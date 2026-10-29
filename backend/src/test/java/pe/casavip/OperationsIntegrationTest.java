package pe.casavip;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import com.fasterxml.jackson.databind.*;
import java.math.*;
import java.util.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.*;
import org.springframework.transaction.annotation.Transactional;
import pe.casavip.ApiModels.*;

@SpringBootTest @AutoConfigureMockMvc @ActiveProfiles("test") @Transactional
class OperationsIntegrationTest {
 @Autowired MockMvc mvc;@Autowired JdbcTemplate jdbc;@Autowired ObjectMapper json;
 @Autowired CatalogService catalog;@Autowired OperationsService ops;
 Actor admin=new Actor(3,"Admin","ADMINISTRADOR"),advisor=new Actor(1,"Asesor","ASESOR");
 String a,m,t;long client;
 @BeforeEach void setup()throws Exception{
   a=token("admin@casavip.pe");m=token("responsable@casavip.pe");t=token("asesor@casavip.pe");
   jdbc.update("update lote set estado='DISPONIBLE',precio=21000 where id=3");
   client=body(mvc.perform(post("/api/clients").header("Authorization",t).contentType(MediaType.APPLICATION_JSON).content("{\"nombre\":\"Titular nuevo\",\"tipo_documento\":\"DNI\",\"numero_documento\":\"98123456\",\"telefono\":\"900123456\",\"proyecto_id\":1}")).andExpect(status().isOk())).get("id").asLong();
 }
 JsonNode body(ResultActions result)throws Exception{return json.readTree(result.andReturn().getResponse().getContentAsString());}
 String token(String email)throws Exception{return "Bearer "+body(mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(Map.of("email",email,"password","CasaVIP-demo-2026!")))).andExpect(status().isOk())).get("token").asText();}
 JsonNode reserve(Map<String,Object> extra)throws Exception{
   var in=new HashMap<String,Object>(Map.of("lote_id",3,"cliente_id",client,"monto",500));in.putAll(extra);
   return body(mvc.perform(post("/api/reservations").header("Authorization",t).contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(in))).andExpect(status().isOk()));
 }
 @Test void loginRechazaLongitudesYBytesExcesivos()throws Exception{
   for(String p:List.of("x".repeat(65),"界".repeat(30)))mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(Map.of("email","asesor@casavip.pe","password",p)))).andExpect(status().isBadRequest());
 }
 @Test void condicionesNegociadasNoModificanCatalogo()throws Exception{
   var r=reserve(Map.of("inicial_acordada",5000,"numero_cuotas_acordado",31));
   assertEquals(5000,r.get("inicial_acordada").asInt());assertEquals(31,r.get("numero_cuotas_acordado").asInt());
   assertEquals(new BigDecimal("21000.00"),jdbc.queryForObject("select precio from lote where id=3",BigDecimal.class));
   var f=OperationsDao.financial(new BigDecimal("21000"),new BigDecimal("5000"),31);
   assertEquals(new BigDecimal("16000.00"),((BigDecimal)f.get("mensualidad")).multiply(new BigDecimal(30)).add((BigDecimal)f.get("ultima_cuota")));
 }
 @Test void asesorNoPuedeModificarPrecio()throws Exception{
   mvc.perform(post("/api/reservations").header("Authorization",t).contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(Map.of("lote_id",3,"cliente_id",client,"monto",500,"precio_acordado",10000)))).andExpect(status().isForbidden());
 }
 @Test void importacionConservaCondicionesDeSeparacion()throws Exception{
   var r=reserve(Map.of("inicial_acordada",4000,"numero_cuotas_acordado",24));long id=r.get("id").asLong();
   var preview=catalog.preview(new MockMultipartFile("file","precios.csv","text/csv","lote_id,precio,inicial,numero_cuotas\n3,25000,6000,36\n".getBytes()),admin);
   catalog.apply((List<Map<String,Object>>)preview.get("rows"),"Nuevo catálogo",admin);
   assertEquals(new BigDecimal("25000.00"),jdbc.queryForObject("select precio from lote where id=3",BigDecimal.class));
   assertEquals(new BigDecimal("21000.00"),jdbc.queryForObject("select precio_acordado from separacion where id=?",BigDecimal.class,id));
   assertEquals(new BigDecimal("4000.00"),jdbc.queryForObject("select inicial_acordada from separacion where id=?",BigDecimal.class,id));
   // Un plan aceptado no desaparece al publicar el catálogo.
   mvc.perform(post("/api/reservations/"+id+"/sale").header("Authorization",m).contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(Map.of("plan_id",r.get("plan_pago_id").asLong(),"precio",21000,"inicial",4000,"numero_cuotas",24,"contrato_firmado",true,"fecha",java.time.LocalDate.now().toString())))).andExpect(status().isOk());
   assertEquals(new BigDecimal("21000.00"),jdbc.queryForObject("select precio_final from venta where separacion_id=?",BigDecimal.class,id));
 }
 @Test void importacionOmiteVendidos()throws Exception{
   jdbc.update("update lote set estado='VENDIDO' where id=3");var p=catalog.preview(new MockMultipartFile("file","x.json","application/json","[{\"lote_id\":3,\"precio\":99000}]".getBytes()),admin);
   var result=catalog.apply((List<Map<String,Object>>)p.get("rows"),"Carga",admin);assertEquals(1,result.get("vendidos_omitidos"));assertEquals(new BigDecimal("21000.00"),jdbc.queryForObject("select precio from lote where id=3",BigDecimal.class));
 }
 @Test void importacionDetectaVersionDesactualizada()throws Exception{
   var p=catalog.preview(new MockMultipartFile("file","x.csv","text/csv","lote_id,precio\n3,25000".getBytes()),admin);jdbc.update("update lote set version=version+1 where id=3");
   assertThrows(BusinessRules.Conflict.class,()->catalog.apply((List<Map<String,Object>>)p.get("rows"),"Carga",admin));
 }
 @Test void importacionInvalidaNoActualizaFilasAnteriores()throws Exception{
   var version=jdbc.queryForObject("select version from lote where id=3",Long.class);
   assertThrows(IllegalArgumentException.class,()->catalog.apply(List.of(new HashMap<>(Map.of("lote_id",3,"precio",25000,"version",version)),new HashMap<>(Map.of("lote_id",6,"precio",-5,"version",0))),"Carga",admin));
   assertEquals(new BigDecimal("21000.00"),jdbc.queryForObject("select precio from lote where id=3",BigDecimal.class));
 }
 @Test void csvConComillasYExcelSePuedenImportar()throws Exception{
   var p=catalog.preview(new MockMultipartFile("file","x.csv","text/csv","lote_id;precio;ubicacion\n3;25000;\"Frente; al parque\"".getBytes()),admin);assertEquals("Frente; al parque",((List<Map<String,Object>>)p.get("rows")).getFirst().get("ubicacion"));
   try(var book=new org.apache.poi.xssf.usermodel.XSSFWorkbook();var output=new java.io.ByteArrayOutputStream()){
     var sheet=book.createSheet();var header=sheet.createRow(0);header.createCell(0).setCellValue("lote_id");header.createCell(1).setCellValue("precio");var row=sheet.createRow(1);row.createCell(0).setCellValue(3);row.createCell(1).setCellValue(25000);book.write(output);
     assertEquals(1,((List<?>)catalog.preview(new MockMultipartFile("file","x.xlsx","application/octet-stream",output.toByteArray()),admin).get("rows")).size());
   }
 }
 @Test void liberarDesactivaCondicionesYConservaHistorial()throws Exception{
   long id=reserve(Map.of()).get("id").asLong();mvc.perform(post("/api/reservations/"+id+"/release").header("Authorization",m).contentType(MediaType.APPLICATION_JSON).content("{\"estado\":\"DISPONIBLE\",\"motivo\":\"Cliente desiste\"}")).andExpect(status().isOk());
   assertEquals(false,jdbc.queryForObject("select condiciones_activas from separacion where id=?",Boolean.class,id));assertNotNull(jdbc.queryForObject("select datos_acordados from separacion where id=?",String.class,id));
 }
 @Test void eliminarClienteConservaOperacionYFotografiaDeSusDatos()throws Exception{
   long id=reserve(Map.of()).get("id").asLong();mvc.perform(delete("/api/clients/"+client).header("Authorization",t)).andExpect(status().isOk());
   assertEquals(0,ops.clients(advisor,null).stream().filter(c->CommercialService.id(c,"id")==client).count());
   assertTrue(json.writeValueAsString(ops.detail(id,advisor).get("datos_acordados")).contains("Titular nuevo"));
 }
 @Test void responsableSoloPuedeDeshabilitarYRevocaSesiones()throws Exception{
   mvc.perform(patch("/api/admin/users/1/active").header("Authorization",m).contentType(MediaType.APPLICATION_JSON).content("{\"activo\":false}")).andExpect(status().isOk());
   mvc.perform(get("/api/projects").header("Authorization",t)).andExpect(status().isUnauthorized());
   mvc.perform(patch("/api/admin/users/1/active").header("Authorization",m).contentType(MediaType.APPLICATION_JSON).content("{\"activo\":true}")).andExpect(status().isForbidden());
   mvc.perform(post("/api/admin/users").header("Authorization",m).contentType(MediaType.APPLICATION_JSON).content("{\"nombre\":\"Otro\",\"correo\":\"otro2@example.invalid\",\"rol\":\"ASESOR\",\"password\":\"ValidPassword1!\",\"activo\":true}")).andExpect(status().isForbidden());
 }
 @Test void noSePuedeDeshabilitarUltimoAdministrador()throws Exception{mvc.perform(patch("/api/admin/users/3/active").header("Authorization",m).contentType(MediaType.APPLICATION_JSON).content("{\"activo\":false}")).andExpect(status().isConflict());}
 @Test void notificacionesGlobalesNoExponenPersonasYLecturaEsIndividual()throws Exception{
   long id=reserve(Map.of()).get("id").asLong();var feed=body(mvc.perform(get("/api/notifications").header("Authorization",m)).andExpect(status().isOk()));assertFalse(feed.toString().contains("98123456"));assertFalse(feed.toString().contains("Titular nuevo"));
   long last=feed.get("items").get(0).get("id").asLong();mvc.perform(post("/api/notifications/read").header("Authorization",m).contentType(MediaType.APPLICATION_JSON).content("{\"hasta\":"+last+"}")).andExpect(status().isOk());
   assertEquals(0,body(mvc.perform(get("/api/notifications").header("Authorization",m))).get("pendientes").asInt());assertTrue(body(mvc.perform(get("/api/notifications").header("Authorization",t))).get("pendientes").asInt()>0);
 }
 @Test void compartirTextoRestringidoYCorreccionesVersionadas()throws Exception{
   long id=reserve(Map.of()).get("id").asLong();mvc.perform(get("/api/operations/"+id+"/share").header("Authorization",t)).andExpect(status().isForbidden());
   mvc.perform(get("/api/operations/"+id+"/share").header("Authorization",m)).andExpect(status().isOk());
   long version=jdbc.queryForObject("select version from separacion where id=?",Long.class,id);var payload=json.writeValueAsString(Map.of("version",version,"precio",22000,"inicial",5000,"numero_cuotas",36,"monto",500,"motivo","Acuerdo autorizado","observacion","Condición revisada"));
   mvc.perform(put("/api/operations/"+id).header("Authorization",m).contentType(MediaType.APPLICATION_JSON).content(payload)).andExpect(status().isOk());
   mvc.perform(put("/api/operations/"+id).header("Authorization",m).contentType(MediaType.APPLICATION_JSON).content(payload)).andExpect(status().isConflict());assertEquals(new BigDecimal("21000.00"),jdbc.queryForObject("select precio from lote where id=3",BigDecimal.class));
 }
 byte[] image(int color)throws Exception{var image=new java.awt.image.BufferedImage(2,2,java.awt.image.BufferedImage.TYPE_INT_RGB);image.setRGB(0,0,color);var output=new java.io.ByteArrayOutputStream();javax.imageio.ImageIO.write(image,"png",output);return output.toByteArray();}
 long withCo()throws Exception{
   var in=new HashMap<String,Object>(Map.of("nombre","Titular nuevo","tipo_documento","DNI","numero_documento","98123456","telefono","900123456","proyecto_id",1));
   in.put("cotitular",Map.of("nombre","Cotitular persistido","tipo_documento","DNI","numero_documento","98123457","telefono","900123457"));
   var updated=body(mvc.perform(put("/api/clients/"+client).header("Authorization",t).contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(in))).andExpect(status().isOk()));long co=updated.get("cotitular").get("id").asLong();
   for(long id:new long[]{client,co})for(String side:List.of("ANVERSO","REVERSO"))mvc.perform(multipart("/api/clients/"+id+"/documents/"+side).file(new MockMultipartFile("file","dni.png","image/png",image(123))).header("Authorization",t)).andExpect(status().isOk());return co;
 }
 @Test void clienteExistenteAdmiteCotitularYDesvincularConservaOperacion()throws Exception{
   long co=withCo(),id=reserve(Map.of("cotitular_id",co)).get("id").asLong();
   mvc.perform(delete("/api/clients/"+client+"/cotitular").header("Authorization",t)).andExpect(status().isOk());
   assertNull(ops.clientProfile(client,advisor).get("cotitular"));assertTrue(json.writeValueAsString(ops.detail(id,advisor).get("datos_acordados")).contains("Cotitular persistido"));
 }
 @Test void reemplazarDocumentoNoBorraImagenGuardadaEnOperacion()throws Exception{
   long co=withCo(),id=reserve(Map.of("cotitular_id",co)).get("id").asLong();var detail=ops.detail(id,admin);var docs=(List<Map<String,Object>>)detail.get("documentos");assertEquals(4,docs.size());long doc=CommercialService.id(docs.getFirst(),"id");
   mvc.perform(multipart("/api/clients/"+client+"/documents/ANVERSO").file(new MockMultipartFile("file","nuevo.png","image/png",image(456))).header("Authorization",t)).andExpect(status().isOk());
   byte[] prior=mvc.perform(get("/api/operations/"+id+"/documents/"+doc).header("Authorization",m)).andExpect(status().isOk()).andReturn().getResponse().getContentAsByteArray();assertArrayEquals(image(123),prior);
 }
 @Test void administradorGestionaUsuariosSinExponerHashes()throws Exception{
   var in=new HashMap<String,Object>(Map.of("nombre","Usuario nuevo","correo","nuevo.ops@example.invalid","telefono","900123456","rol","ASESOR","password","ClaveValida2026!","activo",true));
   long id=body(mvc.perform(post("/api/admin/users").header("Authorization",a).contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(in))).andExpect(status().isOk())).get("id").asLong();
   in.put("nombre","Usuario actualizado");in.put("password","");mvc.perform(put("/api/admin/users/"+id).header("Authorization",a).contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(in))).andExpect(status().isOk());
   var users=body(mvc.perform(get("/api/admin/users").header("Authorization",a)).andExpect(status().isOk()));assertTrue(users.toString().contains("Usuario actualizado"));assertFalse(users.toString().contains("password_hash"));
   mvc.perform(delete("/api/admin/users/"+id).header("Authorization",a)).andExpect(status().isOk());assertEquals(true,jdbc.queryForObject("select eliminado from usuario where id=?",Boolean.class,id));
 }
 @Test void otroAsesorRecibeAvisoSinAccederAOperacionNiBorrarCliente()throws Exception{
   jdbc.update("insert into usuario(rol_id,nombre,correo,password_hash) select rol_id,'Otro asesor','otro.ops@example.invalid',password_hash from usuario where id=1");String other=token("otro.ops@example.invalid");long id=reserve(Map.of()).get("id").asLong();
   mvc.perform(delete("/api/clients/"+client).header("Authorization",other)).andExpect(status().isForbidden());mvc.perform(get("/api/operations/"+id).header("Authorization",other)).andExpect(status().isForbidden());
   var feed=body(mvc.perform(get("/api/notifications").header("Authorization",other)).andExpect(status().isOk()));assertTrue(feed.get("items").get(0).get("operacion_id").isNull());
 }
 @Test void editarVentaConservaVersionAnteriorEnAuditoria()throws Exception{
   var r=reserve(Map.of()).deepCopy();long id=r.get("id").asLong();mvc.perform(post("/api/reservations/"+id+"/sale").header("Authorization",m).contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(Map.of("plan_id",r.get("plan_pago_id").asLong(),"precio",21000,"inicial",3000,"numero_cuotas",24,"contrato_firmado",true,"fecha",java.time.LocalDate.now().toString())))).andExpect(status().isOk());
   long version=jdbc.queryForObject("select version from separacion where id=?",Long.class,id);mvc.perform(put("/api/operations/"+id).header("Authorization",m).contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(Map.of("version",version,"precio",20000,"inicial",4000,"numero_cuotas",20,"monto",500,"motivo","Corrección comercial autorizada")))).andExpect(status().isOk());
   assertEquals(new BigDecimal("20000.00"),jdbc.queryForObject("select precio_final from venta where separacion_id=?",BigDecimal.class,id));assertTrue(jdbc.queryForObject("select anterior from auditoria_comercial where entidad='OPERACION' and registro_id=? and accion='CORREGIR'",String.class,id).contains("21000"));
 }
}
