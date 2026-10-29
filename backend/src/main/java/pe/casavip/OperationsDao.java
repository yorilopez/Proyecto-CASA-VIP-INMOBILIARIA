package pe.casavip;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.math.*;
import java.util.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import pe.casavip.ApiModels.Actor;

/** Persistencia de condiciones por operación, auditoría y avisos transaccionales. */
@Repository
public class OperationsDao {
  final JdbcTemplate jdbc;
  private final ObjectMapper json;
  public OperationsDao(JdbcTemplate jdbc, ObjectMapper json) { this.jdbc=jdbc; this.json=json; }
  public List<Map<String,Object>> list(String sql,Object... args){return jdbc.queryForList(sql,args);}
  public int execute(String sql,Object... args){return jdbc.update(sql,args);}
  public <T> T scalar(String sql,Class<T> type,Object... args){return jdbc.queryForObject(sql,type,args);}
  public String encode(Object value) {
    try { return json.writeValueAsString(value); }
    catch (Exception e) { throw new IllegalArgumentException("No se pudo registrar la información."); }
  }
  public Object decode(Object text) {
    if (text==null) return null;
    try { return json.readValue(text.toString(), Object.class); }
    catch(Exception e) { throw new IllegalArgumentException("El registro histórico no es válido."); }
  }
  public void audit(Actor a,String entity,long id,String action,String reason,Object before,Object after) {
    jdbc.update("insert into auditoria_comercial(usuario_id,entidad,registro_id,accion,motivo,anterior,actual) values(?,?,?,?,?,?,?)",
      a.id(),entity,id,action,BusinessRules.text(reason,500),before==null?null:encode(before),after==null?null:encode(after));
  }
  public Map<String,Object> row(String sql,Object... p) {
    var rows=jdbc.queryForList(sql,p); if(rows.isEmpty())throw new BusinessRules.Missing();return rows.getFirst();
  }
  public static BigDecimal money(Object n) {
    try { var d=new BigDecimal(n.toString()); if(d.scale()>2||d.abs().compareTo(new BigDecimal("999999999999.99"))>0)throw new NumberFormatException();return d.setScale(2); }
    catch(Exception e){throw new IllegalArgumentException("Usa un monto válido con hasta dos decimales.");}
  }
  public static Map<String,Object> financial(BigDecimal price,BigDecimal initial,int count) {
    if(price.signum()<=0||initial.signum()<=0||initial.compareTo(price)>0||count<1||count>600)
      throw new IllegalArgumentException("Revisa precio, inicial y número de cuotas (1 a 600).");
    price=money(price);initial=money(initial);
    var monthly=price.subtract(initial).divide(BigDecimal.valueOf(count),2,RoundingMode.DOWN);
    var last=price.subtract(initial).subtract(monthly.multiply(BigDecimal.valueOf(count-1)));
    return new LinkedHashMap<>(Map.of("precio",price,"inicial",initial,"numero_cuotas",count,"mensualidad",monthly,"ultima_cuota",last));
  }
  public void terms(long id,BigDecimal price,BigDecimal initial,int count) {
    var f=financial(price,initial,count);
    jdbc.update("update separacion set precio_acordado=?,inicial_acordada=?,numero_cuotas_acordado=?,cuota_acordada=?,version=version+1 where id=?",
      price,initial,count,f.get("mensualidad"),id);
  }
  public Map<String,Object> snapshot(long id) {return snapshot(id,false);}
  private Map<String,Object> snapshot(long id,boolean refreshPeople) {
    var s=row("select * from separacion where id=?",id);
    var l=row("select l.id,l.codigo,l.area_m2,l.precio,l.ubicacion,m.codigo as manzana,e.nombre as etapa,p.nombre as proyecto from lote l join manzana m on m.id=l.manzana_id join etapa e on e.id=m.etapa_id join proyecto p on p.id=e.proyecto_id where l.id=?",s.get("lote_id"));
    var c=row("select id,nombre,tipo_documento,numero_documento,telefono,correo,direccion,ocupacion from cliente where id=?",s.get("cliente_id"));
    var result=new LinkedHashMap<String,Object>();result.put("lote",l);result.put("titular",c);
    if(s.get("cotitular_id")!=null)result.put("cotitular",row("select id,nombre,tipo_documento,numero_documento,telefono,correo,direccion,ocupacion from cliente where id=?",s.get("cotitular_id")));
    if(s.get("precio_acordado")!=null&&s.get("inicial_acordada")!=null&&s.get("numero_cuotas_acordado")!=null)
      result.put("condiciones",financial(money(s.get("precio_acordado")),money(s.get("inicial_acordada")),((Number)s.get("numero_cuotas_acordado")).intValue()));
    result.put("monto_separacion",s.get("monto"));result.put("observacion",Objects.toString(s.get("observacion"),""));
    if(decode(s.get("datos_acordados")) instanceof Map<?,?> old){
      for(String key:List.of("lote","titular","cotitular")){
        if((!refreshPeople||key.equals("lote"))&&old.get(key) instanceof Map<?,?> prior&&result.get(key) instanceof Map<?,?> current&&Objects.toString(prior.get("id")).equals(Objects.toString(current.get("id"))))result.put(key,prior);
      }
    }
    return result;
  }
  public void capture(long id) {capture(id,false);}
  public void capture(long id,boolean refreshPeople) {
    var original=row("select datos_acordados from separacion where id=?",id);var next=snapshot(id,refreshPeople);
    Object prior=decode(original.get("datos_acordados"));boolean samePeople=false;
    if(prior instanceof Map<?,?> old){samePeople=Objects.equals(encode(old.get("titular")),encode(next.get("titular")))&&Objects.equals(encode(old.get("cotitular")),encode(next.get("cotitular")));}
    jdbc.update("update separacion set datos_acordados=? where id=?",encode(next),id);
    if(samePeople&&!refreshPeople&&jdbc.queryForObject("select count(*) from operacion_documento where separacion_id=?",Integer.class,id)>0)return;
    jdbc.update("update operacion_documento set activo=false where separacion_id=?",id);
    jdbc.update("update operacion_documento set activo=true where separacion_id=? and ruta_privada in (select cd.ruta_privada from cliente_documento cd join separacion s on s.id=? where cd.cliente_id=s.cliente_id or cd.cliente_id=s.cotitular_id)",id,id);
    jdbc.update("insert into operacion_documento(separacion_id,persona,lado,ruta_privada) select ?,c.nombre,d.lado,d.ruta_privada from cliente_documento d join cliente c on c.id=d.cliente_id join separacion s on s.id=? where (d.cliente_id=s.cliente_id or d.cliente_id=s.cotitular_id) and not exists(select 1 from operacion_documento od where od.separacion_id=? and od.ruta_privada=d.ruta_privada)",id,id,id);
  }
  public void notify(long id,String type) {
    var r=row("select l.codigo,m.codigo as manzana,p.nombre as proyecto from separacion s join lote l on l.id=s.lote_id join manzana m on m.id=l.manzana_id join etapa e on e.id=m.etapa_id join proyecto p on p.id=e.proyecto_id where s.id=?",id);
    String title=switch(type){case "VENTA"->"Venta registrada";case "LIBERACION"->"Lote liberado";default->"Separación registrada";};
    jdbc.update("insert into notificacion(operacion_id,tipo,titulo,mensaje) values(?,?,?,?)",id,type,title,r.get("proyecto")+" · Manzana "+r.get("manzana")+" · Lote "+r.get("codigo"));
  }
  public void created(long id, Actor actor) {capture(id);audit(actor,"OPERACION",id,"SEPARACION","Registro de separación",null,snapshot(id));notify(id,"SEPARACION");}
  public void released(long id, Actor actor,String reason) {jdbc.update("update separacion set condiciones_activas=false,version=version+1 where id=?",id);audit(actor,"OPERACION",id,"LIBERACION",reason,null,row("select * from separacion where id=?",id));notify(id,"LIBERACION");}
  public void sold(long id,Actor actor,BigDecimal price,BigDecimal initial,Integer count) {
    var s=row("select * from separacion where id=?",id);int n=count!=null?count:s.get("numero_cuotas_acordado")==null?1:((Number)s.get("numero_cuotas_acordado")).intValue();
    terms(id,price,initial,n);capture(id);var f=financial(price,initial,n);
    jdbc.update("update venta set numero_cuotas=?,mensualidad=?,ultima_cuota=?,datos_finales=? where separacion_id=?",n,f.get("mensualidad"),f.get("ultima_cuota"),encode(snapshot(id)),id);
    audit(actor,"OPERACION",id,"VENTA","Venta confirmada",decode(s.get("datos_acordados")),snapshot(id));notify(id,"VENTA");
  }
  public boolean retained(String path) {return jdbc.queryForObject("select count(*) from operacion_documento where ruta_privada=?",Integer.class,path)>0;}
}
