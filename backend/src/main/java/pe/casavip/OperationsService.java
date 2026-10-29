package pe.casavip;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.*;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import pe.casavip.ApiModels.*;
import pe.casavip.OperationModels.*;

/** Gestión de operaciones y personas con autorización y trazabilidad en el servidor. */
@Service
public class OperationsService {
 final OperationsDao d;final CommercialDao commercial;final CommercialService service;
 public OperationsService(OperationsDao d,CommercialDao commercial,CommercialService service){this.d=d;this.commercial=commercial;this.service=service;}
 private static long id(Map<String,Object> r,String k){return CommercialService.id(r,k);}
 public Map<String,Object> authorized(long id,Actor a,boolean lock){
   var r=commercial.reservation(id,lock);
   if(!a.manager()&&id(r,"asesor_id")!=a.id())throw new BusinessRules.Forbidden("La operación pertenece a otro asesor.");return r;
 }
 public List<Map<String,Object>> operations(Actor a){
   return d.list("select s.*,c.nombre as cliente,m.codigo as manzana,l.codigo as lote,p.nombre as proyecto,e.nombre as etapa,v.id as venta_id,v.precio_final,v.inicial as inicial_venta,v.numero_cuotas as cuotas_venta,v.mensualidad as mensualidad_venta,v.fecha_venta from separacion s join cliente c on c.id=s.cliente_id join lote l on l.id=s.lote_id join manzana m on m.id=l.manzana_id join etapa e on e.id=m.etapa_id join proyecto p on p.id=e.proyecto_id left join venta v on v.separacion_id=s.id where (?=true or s.asesor_id=?) order by s.id desc",a.manager(),a.id());
 }
 public Map<String,Object> detail(long id,Actor a){
   var r=authorized(id,a,false);r.put("datos_acordados",d.decode(r.get("datos_acordados")));
   var sales=d.list("select * from venta where separacion_id=?",id);
   if(!sales.isEmpty()){var v=sales.getFirst();v.put("datos_finales",d.decode(v.get("datos_finales")));r.put("venta",v);}
   var lot=commercial.lot(id(r,"lote_id"),false);r.put("lote_actual",lot);r.put("asesor_nombre",d.row("select nombre from usuario where id=?",r.get("asesor_id")).get("nombre"));
   if(a.manager())r.put("documentos",d.list("select id,persona,lado from operacion_documento where separacion_id=? and activo=true order by id",id));
   r.put("historial",d.list("select ac.id,ac.accion,ac.motivo,ac.fecha,u.nombre as usuario from auditoria_comercial ac join usuario u on u.id=ac.usuario_id where ac.entidad='OPERACION' and ac.registro_id=? order by ac.id desc",id));return r;
 }
 public List<Map<String,Object>> clients(Actor a,String q){
   var clients=commercial.clients(a,q);var ops=operations(a);
   for(var c:clients)c.put("operaciones",ops.stream().filter(r->Objects.equals(r.get("cliente_id"),c.get("id"))||Objects.equals(r.get("cotitular_id"),c.get("id"))).toList());return clients;
 }
 public Map<String,Object> clientProfile(long id,Actor a){var c=service.clientProfile(id,a);c.put("operaciones",operations(a).stream().filter(r->id(r,"cliente_id")==id||(r.get("cotitular_id")!=null&&id(r,"cotitular_id")==id)).toList());return c;}
 @Transactional public void archiveClient(long id,Actor a){
   var old=service.client(id,a);d.execute("update cliente set activo=false where id=?",id);
   d.execute("delete from cliente_relacion where cliente_id=? or relacionado_id=?",id,id);
   d.audit(a,"CLIENTE",id,"ELIMINAR","Retirado del registro activo; operaciones conservadas",old,Map.of("activo",false));
 }
 @Transactional public void unlink(long id,Actor a){
   service.client(id,a);var old=d.list("select relacionado_id from cliente_relacion where cliente_id=? and tipo='COTITULAR'",id);
   d.execute("delete from cliente_relacion where cliente_id=? and tipo='COTITULAR'",id);
   d.audit(a,"CLIENTE",id,"DESVINCULAR","Cotitular desvinculado; operaciones anteriores conservadas",old,null);
 }
 @Transactional public Map<String,Object> correct(long operation,Correction in,Actor a){
   BusinessRules.requireManager(a.role());var prior=authorized(operation,a,true);
   if(id(prior,"version")!=in.version())throw new BusinessRules.Conflict("La operación cambió. Actualiza antes de guardar.");
   OperationsDao.financial(in.precio(),in.inicial(),in.numero_cuotas());BusinessRules.amount(in.monto(),in.precio());
   long client=in.cliente_id()==null?id(prior,"cliente_id"):in.cliente_id();var person=service.client(client,a);
   var lot=commercial.lot(id(prior,"lote_id"),true);
   if(id(person,"proyecto_id")!=id(lot,"proyecto_id"))throw new IllegalArgumentException("El cliente debe pertenecer al proyecto del lote.");
   Long co=in.quitar_cotitular()?null:in.cotitular_id()!=null?in.cotitular_id():prior.get("cotitular_id")==null?null:id(prior,"cotitular_id");
   if(co!=null){var cp=service.client(co,a);if(co==client||id(cp,"proyecto_id")!=id(lot,"proyecto_id"))throw new IllegalArgumentException("Revisa el cotitular y su proyecto.");}
   long advisor=in.asesor_id()==null?id(prior,"asesor_id"):in.asesor_id();
   if(advisor!=id(prior,"asesor_id"))d.row("select id from usuario where id=? and activo=true and eliminado=false",advisor);
   d.execute("update separacion set cliente_id=?,cotitular_id=?,asesor_id=?,monto=?,observacion=? where id=?",client,co,advisor,in.monto(),in.observacion(),operation);
   d.terms(operation,in.precio(),in.inicial(),in.numero_cuotas());d.capture(operation,in.actualizar_personas());var f=OperationsDao.financial(in.precio(),in.inicial(),in.numero_cuotas());
   if("CONFIRMADA".equals(prior.get("estado")))d.execute("update venta set precio_final=?,inicial=?,numero_cuotas=?,mensualidad=?,ultima_cuota=?,datos_finales=?,fecha_venta=coalesce(?,fecha_venta) where separacion_id=?",in.precio(),in.inicial(),in.numero_cuotas(),f.get("mensualidad"),f.get("ultima_cuota"),d.encode(d.snapshot(operation)),in.fecha(),operation);
   d.audit(a,"OPERACION",operation,"CORREGIR",in.motivo(),prior,commercial.reservation(operation,false));return detail(operation,a);
 }
 public Map<String,Object> share(long id,Actor a){BusinessRules.requireManager(a.role());var r=detail(id,a);r.remove("historial");return r;}
 public List<Map<String,Object>> history(Actor a,String entity){
   BusinessRules.requireManager(a.role());
   if(entity!=null&&!Set.of("CLIENTE","OPERACION","USUARIO","CATALOGO").contains(entity))throw new IllegalArgumentException("Tipo de historial inválido.");
   String sql="select h.*,u.nombre as usuario from auditoria_comercial h join usuario u on u.id=h.usuario_id";
   var rows=entity==null?d.list(sql+" order by h.id desc limit 500"):d.list(sql+" where h.entidad=? order by h.id desc limit 500",entity);
   for(var r:rows){r.put("anterior",d.decode(r.get("anterior")));r.put("actual",d.decode(r.get("actual")));}return rows;
 }
 public List<Map<String,Object>> users(Actor a){BusinessRules.requireManager(a.role());return d.list("select u.id,u.nombre,u.correo,u.telefono,u.activo,r.nombre as rol from usuario u join rol r on r.id=u.rol_id where eliminado=false order by u.nombre");}
 private void userLock(){d.list("select id from rol order by id for update");}
 private void protect(long id,boolean active,String role,Actor a){
   var old=d.row("select u.*,r.nombre as rol from usuario u join rol r on r.id=u.rol_id where u.id=? and eliminado=false",id);
   if(id==a.id()&&(!active||!role.equals(a.role())))throw new IllegalArgumentException("Conserva tu cuenta activa y su rol durante esta sesión.");
   if(Boolean.TRUE.equals(old.get("activo"))&&"ADMINISTRADOR".equals(old.get("rol"))&&(!active||!role.equals("ADMINISTRADOR"))&&d.scalar("select count(*) from usuario u join rol r on r.id=u.rol_id where r.nombre='ADMINISTRADOR' and activo=true and eliminado=false",Integer.class)<=1)
     throw new BusinessRules.Conflict("Debe permanecer al menos un administrador activo.");
 }
 public static void password(String password){if(password==null||password.length()<8||password.codePointCount(0,password.length())>64||password.getBytes(StandardCharsets.UTF_8).length>72)throw new IllegalArgumentException("La contraseña debe tener entre 8 y 64 caracteres y hasta 72 bytes UTF-8.");}
 @Transactional public Map<String,Object> saveUser(Long id,UserInput in,Actor a){
   BusinessRules.requireAdmin(a.role());userLock();var role=d.row("select id from rol where nombre=?",in.rol());
   var before=id==null?null:d.row("select id,nombre,correo,activo,rol_id,telefono from usuario where id=? and eliminado=false",id);
   if(id!=null)protect(id,in.activo(),in.rol(),a);
   boolean newPassword=in.password()!=null&&!in.password().isEmpty();if(id==null||newPassword)password(in.password());
   String name=BusinessRules.text(in.nombre(),160),email=in.correo().strip().toLowerCase(Locale.ROOT);
   if(id==null){d.execute("insert into usuario(nombre,correo,rol_id,telefono,password_hash,activo) values(?,?,?,?,?,?)",name,email,role.get("id"),in.telefono(),new BCryptPasswordEncoder(12).encode(in.password()),in.activo());id=id(d.row("select id from usuario where correo=?",email),"id");}
   else {d.execute("update usuario set nombre=?,correo=?,rol_id=?,telefono=?,activo=? where id=?",name,email,role.get("id"),in.telefono(),in.activo(),id);if(newPassword)d.execute("update usuario set password_hash=? where id=?",new BCryptPasswordEncoder(12).encode(in.password()),id);d.execute("delete from sesion where usuario_id=?",id);}
   var after=d.row("select id,nombre,correo,activo,rol_id,telefono from usuario where id=?",id);d.audit(a,"USUARIO",id,before==null?"CREAR":"MODIFICAR","Administración de usuarios",before,after);return after;
 }
 @Transactional public void activeUser(long id,boolean active,Actor a){
   BusinessRules.requireManager(a.role());userLock();if(!"ADMINISTRADOR".equals(a.role())&&active)throw new BusinessRules.Forbidden("El responsable comercial solo puede deshabilitar usuarios.");
   var old=d.row("select u.id,u.activo,r.nombre as rol from usuario u join rol r on r.id=u.rol_id where u.id=? and eliminado=false",id);protect(id,active,(String)old.get("rol"),a);
   d.execute("update usuario set activo=? where id=?",active,id);d.execute("delete from sesion where usuario_id=?",id);d.audit(a,"USUARIO",id,active?"HABILITAR":"DESHABILITAR","Cambio de acceso",old,Map.of("activo",active));
 }
 @Transactional public void deleteUser(long id,Actor a){BusinessRules.requireAdmin(a.role());userLock();var old=d.row("select u.id,u.activo,r.nombre as rol from usuario u join rol r on r.id=u.rol_id where u.id=? and eliminado=false",id);protect(id,false,(String)old.get("rol"),a);d.execute("update usuario set activo=false,eliminado=true where id=?",id);d.execute("delete from sesion where usuario_id=?",id);d.audit(a,"USUARIO",id,"ELIMINAR","Cuenta retirada; referencias históricas conservadas",old,null);}
 public Map<String,Object> notifications(Actor a){
   var items=d.list("select n.id,n.tipo,n.titulo,n.mensaje,n.fecha,case when nr.notificacion_id is null then false else true end as leida,case when (?=true or s.asesor_id=?) then n.operacion_id else null end as operacion_id from notificacion n left join separacion s on s.id=n.operacion_id left join notificacion_lectura nr on nr.notificacion_id=n.id and nr.usuario_id=? order by n.id desc limit 100",a.manager(),a.id(),a.id());
   var count=d.scalar("select count(*) from notificacion n where not exists(select 1 from notificacion_lectura nr where nr.notificacion_id=n.id and nr.usuario_id=?)",Long.class,a.id());return Map.of("items",items,"pendientes",count);
 }
 @Transactional public void read(long until,Actor a){d.execute("insert into notificacion_lectura(usuario_id,notificacion_id) select ?,n.id from notificacion n where n.id<=? and not exists(select 1 from notificacion_lectura r where r.usuario_id=? and r.notificacion_id=n.id)",a.id(),until,a.id());}
 @Transactional public void readOne(long id,Actor a){d.row("select id from notificacion where id=?",id);d.execute("insert into notificacion_lectura(usuario_id,notificacion_id) select ?,? where not exists(select 1 from notificacion_lectura where usuario_id=? and notificacion_id=?)",a.id(),id,a.id(),id);}
}
