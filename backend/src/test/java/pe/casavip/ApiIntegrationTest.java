package pe.casavip;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.fasterxml.jackson.databind.*;
import java.math.BigDecimal;
import java.util.*;
import java.util.concurrent.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import pe.casavip.ApiModels.*;

/** Pruebas de API, persistencia, autorizacion y concurrencia contra H2 aislada. */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ApiIntegrationTest {
  @Autowired MockMvc mvc;
  @Autowired JdbcTemplate jdbc;
  @Autowired ObjectMapper json;
  @Autowired CommercialService service;

  @BeforeEach
  void clean() {
    jdbc.update("delete from cliente_documento");
    jdbc.update("delete from historial_lote");
    jdbc.update("delete from venta");
    jdbc.update("delete from separacion");
    jdbc.update("delete from cliente_relacion");
    jdbc.update("delete from cliente");
    jdbc.update("delete from sesion");
    jdbc.update("delete from usuario where correo='otro@casavip.pe'");
    jdbc.update("update lote set estado='DISPONIBLE' where id>=3");
  }

  String token(String email) throws Exception {
    var out =
        mvc.perform(
                post("/api/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(
                        json.writeValueAsString(
                            Map.of("email", email, "password", "CasaVIP-demo-2026!"))))
            .andExpect(status().isOk())
            .andReturn()
            .getResponse()
            .getContentAsString();
    return "Bearer " + json.readTree(out).get("token").asText();
  }

  long client(String token, String document) throws Exception {
    var r =
        mvc.perform(
                post("/api/clients")
                    .header("Authorization", token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(
                        json.writeValueAsString(
                            Map.of(
                                "nombre",
                                "Cliente de prueba",
                                "tipo_documento",
                                "DNI",
                                "numero_documento",
                                document,
                                "telefono",
                                "900123456",
                                "correo",
                                "prueba@example.invalid",
                                "proyecto_id",
                                1))))
            .andExpect(status().isOk())
            .andReturn()
            .getResponse();
    return json.readTree(r.getContentAsString()).get("id").asLong();
  }

  long reserve(String token, long client, long lot) throws Exception {
    var r =
        mvc.perform(
                post("/api/reservations")
                    .header("Authorization", token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(
                        json.writeValueAsString(
                            Map.of(
                                "lote_id",
                                lot,
                                "cliente_id",
                                client,
                                "monto",
                                500,
                                "observacion",
                                "Prueba automatizada"))))
            .andExpect(status().isOk())
            .andReturn()
            .getResponse();
    return json.readTree(r.getContentAsString()).get("id").asLong();
  }

  @Test
  void catalogoRequiereSesion() throws Exception {
    mvc.perform(get("/api/projects")).andExpect(status().isUnauthorized());
  }

  @Test
  void loginYLogoutRevocanToken() throws Exception {
    String t = token("asesor@casavip.pe");
    mvc.perform(get("/api/auth/me").header("Authorization", t))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.role").value("ASESOR"));
    mvc.perform(post("/api/auth/logout").header("Authorization", t)).andExpect(status().isOk());
    mvc.perform(get("/api/projects").header("Authorization", t))
        .andExpect(status().isUnauthorized());
    assertEquals(0, jdbc.queryForObject("select count(*) from sesion", Integer.class));
  }

  @Test
  void tokenSeGuardaHasheado() throws Exception {
    String t = token("asesor@casavip.pe").substring(7);
    assertNotEquals(t, jdbc.queryForObject("select token_hash from sesion", String.class));
    assertEquals(64, jdbc.queryForObject("select token_hash from sesion", String.class).length());
  }

  @Test
  void cincoErroresBloqueanTemporalmenteLogin() throws Exception {
    String body = "{\"email\":\"inexistente@example.invalid\",\"password\":\"incorrecta\"}";
    for (int i = 0; i < 5; i++)
      mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content(body))
          .andExpect(status().isUnauthorized());
    mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content(body))
        .andExpect(status().isTooManyRequests());
  }

  @Test
  void reservaActualizaLoteEHistorial() throws Exception {
    String t = token("asesor@casavip.pe");
    reserve(t, client(t, "00123456"), 3);
    assertEquals(
        "RESERVADO", jdbc.queryForObject("select estado from lote where id=3", String.class));
    assertEquals(
        1,
        jdbc.queryForObject("select count(*) from historial_lote where lote_id=3", Integer.class));
  }

  @Test
  void segundaReservaDaConflicto() throws Exception {
    String t = token("asesor@casavip.pe");
    long c = client(t, "00123457");
    reserve(t, c, 3);
    mvc.perform(
            post("/api/reservations")
                .header("Authorization", t)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"lote_id\":3,\"cliente_id\":" + c + ",\"monto\":500}"))
        .andExpect(status().isConflict());
    assertEquals(1, jdbc.queryForObject("select count(*) from separacion", Integer.class));
  }

  @Test
  void documentoDuplicadoReutilizaCliente() throws Exception {
    String t = token("asesor@casavip.pe");
    assertEquals(client(t, "00123458"), client(t, "00123458"));
    assertEquals(1, jdbc.queryForObject("select count(*) from cliente", Integer.class));
  }

  @Test
  void montoInvalidoNoModificaDatos() throws Exception {
    String t = token("asesor@casavip.pe");
    long c = client(t, "00123459");
    mvc.perform(
            post("/api/reservations")
                .header("Authorization", t)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"lote_id\":3,\"cliente_id\":" + c + ",\"monto\":999999}"))
        .andExpect(status().isBadRequest());
    assertEquals(
        "DISPONIBLE", jdbc.queryForObject("select estado from lote where id=3", String.class));
    assertEquals(0, jdbc.queryForObject("select count(*) from separacion", Integer.class));
  }

  @Test
  void asesorNoPuedeLiberar() throws Exception {
    String t = token("asesor@casavip.pe");
    long r = reserve(t, client(t, "00123460"), 3);
    mvc.perform(
            post("/api/reservations/" + r + "/release")
                .header("Authorization", t)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"estado\":\"DISPONIBLE\",\"motivo\":\"Cancelacion solicitada\"}"))
        .andExpect(status().isForbidden());
    assertEquals(
        "RESERVADO", jdbc.queryForObject("select estado from lote where id=3", String.class));
  }

  @Test
  void responsableLiberaConHistorial() throws Exception {
    String t = token("asesor@casavip.pe");
    long r = reserve(t, client(t, "00123461"), 3);
    mvc.perform(
            post("/api/reservations/" + r + "/release")
                .header("Authorization", token("responsable@casavip.pe"))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"estado\":\"DISPONIBLE\",\"motivo\":\"Cancelacion solicitada\"}"))
        .andExpect(status().isOk());
    assertEquals(
        "DISPONIBLE", jdbc.queryForObject("select estado from lote where id=3", String.class));
    assertEquals(
        2,
        jdbc.queryForObject("select count(*) from historial_lote where lote_id=3", Integer.class));
  }

  @Test
  void reasignacionAtomicaCambiaAmbosLotes() throws Exception {
    String t = token("asesor@casavip.pe");
    long r = reserve(t, client(t, "00123462"), 3);
    mvc.perform(
            post("/api/reservations/" + r + "/reassign")
                .header("Authorization", token("responsable@casavip.pe"))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"lote_id\":6,\"motivo\":\"Cambio solicitado por cliente\"}"))
        .andExpect(status().isOk());
    assertEquals(
        "DISPONIBLE", jdbc.queryForObject("select estado from lote where id=3", String.class));
    assertEquals(
        "RESERVADO", jdbc.queryForObject("select estado from lote where id=6", String.class));
    assertEquals(
        6L, jdbc.queryForObject("select lote_id from separacion where id=?", Long.class, r));
  }

  @Test
  void destinoOcupadoNoLiberaOrigen() throws Exception {
    String t = token("asesor@casavip.pe");
    long c = client(t, "00123463");
    long r = reserve(t, c, 3);
    reserve(t, c, 6);
    mvc.perform(
            post("/api/reservations/" + r + "/reassign")
                .header("Authorization", token("responsable@casavip.pe"))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"lote_id\":6,\"motivo\":\"Cambio solicitado\"}"))
        .andExpect(status().isConflict());
    assertEquals(
        "RESERVADO", jdbc.queryForObject("select estado from lote where id=3", String.class));
  }

  @Test
  void dosSolicitudesSimultaneasSoloReservanUnaVez() throws Exception {
    String t = token("asesor@casavip.pe");
    long c = client(t, "00123464");
    var actor = new Actor(1, "Andrea Demo", "ASESOR");
    var barrier = new CyclicBarrier(2);
    try (var pool = Executors.newFixedThreadPool(2)) {
      Callable<Boolean> work =
          () -> {
            barrier.await();
            try {
              service.reserve(new Reservation(3, c, new BigDecimal("500"), "Concurrencia"), actor);
              return true;
            } catch (BusinessRules.Conflict e) {
              return false;
            }
          };
      var a = pool.submit(work);
      var b = pool.submit(work);
      assertNotEquals(a.get(15, TimeUnit.SECONDS), b.get(15, TimeUnit.SECONDS));
    }
    assertEquals(
        1, jdbc.queryForObject("select count(*) from separacion where lote_id=3", Integer.class));
  }

  @Test
  void ventaExigeContrato() throws Exception {
    String t = token("asesor@casavip.pe");
    long r = reserve(t, client(t, "00123465"), 3);
    mvc.perform(
            post("/api/reservations/" + r + "/sale")
                .header("Authorization", token("responsable@casavip.pe"))
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    "{\"plan_id\":3,\"precio\":21000,\"inicial\":3000,\"contrato_firmado\":false,\"fecha\":\"2026-10-20\"}"))
        .andExpect(status().isBadRequest());
    assertEquals(
        "RESERVADO", jdbc.queryForObject("select estado from lote where id=3", String.class));
  }

  @Test
  void ventaConfirmadaCierraSeparacion() throws Exception {
    String t = token("asesor@casavip.pe");
    long r = reserve(t, client(t, "00123466"), 3);
    mvc.perform(
            post("/api/reservations/" + r + "/sale")
                .header("Authorization", token("responsable@casavip.pe"))
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    "{\"plan_id\":3,\"precio\":21000,\"inicial\":3000,\"contrato_firmado\":true,\"fecha\":\"2026-10-20\"}"))
        .andExpect(status().isOk());
    assertEquals(
        "VENDIDO", jdbc.queryForObject("select estado from lote where id=3", String.class));
    assertEquals(1, jdbc.queryForObject("select count(*) from venta", Integer.class));
  }

  @Test
  void soloAdminDeshabilitaLote() throws Exception {
    String path = "/api/lots/3/state",
        body = "{\"estado\":\"NO_DISPONIBLE\",\"motivo\":\"Revision administrativa\"}";
    mvc.perform(
            patch(path)
                .header("Authorization", token("asesor@casavip.pe"))
                .contentType(MediaType.APPLICATION_JSON)
                .content(body))
        .andExpect(status().isForbidden());
    mvc.perform(
            patch(path)
                .header("Authorization", token("admin@casavip.pe"))
                .contentType(MediaType.APPLICATION_JSON)
                .content(body))
        .andExpect(status().isOk());
    assertEquals(
        "NO_DISPONIBLE", jdbc.queryForObject("select estado from lote where id=3", String.class));
  }

  @Test
  void excelEsValidoYSinDni() throws Exception {
    String t = token("asesor@casavip.pe");
    reserve(t, client(t, "00123467"), 3);
    mvc.perform(get("/api/reports/reservations.xlsx").header("Authorization", t))
        .andExpect(status().isForbidden());
    byte[] bytes =
        mvc.perform(
                get("/api/reports/reservations.xlsx")
                    .header("Authorization", token("responsable@casavip.pe")))
            .andExpect(status().isOk())
            .andReturn()
            .getResponse()
            .getContentAsByteArray();
    try (var book =
        new org.apache.poi.xssf.usermodel.XSSFWorkbook(new java.io.ByteArrayInputStream(bytes))) {
      assertEquals(6, book.getSheetAt(0).getRow(0).getPhysicalNumberOfCells());
      assertEquals(1, book.getSheetAt(0).getLastRowNum());
    }
  }

  @Test
  void fichaEsImagenYNoContieneDatosDeCliente() throws Exception {
    byte[] bytes =
        mvc.perform(get("/api/lots/3/card.png").header("Authorization", token("asesor@casavip.pe")))
            .andExpect(status().isOk())
            .andExpect(content().contentType(MediaType.IMAGE_PNG))
            .andReturn()
            .getResponse()
            .getContentAsByteArray();
    assertEquals(
        1080, javax.imageio.ImageIO.read(new java.io.ByteArrayInputStream(bytes)).getWidth());
  }

  @Test
  void archivosFalsosNoSeAceptan() throws Exception {
    String t = token("asesor@casavip.pe");
    long c = client(t, "00123468");
    var file =
        new MockMultipartFile("file", "foto.png", "image/png", "texto que no es imagen".getBytes());
    mvc.perform(
            multipart("/api/clients/" + c + "/documents/ANVERSO")
                .file(file)
                .header("Authorization", t))
        .andExpect(status().isBadRequest());
    assertEquals(0, jdbc.queryForObject("select count(*) from cliente_documento", Integer.class));
  }

  @Test
  void cargaYLecturaPrivadaDeDni() throws Exception {
    String t = token("asesor@casavip.pe");
    long c = client(t, "00123469");
    var image = new java.awt.image.BufferedImage(3, 3, java.awt.image.BufferedImage.TYPE_INT_RGB);
    var out = new java.io.ByteArrayOutputStream();
    javax.imageio.ImageIO.write(image, "png", out);
    mvc.perform(
            multipart("/api/clients/" + c + "/documents/ANVERSO")
                .file(new MockMultipartFile("file", "foto.png", "image/png", out.toByteArray()))
                .header("Authorization", t))
        .andExpect(status().isOk());
    long id = jdbc.queryForObject("select id from cliente_documento", Long.class);
    mvc.perform(get("/api/documents/" + id)).andExpect(status().isUnauthorized());
    mvc.perform(get("/api/documents/" + id).header("Authorization", t)).andExpect(status().isOk());
  }

  @Test
  void otroAsesorNoPuedeConsultarNiUsarClientesAjenos() throws Exception {
    String owner = token("asesor@casavip.pe");
    long c = client(owner, "00123470");
    jdbc.update(
        "insert into usuario(rol_id,correo,nombre,password_hash) select 1,'otro@casavip.pe','Otro"
            + " Asesor',password_hash from usuario where id=1");
    String other = token("otro@casavip.pe");
    mvc.perform(get("/api/clients").header("Authorization", other))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.length()").value(0));
    mvc.perform(get("/api/clients/" + c + "/documents").header("Authorization", other))
        .andExpect(status().isForbidden());
    mvc.perform(
            post("/api/reservations")
                .header("Authorization", other)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"lote_id\":3,\"cliente_id\":" + c + ",\"monto\":500}"))
        .andExpect(status().isForbidden());
    assertEquals(
        "DISPONIBLE", jdbc.queryForObject("select estado from lote where id=3", String.class));
  }

  @Test
  void sesionVencidaNoAutorizaConsultas() throws Exception {
    String t = token("asesor@casavip.pe");
    jdbc.update(
        "update sesion set expira=?",
        java.sql.Timestamp.from(java.time.Instant.now().minusSeconds(10)));
    mvc.perform(get("/api/projects").header("Authorization", t))
        .andExpect(status().isUnauthorized());
  }

  Map<String, Object> prototypePerson(String doc) {
    return new java.util.LinkedHashMap<>(
        Map.of(
            "nombre",
            "Persona demostrativa",
            "tipo_documento",
            "DNI",
            "numero_documento",
            doc,
            "telefono",
            "900123456",
            "correo",
            "demo@example.invalid",
            "direccion",
            "Av. Demostrativa 123, Huacho",
            "ocupacion",
            "Comerciante",
            "proyecto_id",
            1));
  }

  JsonNode createWithCo(String token, String main, String co) throws Exception {
    var payload = prototypePerson(main);
    var secondary = prototypePerson(co);
    secondary.remove("proyecto_id");
    payload.put("cotitular", secondary);
    var response =
        mvc.perform(
                post("/api/clients")
                    .header("Authorization", token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(json.writeValueAsString(payload)))
            .andExpect(status().isOk())
            .andReturn()
            .getResponse();
    return json.readTree(response.getContentAsString());
  }

  void uploadBoth(String token, long person) throws Exception {
    var image = new java.awt.image.BufferedImage(30, 20, java.awt.image.BufferedImage.TYPE_INT_RGB);
    var out = new java.io.ByteArrayOutputStream();
    javax.imageio.ImageIO.write(image, "png", out);
    for (String side : List.of("ANVERSO", "REVERSO"))
      mvc.perform(
              multipart("/api/clients/" + person + "/documents/" + side)
                  .file(new MockMultipartFile("file", "foto.png", "image/png", out.toByteArray()))
                  .header("Authorization", token))
          .andExpect(status().isOk());
  }

  @Test
  void camposYRelacionDelCotitularSePersisten() throws Exception {
    String t = token("asesor@casavip.pe");
    var result = createWithCo(t, "00000661", "00000662");
    assertEquals("Comerciante", result.get("ocupacion").asText());
    long person = result.get("id").asLong(), co = result.get("cotitular").get("id").asLong();
    assertEquals(
        "Av. Demostrativa 123, Huacho",
        jdbc.queryForObject("select direccion from cliente where id=?", String.class, person));
    assertEquals(
        1,
        jdbc.queryForObject(
            "select count(*) from cliente_relacion where cliente_id=? and relacionado_id=?",
            Integer.class,
            person,
            co));
    mvc.perform(get("/api/clients/" + person).header("Authorization", t))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.cotitular.id").value(co));
  }

  @Test
  void cotitularIgualAlTitularRevierteElRegistro() throws Exception {
    String t = token("asesor@casavip.pe");
    var input = prototypePerson("00000663");
    var co = prototypePerson("00000663");
    co.remove("proyecto_id");
    input.put("cotitular", co);
    mvc.perform(
            post("/api/clients")
                .header("Authorization", t)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsString(input)))
        .andExpect(status().isBadRequest());
    assertEquals(0, jdbc.queryForObject("select count(*) from cliente", Integer.class));
  }

  @Test
  void unCotitularAjenoNoPuedeVincularse() throws Exception {
    jdbc.update(
        "insert into usuario(rol_id,correo,nombre,password_hash) select 1,'otro@casavip.pe','Otro"
            + " Asesor',password_hash from usuario where id=1");
    String other = token("otro@casavip.pe");
    client(other, "00000664");
    String t = token("asesor@casavip.pe");
    var input = prototypePerson("00000665");
    var co = prototypePerson("00000664");
    co.remove("proyecto_id");
    input.put("cotitular", co);
    mvc.perform(
            post("/api/clients")
                .header("Authorization", t)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsString(input)))
        .andExpect(status().isForbidden());
    assertEquals(
        0,
        jdbc.queryForObject(
            "select count(*) from cliente where numero_documento='00000665'", Integer.class));
  }

  @Test
  void elPlanElegidoSeGuardaConImportesDelServidor() throws Exception {
    String t = token("asesor@casavip.pe");
    long person = client(t, "00000666");
    long plan =
        jdbc.queryForObject(
            "select pp.id from plan_pago pp join lote_plan_pago lp on lp.plan_pago_id=pp.id where"
                + " lp.lote_id=3 and pp.numero_cuotas=24",
            Long.class);
    mvc.perform(
            post("/api/reservations")
                .header("Authorization", t)
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    json.writeValueAsString(
                        Map.of(
                            "lote_id",
                            3,
                            "cliente_id",
                            person,
                            "monto",
                            500,
                            "plan_id",
                            plan,
                            "cuota_acordada",
                            1))))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.numero_cuotas_acordado").value(24))
        .andExpect(jsonPath("$.cuota_acordada").value(750.0));
    assertEquals(plan, jdbc.queryForObject("select plan_pago_id from separacion", Long.class));
    assertEquals(
        0,
        new BigDecimal("21000")
            .compareTo(
                jdbc.queryForObject("select precio_acordado from separacion", BigDecimal.class)));
  }

  @Test
  void unPlanDeOtroLoteNoPuedeGuardarse() throws Exception {
    String t = token("asesor@casavip.pe");
    long person = client(t, "00000667");
    mvc.perform(
            post("/api/reservations")
                .header("Authorization", t)
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    json.writeValueAsString(
                        Map.of("lote_id", 3, "cliente_id", person, "monto", 500, "plan_id", 6))))
        .andExpect(status().isBadRequest());
    assertEquals(0, jdbc.queryForObject("select count(*) from separacion", Integer.class));
    assertEquals(
        "DISPONIBLE", jdbc.queryForObject("select estado from lote where id=3", String.class));
  }

  @Test
  void elCotitularRequiereSusCuatroFotografias() throws Exception {
    String t = token("asesor@casavip.pe");
    var people = createWithCo(t, "00000668", "00000669");
    long person = people.get("id").asLong(), co = people.get("cotitular").get("id").asLong();
    uploadBoth(t, person);
    mvc.perform(
            post("/api/reservations")
                .header("Authorization", t)
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    json.writeValueAsString(
                        Map.of(
                            "lote_id", 3, "cliente_id", person, "cotitular_id", co, "monto", 500))))
        .andExpect(status().isBadRequest());
    assertEquals(0, jdbc.queryForObject("select count(*) from separacion", Integer.class));
  }

  @Test
  void separacionConCotitularConservaRelacionYDocumentos() throws Exception {
    String t = token("asesor@casavip.pe");
    var people = createWithCo(t, "00000670", "00000671");
    long person = people.get("id").asLong(), co = people.get("cotitular").get("id").asLong();
    uploadBoth(t, person);
    uploadBoth(t, co);
    mvc.perform(
            post("/api/reservations")
                .header("Authorization", t)
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    json.writeValueAsString(
                        Map.of(
                            "lote_id", 3, "cliente_id", person, "cotitular_id", co, "monto", 500))))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.cotitular_id").value(co));
    assertEquals(4, jdbc.queryForObject("select count(*) from cliente_documento", Integer.class));
  }

  @Test
  void elTitularPuedeCorregirSuFormularioAntesDeConfirmar() throws Exception {
    String t = token("asesor@casavip.pe");
    long person = client(t, "00000672");
    var input = prototypePerson("00000672");
    input.put("direccion", "Dirección corregida");
    mvc.perform(
            put("/api/clients/" + person)
                .header("Authorization", t)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsString(input)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.direccion").value("Dirección corregida"));
  }

  @Test
  void editarUnClienteAjenoEstaProhibido() throws Exception {
    String t = token("asesor@casavip.pe");
    long person = client(t, "00000673");
    jdbc.update(
        "insert into usuario(rol_id,correo,nombre,password_hash) select 1,'otro@casavip.pe','Otro"
            + " Asesor',password_hash from usuario where id=1");
    String other = token("otro@casavip.pe");
    mvc.perform(
            put("/api/clients/" + person)
                .header("Authorization", other)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsString(prototypePerson("00000673"))))
        .andExpect(status().isForbidden());
    assertEquals(
        "Cliente de prueba",
        jdbc.queryForObject("select nombre from cliente where id=?", String.class, person));
  }
}
