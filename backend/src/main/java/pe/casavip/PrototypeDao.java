package pe.casavip;

import java.util.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

/** Persistencia de los campos y condiciones presentes en el prototipo aprobado. */
@Repository
public class PrototypeDao {
  private final JdbcTemplate jdbc;

  public PrototypeDao(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  public void profile(long id, String direccion, String ocupacion) {
    jdbc.update("update cliente set direccion=?,ocupacion=? where id=?", direccion, ocupacion, id);
  }

  public void person(long id, pe.casavip.ApiModels.Client in) {
    jdbc.update(
        "update cliente set"
            + " nombre=?,tipo_documento=?,numero_documento=?,telefono=?,correo=?,direccion=?,ocupacion=?"
            + " where id=?",
        in.nombre(),
        in.tipo_documento(),
        in.numero_documento(),
        in.telefono(),
        in.correo(),
        in.direccion(),
        in.ocupacion(),
        id);
  }

  public void link(long titular, long cotitular) {
    jdbc.update(
        "insert into cliente_relacion(cliente_id,relacionado_id,tipo) select ?,?,'COTITULAR' where"
            + " not exists (select 1 from cliente_relacion where cliente_id=? and relacionado_id=?"
            + " and tipo='COTITULAR')",
        titular,
        cotitular,
        titular,
        cotitular);
  }

  public boolean linked(long titular, long cotitular) {
    return jdbc.queryForObject(
            "select count(*) from cliente_relacion where cliente_id=? and relacionado_id=? and"
                + " tipo='COTITULAR'",
            Integer.class,
            titular,
            cotitular)
        > 0;
  }

  public Map<String, Object> coClient(long titular) {
    var rows =
        jdbc.queryForList(
            "select c.* from cliente c join cliente_relacion r on r.relacionado_id=c.id where"
                + " r.cliente_id=? and r.tipo='COTITULAR' order by r.id desc",
            titular);
    return rows.isEmpty() ? null : rows.getFirst();
  }

  public void terms(long id, Map<String, Object> lot, Map<String, Object> plan, Long co) {
    jdbc.update(
        "update separacion set"
            + " plan_pago_id=?,cotitular_id=?,precio_acordado=?,inicial_acordada=?,cuota_acordada=?,numero_cuotas_acordado=?"
            + " where id=?",
        plan == null ? null : plan.get("id"),
        co,
        lot.get("precio"),
        plan == null ? null : plan.get("inicial"),
        plan == null ? null : plan.get("monto_cuota"),
        plan == null ? null : plan.get("numero_cuotas"),
        id);
  }
}
