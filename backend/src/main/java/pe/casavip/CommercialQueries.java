package pe.casavip;

import java.time.*;
import java.time.format.DateTimeParseException;
import java.util.*;
import org.springframework.stereotype.Service;
import pe.casavip.ApiModels.Actor;

/** Consultas de listas y auditoría con períodos de negocio en Lima. */
@Service
public class CommercialQueries {
  private final OperationsDao d;
  private static final String RELEASE =
      "(select max(h.fecha_cambio) from historial_lote h where h.separacion_id=s.id and"
          + " h.estado_nuevo='DISPONIBLE' and h.estado_anterior='RESERVADO')";
  private static final String OPERATIONS =
      "select"
          + " s.id,s.lote_id,s.cliente_id,s.cotitular_id,s.asesor_id,s.monto,s.fecha_registro,s.fecha_vencimiento,s.plazo_dias,s.estado,s.observacion,s.precio_acordado,s.inicial_acordada,s.cuota_acordada,s.numero_cuotas_acordado,s.version,c.nombre"
          + " as cliente,m.codigo as manzana,l.codigo as lote,p.nombre as proyecto,e.nombre as"
          + " etapa,v.id as venta_id,v.precio_final,v.inicial as inicial_venta,v.numero_cuotas as"
          + " cuotas_venta,v.mensualidad as mensualidad_venta,v.fecha_venta,"
          + RELEASE
          + " as fecha_liberacion from separacion s join cliente c on c.id=s.cliente_id join lote l"
          + " on l.id=s.lote_id join manzana m on m.id=l.manzana_id join etapa e on e.id=m.etapa_id"
          + " join proyecto p on p.id=e.proyecto_id left join venta v on v.separacion_id=s.id";

  public CommercialQueries(OperationsDao d) {
    this.d = d;
  }

  public record Period(OffsetDateTime from, OffsetDateTime until) {
    public static Period parse(String month) {
      if (month == null || month.isBlank()) return null;
      try {
        if (!month.matches("\\d{4}-\\d{2}")) throw new DateTimeParseException("month", month, 0);
        var first = YearMonth.parse(month).atDay(1);
        if (first.getYear() < 1900 || first.getYear() > 9998) throw new IllegalArgumentException();
        return new Period(
            first.atStartOfDay(ZoneId.of("America/Lima")).toOffsetDateTime(),
            first.plusMonths(1).atStartOfDay(ZoneId.of("America/Lima")).toOffsetDateTime());
      } catch (RuntimeException e) {
        throw new IllegalArgumentException("Selecciona un mes válido (AAAA-MM).");
      }
    }

    String timestamp(String column, List<Object> args) {
      args.add(from);
      args.add(until);
      return column + ">=? and " + column + "<?";
    }

    String date(String column, List<Object> args) {
      args.add(from.toLocalDate());
      args.add(until.toLocalDate());
      return column + ">=? and " + column + "<?";
    }
  }

  public List<Map<String, Object>> operations(Actor a, String month, String state) {
    return operations(a, month, state, null);
  }

  public List<Map<String, Object>> operations(Actor a, String month, String state, Long person) {
    var args = new ArrayList<Object>();
    var sql = new StringBuilder(OPERATIONS + " where (?=true or s.asesor_id=?)");
    args.add(a.manager());
    args.add(a.id());
    if (person != null) {
      sql.append(" and (s.cliente_id=? or s.cotitular_id=?)");
      args.add(person);
      args.add(person);
    }
    if (state != null && !state.isBlank()) {
      sql.append(
          switch (state) {
            case "ACTIVA" -> " and s.estado='ACTIVA'";
            case "CONFIRMADA" -> " and s.estado='CONFIRMADA'";
            case "LIBERADA" -> " and s.estado in ('ANULADA','VENCIDA')";
            default -> throw new IllegalArgumentException("Estado inválido.");
          });
    }
    var period = Period.parse(month);
    if (period != null) {
      sql.append(" and ((s.estado='CONFIRMADA' and ")
          .append(period.date("v.fecha_venta", args))
          .append(") or (s.estado in ('ANULADA','VENCIDA') and ")
          .append(period.timestamp("coalesce(" + RELEASE + ",s.fecha_registro)", args))
          .append(") or (s.estado='ACTIVA' and ")
          .append(period.timestamp("s.fecha_registro", args))
          .append("))");
    }
    sql.append(" order by s.id desc");
    return d.list(sql.toString(), args.toArray());
  }

  public List<Map<String, Object>> clients(Actor a, String query, String month, String category) {
    var args = new ArrayList<Object>();
    args.add(a.manager());
    args.add(a.id());
    String term = "%" + Objects.toString(query, "").toLowerCase(Locale.ROOT) + "%";
    args.add(term);
    args.add(term);
    args.add(term);
    var sql =
        new StringBuilder(
            "select"
                + " c.id,c.tipo_documento,c.numero_documento,c.nombre,c.telefono,c.correo,c.direccion,c.ocupacion,c.proyecto_id,c.asesor_id,c.activo,c.fecha_registro"
                + " from cliente c where c.activo=true and (?=true or c.asesor_id=?) and"
                + " (lower(c.nombre) like ? or c.numero_documento like ? or c.telefono like ?)");
    var period = Period.parse(month);
    if (period != null) sql.append(" and ").append(period.timestamp("c.fecha_registro", args));
    String exists =
        "select 1 from separacion s where (s.cliente_id=c.id or s.cotitular_id=c.id) and (?=true or"
            + " s.asesor_id=?) and ";
    if (category != null && !category.isBlank()) {
      sql.append(
          switch (category) {
            case "POTENCIAL" ->
                " and not exists (" + exists + "s.estado in ('ACTIVA','CONFIRMADA'))";
            case "SEPARACION" -> " and exists (" + exists + "s.estado='ACTIVA')";
            case "VENTA" -> " and exists (" + exists + "s.estado='CONFIRMADA')";
            default -> throw new IllegalArgumentException("Tipo de cliente inválido.");
          });
      args.add(a.manager());
      args.add(a.id());
    }
    sql.append(" order by c.id desc");
    var people = d.list(sql.toString(), args.toArray());
    // Una sola consulta adicional y un índice en memoria, en lugar de buscar por cada cliente.
    if (!people.isEmpty()) {
      var byPerson = new HashMap<Long, List<Map<String, Object>>>();
      for (var operation : operations(a, null, null))
        for (String key : List.of("cliente_id", "cotitular_id")) {
          if (operation.get(key) instanceof Number n)
            byPerson.computeIfAbsent(n.longValue(), k -> new ArrayList<>()).add(operation);
        }
      for (var p : people)
        p.put("operaciones", byPerson.getOrDefault(((Number) p.get("id")).longValue(), List.of()));
    }
    return people;
  }

  public List<Map<String, Object>> history(Actor a, String entity, String month, Long user) {return history(a,entity,month,user,null);}

  public List<Map<String, Object>> history(Actor a, String entity, String month, Long user, String action) {
    BusinessRules.requireManager(a.role());
    var args = new ArrayList<Object>();
    var sql =
        new StringBuilder(
            "select h.*,u.nombre as usuario,r.nombre as rol from auditoria_comercial h join usuario"
                + " u on u.id=h.usuario_id join rol r on r.id=u.rol_id where 1=1");
    if (entity != null && !entity.isBlank()) {
      if (!Set.of("CLIENTE", "OPERACION", "USUARIO", "CATALOGO").contains(entity))
        throw new IllegalArgumentException("Tipo de historial inválido.");
      sql.append(" and h.entidad=?");
      args.add(entity);
    }
    if(action!=null&&!action.isBlank()){
      if(!Set.of("SEPARACION","VENTA","LIBERACION","PLAZO","MODIFICAR","REASIGNAR").contains(action))throw new IllegalArgumentException("Acción de historial inválida.");
      sql.append(" and h.accion=?");args.add(action);
    }
    if (user != null) {
      if (user < 1) throw new IllegalArgumentException("Usuario inválido.");
      sql.append(" and h.usuario_id=?");
      args.add(user);
    }
    var period = Period.parse(month);
    if (period != null) sql.append(" and ").append(period.timestamp("h.fecha", args));
    sql.append(" order by h.fecha desc,h.id desc");
    var rows = d.list(sql.toString(), args.toArray());
    for (var row : rows) {
      row.put("anterior", d.decode(row.get("anterior")));
      row.put("actual", d.decode(row.get("actual")));
    }
    return rows;
  }

  public List<Map<String, Object>> historyUsers(Actor a) {
    BusinessRules.requireManager(a.role());
    return d.list(
        "select u.id,u.nombre,u.activo,u.eliminado from usuario u where exists (select 1 from"
            + " auditoria_comercial h where h.usuario_id=u.id) order by u.nombre");
  }
}
