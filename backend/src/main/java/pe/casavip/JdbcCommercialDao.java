package pe.casavip;

import java.math.BigDecimal;
import java.sql.*;
import java.util.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.stereotype.Repository;
import pe.casavip.ApiModels.*;

/** Implementacion JDBC con consultas parametrizadas y bloqueos de filas. */
@Repository
public class JdbcCommercialDao implements CommercialDao {
  private final JdbcTemplate jdbc;

  public JdbcCommercialDao(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  private Map<String, Object> one(String sql, Object... params) {
    var list = jdbc.queryForList(sql, params);
    if (list.isEmpty()) throw new BusinessRules.Missing();
    return list.getFirst();
  }

  private Map<String, Object> optional(String sql, Object... params) {
    var list = jdbc.queryForList(sql, params);
    return list.isEmpty() ? null : list.getFirst();
  }

  private long insert(String sql, Object... params) {
    var keys = new GeneratedKeyHolder();
    jdbc.update(
        c -> {
          var s = c.prepareStatement(sql, new String[] {"id"});
          for (int i = 0; i < params.length; i++) s.setObject(i + 1, params[i]);
          return s;
        },
        keys);
    return Objects.requireNonNull(keys.getKey()).longValue();
  }

  public Map<String, Object> user(String email) {
    return optional(
        "select u.id,u.correo,u.nombre,u.telefono,u.password_hash,r.nombre as rol from usuario u"
            + " join rol r on r.id=u.rol_id where lower(u.correo)=lower(?) and u.activo=true",
        email);
  }

  public Map<String, Object> session(String hash) {
    return optional(
        "select u.id,u.nombre,u.telefono,r.nombre as rol from sesion s join usuario u on"
            + " u.id=s.usuario_id join rol r on r.id=u.rol_id where s.token_hash=? and s.expira>?"
            + " and u.activo=true",
        hash,
        Timestamp.from(java.time.Instant.now()));
  }

  public void sessionAdd(long id, String hash, java.time.Instant expiry) {
    jdbc.update("delete from sesion where expira<?", Timestamp.from(java.time.Instant.now()));
    jdbc.update(
        "insert into sesion(usuario_id,token_hash,expira) values(?,?,?)",
        id,
        hash,
        Timestamp.from(expiry));
  }

  public void sessionRemove(String hash) {
    jdbc.update("delete from sesion where token_hash=?", hash);
  }

  public List<Map<String, Object>> projects() {
    return jdbc.queryForList(
        "select p.id,p.codigo,p.nombre,p.ubicacion,(select count(*) from manzana m join etapa e on"
            + " e.id=m.etapa_id where e.proyecto_id=p.id) as manzanas,(select count(*) from lote l"
            + " join manzana m on m.id=l.manzana_id join etapa e on e.id=m.etapa_id where"
            + " e.proyecto_id=p.id) as lotes,(select count(*) from lote l join manzana m on"
            + " m.id=l.manzana_id join etapa e on e.id=m.etapa_id where e.proyecto_id=p.id and"
            + " l.estado='DISPONIBLE') as disponibles from proyecto p where p.activo=true order by"
            + " p.id");
  }

  public List<Map<String, Object>> stages(long id) {
    return jdbc.queryForList(
        "select id,proyecto_id,nombre,orden from etapa where proyecto_id=? order by orden", id);
  }

  public List<Map<String, Object>> blocks(long id) {
    return jdbc.queryForList(
        "select m.id,m.codigo,e.id as etapa_id,e.nombre as etapa,count(l.id) as total,sum(case when"
            + " l.estado='DISPONIBLE' then 1 else 0 end) as disponibles from manzana m join etapa e"
            + " on e.id=m.etapa_id left join lote l on l.manzana_id=m.id where e.proyecto_id=?"
            + " group by m.id,m.codigo,e.id,e.nombre order by m.codigo",
        id);
  }

  private static final String LOT_SQL =
      "select l.id,l.manzana_id,l.codigo,l.area_m2,l.precio,l.estado,l.ubicacion as"
          + " referencia,m.codigo as manzana,e.id as etapa_id,e.nombre as"
          + " etapa,e.proyecto_id,p.nombre as proyecto,p.ubicacion,(select min(pp.inicial) from"
          + " lote_plan_pago lp join plan_pago pp on pp.id=lp.plan_pago_id where lp.lote_id=l.id"
          + " and pp.activo=true) as inicial,(select min(pp.numero_cuotas) from lote_plan_pago lp"
          + " join plan_pago pp on pp.id=lp.plan_pago_id where lp.lote_id=l.id and pp.activo=true)"
          + " as numero_cuotas from lote l join manzana m on m.id=l.manzana_id join etapa e on"
          + " e.id=m.etapa_id join proyecto p on p.id=e.proyecto_id";

  public List<Map<String, Object>> lots(Long project, Long block, String state, String query) {
    StringBuilder sql = new StringBuilder(LOT_SQL + " where 1=1");
    List<Object> p = new ArrayList<>();
    if (project != null) {
      sql.append(" and p.id=?");
      p.add(project);
    }
    if (block != null) {
      sql.append(" and m.id=?");
      p.add(block);
    }
    if (state != null && !state.isBlank()) {
      sql.append(" and l.estado=?");
      p.add(state);
    }
    if (query != null && !query.isBlank()) {
      sql.append(" and (lower(l.codigo) like ? or lower(m.codigo) like ?)");
      String q = "%" + query.toLowerCase(Locale.ROOT) + "%";
      p.add(q);
      p.add(q);
    }
    sql.append(" order by m.codigo,l.id");
    return jdbc.queryForList(sql.toString(), p.toArray());
  }

  public Map<String, Object> lot(long id, boolean lock) {
    if (lock) one("select id from lote where id=? for update", id);
    var row = one(LOT_SQL + " where l.id=?", id);
    row.put(
        "planes",
        jdbc.queryForList(
            "select pp.id,pp.nombre,pp.inicial,pp.numero_cuotas,pp.monto_cuota from plan_pago pp"
                + " join lote_plan_pago lp on pp.id=lp.plan_pago_id where lp.lote_id=? and"
                + " pp.activo=true order by pp.numero_cuotas",
            id));
    return row;
  }

  public void lockLots(long a, long b) {
    jdbc.queryForList(
        "select id from lote where id in (?,?) order by id for update",
        Math.min(a, b),
        Math.max(a, b));
  }

  public List<Map<String, Object>> clients(Actor actor, String q) {
    String sql =
        "select"
            + " id,tipo_documento,numero_documento,nombre,telefono,correo,direccion,ocupacion,proyecto_id,asesor_id"
            + " from cliente where (?=true or asesor_id=?) and (lower(nombre) like ? or"
            + " numero_documento like ? or telefono like ?) order by id desc";
    String term = "%" + (q == null ? "" : q.toLowerCase(Locale.ROOT)) + "%";
    return jdbc.queryForList(sql, actor.manager(), actor.id(), term, term, term);
  }

  public Map<String, Object> client(long id) {
    return one(
        "select"
            + " id,tipo_documento,numero_documento,nombre,telefono,correo,direccion,ocupacion,proyecto_id,asesor_id"
            + " from cliente where id=?",
        id);
  }

  public Map<String, Object> clientByDocument(String type, String number) {
    return optional(
        "select"
            + " id,tipo_documento,numero_documento,nombre,telefono,correo,direccion,ocupacion,proyecto_id,asesor_id"
            + " from cliente where tipo_documento=? and numero_documento=?",
        type,
        number);
  }

  public long clientAdd(Client c, Actor a) {
    return insert(
        "insert into"
            + " cliente(tipo_documento,numero_documento,nombre,telefono,correo,proyecto_id,asesor_id)"
            + " values(?,?,?,?,?,?,?)",
        c.tipo_documento(),
        c.numero_documento(),
        c.nombre(),
        c.telefono(),
        c.correo(),
        c.proyecto_id(),
        a.id());
  }

  public List<Map<String, Object>> reservations(Actor a) {
    return jdbc.queryForList(
        "select"
            + " s.id,s.lote_id,s.cliente_id,s.asesor_id,s.monto,s.fecha_registro,s.estado,s.observacion,s.plan_pago_id,s.cotitular_id,s.precio_acordado,s.inicial_acordada,s.cuota_acordada,s.numero_cuotas_acordado,c.nombre"
            + " as cliente,m.codigo as manzana,l.codigo as lote,p.nombre as proyecto from"
            + " separacion s join cliente c on c.id=s.cliente_id join lote l on l.id=s.lote_id join"
            + " manzana m on m.id=l.manzana_id join etapa e on e.id=m.etapa_id join proyecto p on"
            + " p.id=e.proyecto_id where (?=true or s.asesor_id=?) order by s.id desc",
        a.manager(),
        a.id());
  }

  public Map<String, Object> reservation(long id, boolean lock) {
    return one("select * from separacion where id=?" + (lock ? " for update" : ""), id);
  }

  public long reserve(long lot, long client, long actor, BigDecimal amount, String obs) {
    return insert(
        "insert into separacion(lote_id,cliente_id,asesor_id,monto,estado,observacion)"
            + " values(?,?,?,?,'ACTIVA',?)",
        lot,
        client,
        actor,
        amount,
        obs);
  }

  public void lotState(long id, String state) {
    jdbc.update("update lote set estado=?,version=version+1 where id=?", state, id);
  }

  public void reservationState(long id, String state) {
    jdbc.update("update separacion set estado=? where id=?", state, id);
  }

  public void reservationMove(long id, long lot) {
    jdbc.update("update separacion set lote_id=? where id=?", lot, id);
  }

  public void history(long lot, long actor, Long res, String old, String next, String reason) {
    jdbc.update(
        "insert into"
            + " historial_lote(lote_id,usuario_id,separacion_id,estado_anterior,estado_nuevo,motivo)"
            + " values(?,?,?,?,?,?)",
        lot,
        actor,
        res,
        old,
        next,
        reason);
  }

  public List<Map<String, Object>> history(long lot) {
    return jdbc.queryForList(
        "select h.id,h.estado_anterior,h.estado_nuevo,h.fecha_cambio,h.motivo,u.nombre as usuario"
            + " from historial_lote h join usuario u on u.id=h.usuario_id where h.lote_id=? order"
            + " by h.id desc",
        lot);
  }

  public void sale(long reservation, long responsible, Sale in) {
    jdbc.update(
        "insert into"
            + " venta(separacion_id,responsable_id,precio_final,inicial,contrato_firmado,fecha_venta,plan_pago_id)"
            + " values(?,?,?,?,?,?,?)",
        reservation,
        responsible,
        in.precio(),
        in.inicial(),
        in.contrato_firmado(),
        in.fecha(),
        in.plan_id());
  }

  public void document(long client, String side, String path) {
    jdbc.update(
        "delete from cliente_documento where cliente_id=? and tipo='DNI' and lado=?", client, side);
    jdbc.update(
        "insert into cliente_documento(cliente_id,tipo,lado,ruta_privada) values(?,'DNI',?,?)",
        client,
        side,
        path);
  }

  public List<Map<String, Object>> documents(long client) {
    return jdbc.queryForList(
        "select id,lado,fecha_carga from cliente_documento where cliente_id=? order by lado",
        client);
  }

  public Map<String, Object> document(long id) {
    return one("select * from cliente_documento where id=?", id);
  }
}
