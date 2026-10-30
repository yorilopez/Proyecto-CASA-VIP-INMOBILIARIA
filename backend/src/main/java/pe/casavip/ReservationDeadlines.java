package pe.casavip;

import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import pe.casavip.ApiModels.Actor;

@Service
public class ReservationDeadlines {
  private final OperationsDao d;
  @org.springframework.beans.factory.annotation.Value("${app.deadlines.enabled:true}") boolean enabled;
  public ReservationDeadlines(OperationsDao d) { this.d = d; }

  public static int days(BigDecimal amount, Integer requested) {
    int preset = amount.compareTo(new BigDecimal("100")) == 0 ? 3
        : amount.compareTo(new BigDecimal("200")) == 0 ? 5
        : amount.compareTo(new BigDecimal("500")) == 0 ? 14 : 0;
    int result = requested == null ? preset : requested;
    if (result < 1 || result > 3650)
      throw new IllegalArgumentException("Indica un plazo de 1 a 3650 días.");
    if (preset > 0 && result > preset)
      throw new IllegalArgumentException("El plazo inicial para este monto es de hasta " + preset + " días.");
    return result;
  }

  public void initialize(long id, BigDecimal amount, Integer requested) {
    int count = days(amount, requested);
    d.execute("update separacion set plazo_dias=?,fecha_vencimiento=fecha_registro + (? * interval '1' day) where id=?", count, count, id);
  }

  @Transactional
  public Map<String,Object> change(long id, int days, long version, Actor actor) {
    BusinessRules.requireManager(actor.role());
    if (days < 1 || days > 3650) throw new IllegalArgumentException("Indica un plazo de 1 a 3650 días.");
    var before = d.row("select * from separacion where id=? for update", id);
    if (!"ACTIVA".equals(before.get("estado"))) throw new BusinessRules.Conflict("La separación ya no está activa.");
    if (((Number) before.get("version")).longValue() != version)
      throw new BusinessRules.Conflict("La operación cambió. Vuelve a abrirla.");
    d.execute("update separacion set plazo_dias=?,fecha_vencimiento=fecha_registro + (? * interval '1' day),vencimiento_avisado=null,version=version+1 where id=?", days, days, id);
    var after = d.row("select plazo_dias,fecha_vencimiento from separacion where id=?", id);
    d.audit(actor,"OPERACION",id,"PLAZO","Plazo de separación actualizado",
        Map.of("plazo_dias",Objects.toString(before.get("plazo_dias"),""),"fecha_vencimiento",Objects.toString(before.get("fecha_vencimiento"),"")),after);
    return after;
  }

  @Scheduled(fixedDelayString="${app.deadlines.poll-ms:60000}",initialDelay=10000)
  @Transactional
  public void scheduledScan() {if(enabled)scan();}

  @Transactional
  public void scan() {
    d.execute("update separacion set plazo_dias=case when monto=100 then 3 when monto=200 then 5 when monto=500 then 14 end where plazo_dias is null and monto in (100,200,500)");
    d.execute("update separacion set fecha_vencimiento=fecha_registro + (plazo_dias * interval '1' day) where fecha_vencimiento is null and plazo_dias is not null");
    for (var row : d.list("select id from separacion where estado='ACTIVA' and fecha_vencimiento<=CURRENT_TIMESTAMP and (vencimiento_avisado is null or vencimiento_avisado<>fecha_vencimiento) order by id")) {
      long id = ((Number)row.get("id")).longValue();
      var locked = d.row("select * from separacion where id=? for update", id);
      if (!"ACTIVA".equals(locked.get("estado")) || locked.get("fecha_vencimiento")==null ||
          Objects.equals(locked.get("vencimiento_avisado"),locked.get("fecha_vencimiento"))) continue;
      var due = CommercialDashboard.instant(locked.get("fecha_vencimiento"));
      if (due.isAfter(Instant.now())) continue;
      d.notify(id,"VENCIMIENTO");
      d.execute("update separacion set vencimiento_avisado=fecha_vencimiento where id=?",id);
    }
  }
}
