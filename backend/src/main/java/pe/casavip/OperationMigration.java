package pe.casavip;
import java.math.BigDecimal;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/** Completa instantáneas de registros anteriores una sola vez, sin emitir avisos nuevos. */
@Component
public class OperationMigration {
 final OperationsDao d;final CommercialDao dao;
 public OperationMigration(OperationsDao d,CommercialDao dao){this.d=d;this.dao=dao;}
 @EventListener(ApplicationReadyEvent.class) @Transactional public void migrate(){
   for(var s:d.list("select * from separacion where datos_acordados is null")){
     long id=CommercialService.id(s,"id");var lot=dao.lot(CommercialService.id(s,"lote_id"),false);
     var sales=d.list("select * from venta where separacion_id=?",id);
     if(s.get("precio_acordado")==null||s.get("inicial_acordada")==null||s.get("numero_cuotas_acordado")==null){
       var plans=(java.util.List<java.util.Map<String,Object>>)lot.get("planes");var plan=plans.isEmpty()?null:plans.getLast();
       var sale=sales.isEmpty()?null:sales.getFirst();var price=sale!=null?(BigDecimal)sale.get("precio_final"):(BigDecimal)lot.get("precio");
       var initial=sale!=null?(BigDecimal)sale.get("inicial"):plan==null?price:(BigDecimal)plan.get("inicial");int n=plan==null?1:((Number)plan.get("numero_cuotas")).intValue();
       d.terms(id,price,initial,n);
     }
     d.capture(id);
     if(!sales.isEmpty()){var now=dao.reservation(id,false);var f=OperationsDao.financial((BigDecimal)now.get("precio_acordado"),(BigDecimal)now.get("inicial_acordada"),((Number)now.get("numero_cuotas_acordado")).intValue());d.execute("update venta set numero_cuotas=?,mensualidad=?,ultima_cuota=?,datos_finales=? where separacion_id=?",f.get("numero_cuotas"),f.get("mensualidad"),f.get("ultima_cuota"),d.encode(d.snapshot(id)),id);}
     if(!"ACTIVA".equals(s.get("estado"))&&!"CONFIRMADA".equals(s.get("estado")))d.execute("update separacion set condiciones_activas=false where id=?",id);
   }
 }
}
