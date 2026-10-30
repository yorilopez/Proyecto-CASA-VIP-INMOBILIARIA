package pe.casavip;

import java.time.*;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import pe.casavip.ApiModels.Actor;

@Service
public class CommercialDashboard {
  final OperationsDao d;
  final CommercialQueries queries;
  public CommercialDashboard(OperationsDao d, CommercialQueries queries) { this.d=d;this.queries=queries; }
  static final ZoneId LIMA=ZoneId.of("America/Lima");
  static final String BASE="select s.id,s.fecha_registro,s.fecha_vencimiento,s.plazo_dias,s.estado,s.cliente_id,s.cotitular_id,s.asesor_id,u.nombre as asesor,ar.nombre as rol_asesor,c.nombre as cliente,c.numero_documento as documento,c.telefono,co.nombre as cotitular,co.numero_documento as documento_cotitular,p.id as proyecto_id,p.nombre as proyecto,m.codigo as manzana,l.codigo as lote from separacion s join usuario u on u.id=s.asesor_id join rol ar on ar.id=u.rol_id join cliente c on c.id=s.cliente_id left join cliente co on co.id=s.cotitular_id join lote l on l.id=s.lote_id join manzana m on m.id=l.manzana_id join etapa e on e.id=m.etapa_id join proyecto p on p.id=e.proyecto_id";

  static String scope(String alias, Long advisor,Long project,List<Object> args) {
    String sql="";
    if(advisor!=null){if(advisor<1)throw new IllegalArgumentException("Selecciona un asesor válido.");sql+=" and "+alias+".asesor_id=?";args.add(advisor);}
    if(project!=null){if(project<1)throw new IllegalArgumentException("Selecciona un proyecto válido.");sql+=" and p.id=?";args.add(project);}
    return sql;
  }
  public static String month(String value) {
    String m=value==null||value.isBlank()?YearMonth.now(LIMA).toString():value;
    CommercialQueries.Period.parse(m);return m;
  }

  @Transactional(readOnly=true,isolation=org.springframework.transaction.annotation.Isolation.REPEATABLE_READ)
  public Map<String,Object> data(Actor actor,String month,Long advisor,Long project) {
    BusinessRules.requireManager(actor.role());
    month=month(month);var period=CommercialQueries.Period.parse(month);
    var args=new ArrayList<Object>();
    String filter=scope("s",advisor,project,args);
    var sepArgs=new ArrayList<>(args);
    var separations=d.list(BASE+" where 1=1"+filter+" and "+period.timestamp("s.fecha_registro",sepArgs)+" order by s.fecha_registro desc,s.id desc",sepArgs.toArray());
    var saleArgs=new ArrayList<>(args);
    String saleBase=BASE.replace(" from separacion s ",",v.fecha_venta from separacion s join venta v on v.separacion_id=s.id ");
    var sales=d.list(saleBase+" where 1=1"+filter+" and "+period.date("v.fecha_venta",saleArgs)+" order by v.fecha_venta desc,s.id desc",saleArgs.toArray());
    var releaseArgs=new ArrayList<>(args);
    String releaseBase=BASE.replace(" from separacion s ",",h.fecha as fecha_liberacion,h.motivo,ru.nombre as responsable from separacion s join auditoria_comercial h on h.entidad='OPERACION' and h.registro_id=s.id and h.accion='LIBERACION' join usuario ru on ru.id=h.usuario_id ");
    var releases=d.list(releaseBase+" where 1=1"+filter+" and "+period.timestamp("h.fecha",releaseArgs)+" order by h.fecha desc,h.id desc",releaseArgs.toArray());
    var clientArgs=new ArrayList<Object>();
    String clientScope=scope("c",advisor,project,clientArgs);
    var clients=d.list("select c.id,c.nombre,c.tipo_documento,c.numero_documento,c.telefono,c.correo,c.fecha_registro,p.nombre as proyecto,case when exists(select 1 from separacion cs where cs.cotitular_id=c.id) or exists(select 1 from cliente_relacion cr where cr.relacionado_id=c.id) then 'Cotitular' else 'Titular' end as participacion from cliente c join proyecto p on p.id=c.proyecto_id where 1=1"+clientScope+" and "+period.timestamp("c.fecha_registro",clientArgs)+" order by c.fecha_registro desc,c.id desc",clientArgs.toArray());
    var allArgs=new ArrayList<>(args);
    var all=d.list(BASE+" where 1=1"+filter+" order by s.id desc",allArgs.toArray());
    var personLots=new HashMap<Long,List<String>>();
    for(var op:all) if(Set.of("ACTIVA","CONFIRMADA").contains(Objects.toString(op.get("estado")))) {
      String label=op.get("proyecto")+" / Mz "+op.get("manzana")+" / Lote "+op.get("lote")+" / "+("CONFIRMADA".equals(op.get("estado"))?"Vendido":"Separado");
      for(String key:List.of("cliente_id","cotitular_id"))if(op.get(key) instanceof Number n)personLots.computeIfAbsent(n.longValue(),x->new ArrayList<>()).add(label);
    }
    for(var person:clients)person.put("lotes",personLots.getOrDefault(((Number)person.get("id")).longValue(),List.of()));
    var byAdvisor=new LinkedHashMap<Long,Map<String,Object>>();
    for(var group:List.of(separations,sales))for(var op:group){
      long id=((Number)op.get("asesor_id")).longValue();
      var entry=byAdvisor.computeIfAbsent(id,x->{var n=new LinkedHashMap<String,Object>();n.put("id",id);n.put("asesor",op.get("asesor"));n.put("rol",op.get("rol_asesor"));n.put("separaciones",0);n.put("ventas",0);n.put("lotes_separados",new ArrayList<String>());n.put("lotes_vendidos",new ArrayList<String>());return n;});
      String key=group==separations?"separaciones":"ventas",lotKey=group==separations?"lotes_separados":"lotes_vendidos";
      entry.put(key,((Number)entry.get(key)).intValue()+1);
      ((List<String>)entry.get(lotKey)).add(op.get("proyecto")+" / Mz "+op.get("manzana")+" / Lote "+op.get("lote"));
    }
    var activity=new ArrayList<>(byAdvisor.values());
    activity.sort(Comparator.comparing(e->Objects.toString(e.get("asesor"))));
    var ranking=new ArrayList<>(activity.stream().filter(e->"ASESOR".equals(e.get("rol"))&&((Number)e.get("ventas")).intValue()>0).toList());
    ranking.sort(Comparator.<Map<String,Object>>comparingInt(e->((Number)e.get("ventas")).intValue()).reversed().thenComparing(e->Objects.toString(e.get("asesor"))));
    int position=0,last=-1,index=0;
    for(var entry:ranking){index++;int count=((Number)entry.get("ventas")).intValue();if(count!=last)position=index;last=count;entry.put("posicion",position);}
    var pending=new ArrayList<Map<String,Object>>();
    Instant now=Instant.now();
    for(var op:all)if("ACTIVA".equals(op.get("estado"))){
      Object due=op.get("fecha_vencimiento");
      if(due==null){op.put("alerta","Sin plazo");pending.add(op);}
      else {Instant at=instant(due);if(!at.isAfter(now.plus(Duration.ofDays(3)))){op.put("alerta",at.isAfter(now)?"Por vencer":"Vencida");pending.add(op);}}
    }
    pending.sort(Comparator.comparing(op->Objects.toString(op.get("fecha_vencimiento"),"9999")));
    var totals=new LinkedHashMap<String,Object>();
    totals.put("separaciones",separations.size());totals.put("ventas",sales.size());totals.put("clientes",clients.size());totals.put("cotitulares",clients.stream().filter(c->"Cotitular".equals(c.get("participacion"))).count());totals.put("liberaciones",releases.size());totals.put("vencidas",pending.stream().filter(op->"Vencida".equals(op.get("alerta"))).count());
    var result=new LinkedHashMap<String,Object>();result.put("mes",month);result.put("generado",OffsetDateTime.now(LIMA));result.put("totales",totals);result.put("separaciones",separations);result.put("ventas",sales);result.put("clientes",clients);result.put("asesores",activity);result.put("ranking",ranking);result.put("liberaciones",releases);result.put("alertas",pending);
    result.put("filtros",Map.of("asesor",advisor==null?"Todos":Objects.toString(d.row("select nombre from usuario where id=?",advisor).get("nombre")),"proyecto",project==null?"Todos":Objects.toString(d.row("select nombre from proyecto where id=?",project).get("nombre"))));
    result.put("usuarios",d.list("select distinct u.id,u.nombre from usuario u where exists(select 1 from separacion s where s.asesor_id=u.id) or exists(select 1 from cliente c where c.asesor_id=u.id) order by u.nombre"));
    result.put("proyectos",d.list("select id,nombre from proyecto order by nombre"));
    return result;
  }

  static Instant instant(Object value){if(value instanceof OffsetDateTime d)return d.toInstant();if(value instanceof java.util.Date d)return d.toInstant();return OffsetDateTime.parse(value.toString()).toInstant();}
}
