package pe.casavip;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Component;

/** Datos ficticios cargados exclusivamente en perfiles demo y test. */
@Component
@Profile({"demo", "test"})
public class DemoData implements CommandLineRunner {
  private final JdbcTemplate jdbc;
  private final String password;

  public DemoData(JdbcTemplate jdbc, @Value("${app.demo-password}") String password) {
    this.jdbc = jdbc;
    this.password = password;
  }

  public void run(String... args) {
    if (jdbc.queryForObject("select count(*) from usuario", Integer.class) > 0) {
      ensurePrototypeCatalog();
      return;
    }
    jdbc.update(
        "insert into rol(nombre) values('ASESOR'),('RESPONSABLE_COMERCIAL'),('ADMINISTRADOR')");
    String hash = new BCryptPasswordEncoder(12).encode(password);
    jdbc.update(
        "insert into usuario(rol_id,correo,nombre,password_hash)"
            + " values(1,'asesor@casavip.pe','Andrea"
            + " Demo',?),(2,'responsable@casavip.pe','Responsable"
            + " Demo',?),(3,'admin@casavip.pe','Administrador Demo',?)",
        hash,
        hash,
        hash);
    jdbc.update(
        "insert into proyecto(codigo,nombre,ubicacion) values('SH','SHENNAN HOUSE','Piloto"
            + " comercial CASA VIP')");
    jdbc.update("insert into etapa(proyecto_id,nombre,orden) values(1,'Etapa 1',1)");
    jdbc.update("insert into manzana(etapa_id,codigo) values(1,'B')");
    int[] codes = {1, 2, 6, 7, 8, 15, 19};
    String[] states = {
      "NO_DISPONIBLE",
      "NO_DISPONIBLE",
      "DISPONIBLE",
      "RESERVADO",
      "VENDIDO",
      "DISPONIBLE",
      "DISPONIBLE"
    };
    for (int i = 0; i < codes.length; i++) {
      int price = codes[i] == 15 ? 24000 : codes[i] == 19 ? 22000 : 21000;
      double area = codes[i] == 1 ? 138.46 : codes[i] == 2 ? 132.94 : codes[i] == 15 ? 140 : 124.42;
      jdbc.update(
          "insert into lote(manzana_id,codigo,area_m2,precio,estado) values(1,?,?,?,?)",
          String.valueOf(codes[i]),
          area,
          price,
          states[i]);
      jdbc.update(
          "insert into plan_pago(proyecto_id,nombre,inicial,numero_cuotas,monto_cuota)"
              + " values(1,?,?,48,?)",
          "B-" + codes[i] + " 48 cuotas",
          codes[i] == 15 ? 4000 : 3000,
          (price - (codes[i] == 15 ? 4000 : 3000)) / 48.0);
      jdbc.update("insert into lote_plan_pago(lote_id,plan_pago_id) values(?,?)", i + 1, i + 1);
    }
    jdbc.update(
        "insert into"
            + " cliente(tipo_documento,numero_documento,nombre,telefono,correo,proyecto_id,asesor_id)"
            + " values('DNI','00000001','Cliente Demo"
            + " Uno','900000001','demo1@example.invalid',1,1),('DNI','00000002','Cliente Demo"
            + " Dos','900000002','demo2@example.invalid',1,1)");
    jdbc.update(
        "insert into separacion(lote_id,cliente_id,asesor_id,monto,estado)"
            + " values(4,1,1,500,'ACTIVA'),(5,2,1,500,'CONFIRMADA')");
    jdbc.update(
        "insert into"
            + " venta(separacion_id,responsable_id,precio_final,inicial,contrato_firmado,fecha_venta,plan_pago_id)"
            + " values(2,2,21000,3000,true,CURRENT_DATE,5)");
    jdbc.update(
        "insert into"
            + " historial_lote(lote_id,usuario_id,separacion_id,estado_anterior,estado_nuevo,motivo)"
            + " values(4,1,1,'DISPONIBLE','RESERVADO','Datos ficticios del"
            + " piloto'),(5,1,2,'DISPONIBLE','RESERVADO','Datos ficticios del"
            + " piloto'),(5,2,2,'RESERVADO','VENDIDO','Datos ficticios del piloto')");
    ensurePrototypeCatalog();
  }

  private void ensurePrototypeCatalog() {
    jdbc.update(
        "update usuario set telefono='900000000' where telefono is null and correo in"
            + " ('asesor@casavip.pe','responsable@casavip.pe','admin@casavip.pe')");
    jdbc.update(
        "update proyecto set ubicacion='Huacho, Lima' where codigo='SH' and ubicacion like"
            + " 'Piloto%'");
    for (String code : new String[] {"A", "C", "D", "P1", "P2"})
      jdbc.update(
          "insert into manzana(etapa_id,codigo) select 1,? where not exists(select 1 from manzana"
              + " where etapa_id=1 and codigo=?)",
          code,
          code);
    for (var lot :
        jdbc.queryForList(
            "select l.id,l.codigo,l.precio,m.codigo as manzana,e.proyecto_id from lote l join"
                + " manzana m on m.id=l.manzana_id join etapa e on e.id=m.etapa_id where"
                + " e.proyecto_id=1")) {
      long id = ((Number) lot.get("id")).longValue();
      String code = String.valueOf(lot.get("codigo"));
      String location =
          switch (code) {
            case "1" -> "Esquina Panamericana";
            case "2" -> "Panamericana";
            case "15" -> "Esquina interior";
            case "19" -> "Avenida";
            default -> "Parque";
          };
      jdbc.update("update lote set ubicacion=? where id=? and ubicacion is null", location, id);
      java.math.BigDecimal price = (java.math.BigDecimal) lot.get("precio");
      var existing =
          jdbc.queryForList(
              "select pp.* from plan_pago pp join lote_plan_pago lp on lp.plan_pago_id=pp.id where"
                  + " lp.lote_id=? order by pp.numero_cuotas desc",
              id);
      if (existing.isEmpty()) continue;
      java.math.BigDecimal initial = (java.math.BigDecimal) existing.getFirst().get("inicial");
      for (int months : new int[] {12, 24, 36}) {
        String name = lot.get("manzana") + "-" + code + " " + months + " cuotas";
        java.math.BigDecimal installment =
            price
                .subtract(initial)
                .divide(java.math.BigDecimal.valueOf(months), 2, java.math.RoundingMode.HALF_UP);
        jdbc.update(
            "insert into plan_pago(proyecto_id,nombre,inicial,numero_cuotas,monto_cuota) select"
                + " 1,?,?,?,? where not exists(select 1 from plan_pago where proyecto_id=1 and"
                + " nombre=?)",
            name,
            initial,
            months,
            installment,
            name);
        long plan =
            jdbc.queryForObject(
                "select id from plan_pago where proyecto_id=1 and nombre=?", Long.class, name);
        jdbc.update(
            "insert into lote_plan_pago(lote_id,plan_pago_id) select ?,? where not exists(select 1"
                + " from lote_plan_pago where lote_id=? and plan_pago_id=?)",
            id,
            plan,
            id,
            plan);
      }
    }
  }
}
