package pe.casavip;

import java.io.IOException;
import java.util.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import pe.casavip.ApiModels.Actor;

@RestController
@RequestMapping("/api")
public class DashboardController {
  final CommercialDashboard dashboard;final DashboardReports reports;final CommercialQueries queries;final ReservationDeadlines deadlines;
  public DashboardController(CommercialDashboard dashboard,DashboardReports reports,CommercialQueries queries,ReservationDeadlines deadlines){this.dashboard=dashboard;this.reports=reports;this.queries=queries;this.deadlines=deadlines;}
  @GetMapping("/dashboard")
  public Object dashboard(@RequestParam(required=false)String month,@RequestParam(required=false)Long user,@RequestParam(required=false)Long project,@AuthenticationPrincipal Actor actor){return dashboard.data(actor,month,user,project);}
  @GetMapping("/reports/monthly.{format}")
  public ResponseEntity<byte[]> monthly(@PathVariable String format,@RequestParam(required=false)String month,@RequestParam(defaultValue="general")String section,@RequestParam(required=false)Long user,@RequestParam(required=false)Long project,@AuthenticationPrincipal Actor actor)throws IOException {
    var data=dashboard.data(actor,month,user,project);var filters=(Map<?,?>)data.get("filtros");
    String context="Mes: "+data.get("mes")+" / Asesor: "+filters.get("asesor")+" / Proyecto: "+filters.get("proyecto");
    return download(format,"CASA_VIP_"+data.get("mes")+"_"+section,reports.export(format,"Reporte mensual "+data.get("mes"),context,reports.sections(data,section)));
  }
  @GetMapping("/reports/history.{format}")
  public ResponseEntity<byte[]> history(@PathVariable String format,@RequestParam(required=false)String month,@RequestParam(required=false)String entity,@RequestParam(required=false)String action,@RequestParam(required=false)Long user,@AuthenticationPrincipal Actor actor)throws IOException {
    var data=queries.history(actor,entity,month,user,action);
    String context="Período: "+Objects.toString(month,"Todos")+" / Tipo: "+Objects.toString(entity,"Todos")+" / Acción: "+Objects.toString(action,"Todas")+" / Usuario: "+(user==null?"Todos":user);
    return download(format,"CASA_VIP_historial_"+(month==null||month.isBlank()?"todos":month),reports.export(format,"Historial comercial",context,List.of(reports.history(data))));
  }
  static ResponseEntity<byte[]> download(String format,String name,byte[] bytes){
    String mime=switch(format){case "pdf"->"application/pdf";case "xlsx"->"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";case "txt"->"text/plain;charset=UTF-8";default->throw new IllegalArgumentException("Formato inválido.");};
    return ResponseEntity.ok().contentType(MediaType.parseMediaType(mime)).header("Content-Disposition","attachment; filename="+name+"."+format).header("Cache-Control","no-store").body(bytes);
  }
  public record DeadlineInput(@Min(1)@Max(3650)int dias,@PositiveOrZero long version){}
  @PatchMapping("/operations/{id}/deadline")
  public Object deadline(@PathVariable long id,@Valid@RequestBody DeadlineInput input,@AuthenticationPrincipal Actor actor){return deadlines.change(id,input.dias(),input.version(),actor);}
}
