package pe.casavip;

import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/** Escenarios ficticios de seis meses, aislados en un proyecto de demostración. */
@org.springframework.core.annotation.Order(10)
@Component
@Profile("demo")
@ConditionalOnProperty(name = "app.demo-expanded", havingValue = "true", matchIfMissing = true)
public class ExpandedDemoData implements CommandLineRunner {
  private final JdbcTemplate jdbc;
  private final OperationsDao d;
  private final String password;

  public ExpandedDemoData(
      JdbcTemplate jdbc, OperationsDao d, @Value("${app.demo-password}") String password) {
    this.jdbc = jdbc;
    this.d = d;
    this.password = password;
  }

  private long id(String table, String key, Object value) {
    return jdbc.queryForObject(
        "select id from " + table + " where " + key + "=?", Long.class, value);
  }

  @Override
  @Transactional
  public void run(String... args) {
    if (jdbc.queryForObject("select count(*) from usuario", Integer.class) == 0
        || jdbc.queryForObject("select count(*) from proyecto where codigo='DEMO05'", Integer.class)
            > 0) return;
    String advisorEmail = "asesor2.demo@example.invalid";
    if (jdbc.queryForObject(
            "select count(*) from usuario where correo=?", Integer.class, advisorEmail)
        == 0)
      jdbc.update(
          "insert into usuario(rol_id,correo,nombre,password_hash,telefono) values(?,?,?,?,?)",
          id("rol", "nombre", "ASESOR"),
          advisorEmail,
          "Luis Asesor Demo",
          new BCryptPasswordEncoder(12).encode(password),
          "900000022");
    long first = id("usuario", "correo", "asesor@casavip.pe"),
        second = id("usuario", "correo", advisorEmail),
        admin = id("usuario", "correo", "admin@casavip.pe"),
        manager = id("usuario", "correo", "responsable@casavip.pe");
    jdbc.update(
        "insert into proyecto(codigo,nombre,ubicacion) values('DEMO05','MIRADOR DEL SOL DEMO','Lima"
            + " · Datos ficticios')");
    long project = id("proyecto", "codigo", "DEMO05");
    jdbc.update(
        "insert into etapa(proyecto_id,nombre,orden) values(?,'Etapa demostrativa',1)", project);
    long stage = id("etapa", "proyecto_id", project);
    jdbc.update("insert into manzana(etapa_id,codigo) values(?,'DEMO')", stage);
    long block = id("manzana", "etapa_id", stage);
    String[] names = {
      "Valeria Torres",
      "Diego Ramos",
      "Lucía Medina",
      "Mateo Salazar",
      "Camila Rojas",
      "Sofía Paredes",
      "Gabriel Vega",
      "Daniela Flores",
      "Sebastián Castro",
      "Mariana Ruiz",
      "Adrián Morales",
      "Paula Herrera",
      "Nicolás Silva",
      "Andrea Navarro",
      "Joaquín Mendoza",
      "Renata Castillo",
      "Alonso Vargas",
      "Isabella Soto",
      "Bruno Aguilar",
      "Elena Cárdenas",
      "Samuel León",
      "Carolina Peña",
      "Emiliano Cruz",
      "Antonia Campos",
      "Leonardo Ríos",
      "Victoria Fuentes",
      "Ignacio Romero",
      "Micaela Suárez",
      "Felipe Núñez",
      "Natalia Cabrera"
    };
    var current = YearMonth.now(ZoneId.of("America/Lima"));
    for (int offset = 0; offset < 6; offset++) {
      var month = current.minusMonths(offset);
      var created = month.atDay(5).atTime(10, 0).atOffset(ZoneOffset.ofHours(-5));
      long[] clients = new long[5];
      for (int i = 0; i < 5; i++) {
        int n = offset * 5 + i;
        String number = String.valueOf(99050001 + n);
        long advisor = i % 2 == 0 ? first : second;
        jdbc.update(
            "insert into"
                + " cliente(tipo_documento,numero_documento,nombre,telefono,correo,direccion,ocupacion,proyecto_id,asesor_id,fecha_registro)"
                + " values('DNI',?,?,?,?,?,?,?,?,?)",
            number,
            names[n] + " Demo",
            "90005" + String.format("%04d", n),
            "cliente" + n + ".demo@example.invalid",
            "Av. Demostración " + (100 + n),
            i % 2 == 0 ? "Comerciante" : "Profesional independiente",
            project,
            advisor,
            created);
        clients[i] = id("cliente", "numero_documento", number);
        jdbc.update(
            "insert into"
                + " auditoria_comercial(usuario_id,entidad,registro_id,accion,motivo,actual,fecha)"
                + " values(?,'CLIENTE',?,'CREAR','Registro ficticio para revisar filtros',?,?)",
            advisor,
            clients[i],
            d.encode(
                Map.of(
                    "nombre",
                    names[n] + " Demo",
                    "telefono",
                    "90005" + String.format("%04d", n),
                    "activo",
                    true)),
            created);
      }
      String coNumber = String.valueOf(99050101 + offset);
      jdbc.update(
          "insert into"
              + " cliente(tipo_documento,numero_documento,nombre,telefono,proyecto_id,asesor_id,fecha_registro)"
              + " values('DNI',?,?,'900000033',?,?,?)",
          coNumber,
          "Cotitular " + (offset + 1) + " Demo",
          project,
          first,
          created);
      long co = id("cliente", "numero_documento", coNumber);
      jdbc.update(
          "insert into cliente_relacion(cliente_id,relacionado_id,tipo) values(?,?,'COTITULAR')",
          clients[0],
          co);
      for (int i = 0; i < 3; i++) {
        String code = String.format("%02d", offset * 3 + i + 1);
        String state = i == 0 ? "ACTIVA" : i == 1 ? "CONFIRMADA" : "ANULADA";
        long advisor = i % 2 == 0 ? first : second;
        BigDecimal price = BigDecimal.valueOf(28000 + offset * 1000 + i * 500),
            initial = BigDecimal.valueOf(4000 + i * 500);
        int count = 24 + offset * 6;
        var terms = OperationsDao.financial(price, initial, count);
        jdbc.update(
            "insert into lote(manzana_id,codigo,area_m2,precio,estado,ubicacion)"
                + " values(?,?,120,?,?,?)",
            block,
            code,
            price,
            i == 0 ? "RESERVADO" : i == 1 ? "VENDIDO" : "DISPONIBLE",
            "Parque demostrativo");
        long lot =
            jdbc.queryForObject(
                "select id from lote where manzana_id=? and codigo=?", Long.class, block, code);
        jdbc.update(
            "insert into plan_pago(proyecto_id,nombre,inicial,numero_cuotas,monto_cuota)"
                + " values(?,?,?,?,?)",
            project,
            "DEMO-" + code,
            initial,
            count,
            terms.get("mensualidad"));
        long plan = id("plan_pago", "nombre", "DEMO-" + code);
        jdbc.update("insert into lote_plan_pago(lote_id,plan_pago_id) values(?,?)", lot, plan);
        var registered = month.atDay(10).atTime(11, 0).atOffset(ZoneOffset.ofHours(-5));
        jdbc.update(
            "insert into"
                + " separacion(lote_id,cliente_id,cotitular_id,asesor_id,monto,estado,fecha_registro,observacion,plan_pago_id,precio_acordado,inicial_acordada,numero_cuotas_acordado,cuota_acordada,condiciones_activas)"
                + " values(?,?,?,?,500,?,?,?,?,?,?,?,?,?)",
            lot,
            clients[i],
            i == 0 ? co : null,
            advisor,
            state,
            registered,
            "Escenario ficticio " + month,
            plan,
            price,
            initial,
            count,
            terms.get("mensualidad"),
            i != 2);
        long operation = id("separacion", "lote_id", lot);
        d.capture(operation);
        jdbc.update(
            "insert into"
                + " historial_lote(lote_id,usuario_id,separacion_id,estado_anterior,estado_nuevo,motivo,fecha_cambio)"
                + " values(?,?,?,'DISPONIBLE','RESERVADO','Separación ficticia',?)",
            lot,
            advisor,
            operation,
            registered);
        jdbc.update(
            "insert into"
                + " auditoria_comercial(usuario_id,entidad,registro_id,accion,motivo,actual,fecha)"
                + " values(?,'OPERACION',?,'SEPARAR','Separación ficticia',?,?)",
            advisor,
            operation,
            d.encode(
                Map.of(
                    "estado",
                    "ACTIVA",
                    "monto",
                    500,
                    "precio_acordado",
                    price,
                    "inicial_acordada",
                    initial,
                    "numero_cuotas_acordado",
                    count)),
            registered);
        if (i == 1) {
          jdbc.update(
              "insert into"
                  + " venta(separacion_id,responsable_id,precio_final,inicial,contrato_firmado,fecha_venta,plan_pago_id,numero_cuotas,mensualidad,ultima_cuota,datos_finales)"
                  + " values(?,?,?,?,true,?,?,?,?,?,?)",
              operation,
              manager,
              price,
              initial,
              month.atDay(15),
              plan,
              count,
              terms.get("mensualidad"),
              terms.get("ultima_cuota"),
              d.encode(d.snapshot(operation)));
          jdbc.update(
              "insert into"
                  + " historial_lote(lote_id,usuario_id,separacion_id,estado_anterior,estado_nuevo,motivo,fecha_cambio)"
                  + " values(?,?,?,'RESERVADO','VENDIDO','Venta ficticia',?)",
              lot,
              manager,
              operation,
              month.atDay(15).atTime(12, 0).atOffset(ZoneOffset.ofHours(-5)));
        } else if (i == 2)
          jdbc.update(
              "insert into"
                  + " historial_lote(lote_id,usuario_id,separacion_id,estado_anterior,estado_nuevo,motivo,fecha_cambio)"
                  + " values(?,?,?,'RESERVADO','DISPONIBLE','Liberación ficticia',?)",
              lot,
              admin,
              operation,
              month.atDay(18).atTime(12, 0).atOffset(ZoneOffset.ofHours(-5)));
        if (i > 0)
          jdbc.update(
              "insert into"
                  + " auditoria_comercial(usuario_id,entidad,registro_id,accion,motivo,anterior,actual,fecha)"
                  + " values(?,'OPERACION',?,?,'Escenario ficticio para revisar historial',?,?,?)",
              i == 1 ? manager : admin,
              operation,
              i == 1 ? "VENDER" : "LIBERAR",
              d.encode(Map.of("estado", "ACTIVA")),
              d.encode(Map.of("estado", state)),
              month.atDay(i == 1 ? 15 : 18).atTime(12, 0).atOffset(ZoneOffset.ofHours(-5)));
      }
    }
  }
}
