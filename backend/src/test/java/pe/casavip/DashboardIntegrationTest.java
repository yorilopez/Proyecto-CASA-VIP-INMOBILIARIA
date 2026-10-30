package pe.casavip;

import static org.junit.jupiter.api.Assertions.*;
import java.math.BigDecimal;
import java.io.*;
import java.time.*;
import java.util.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;
import pe.casavip.ApiModels.*;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class DashboardIntegrationTest {
  @Autowired OperationsDao d;
  @Autowired CommercialDashboard dashboard;
  @Autowired DashboardReports reports;
  @Autowired ReservationDeadlines deadlines;
  @Autowired OperationsService operations;
  @Autowired CommercialQueries queries;
  @Autowired AuthService auth;
  Actor admin=new Actor(3,"Admin","ADMINISTRADOR"),manager=new Actor(2,"Responsable","RESPONSABLE_COMERCIAL"),advisor=new Actor(1,"Asesor","ASESOR");
  @BeforeEach void fixture(){
    for(String table:List.of("notificacion_lectura","notificacion","auditoria_comercial","operacion_documento","cliente_documento","historial_lote","venta","separacion","cliente_relacion","cliente"))d.execute("delete from "+table);
    d.execute("insert into cliente(id,tipo_documento,numero_documento,nombre,proyecto_id,asesor_id,fecha_registro) values(1,'DNI','98060001','Titular mensual',1,1,?),(2,'DNI','98060002','Cotitular mensual',1,1,?)",OffsetDateTime.parse("2026-10-10T10:00:00-05:00"),OffsetDateTime.parse("2026-10-11T10:00:00-05:00"));
    d.execute("insert into cliente_relacion(cliente_id,relacionado_id,tipo) values(1,2,'COTITULAR')");
    d.execute("insert into separacion(id,lote_id,cliente_id,cotitular_id,asesor_id,monto,estado,fecha_registro) values(1,4,1,2,1,100,'ACTIVA',?),(2,5,1,2,1,500,'CONFIRMADA',?)",OffsetDateTime.parse("2026-10-01T10:00:00-05:00"),OffsetDateTime.parse("2026-09-01T10:00:00-05:00"));
    d.execute("insert into venta(separacion_id,responsable_id,precio_final,inicial,contrato_firmado,fecha_venta) values(2,2,21000,3000,true,?)",LocalDate.of(2026,10,12));
  }
  Map<?,?> totals(Map<String,Object> data){return (Map<?,?>)data.get("totales");}
  @Test void mesSeparaFechasDeRegistroYVenta(){var data=dashboard.data(admin,"2026-10",null,null);assertEquals(1,totals(data).get("separaciones"));assertEquals(1,totals(data).get("ventas"));assertEquals(2,totals(data).get("clientes"));assertEquals(1L,totals(data).get("cotitulares"));assertFalse(totals(data).containsKey("ingresos"));}
  @Test void rankingSoloIncluyeVentasYAsociaLotesAlCotitular(){var data=dashboard.data(admin,"2026-10",null,null);var ranking=(List<Map<String,Object>>)data.get("ranking");assertEquals(1,ranking.size());assertEquals(1,ranking.getFirst().get("ventas"));var clients=(List<Map<String,Object>>)data.get("clientes");assertTrue(clients.stream().allMatch(c->((List<?>)c.get("lotes")).size()==2));}
  @Test void reporteSiempreDisponibleYFiltrado(){assertEquals(0,totals(dashboard.data(admin,"1900-01",null,null)).get("ventas"));assertEquals(0,totals(dashboard.data(admin,"2026-10",2L,null)).get("ventas"));assertThrows(BusinessRules.Forbidden.class,()->dashboard.data(advisor,"2026-10",null,null));assertDoesNotThrow(()->dashboard.data(manager,"2026-10",null,null));assertThrows(IllegalArgumentException.class,()->dashboard.data(admin,"2026-13",null,null));}
  @Test void formatosMantienenConteosYDetalles()throws Exception{
    var data=dashboard.data(admin,"2026-10",null,null);var sections=reports.sections(data,"general");
    byte[] xlsx=reports.export("xlsx","Octubre 2026","Mes: 2026-10",sections);try(var book=new XSSFWorkbook(new ByteArrayInputStream(xlsx))){assertEquals(7,book.getNumberOfSheets());assertEquals("Cotitular mensual",book.getSheet("Clientes nuevos").getRow(4).getCell(0).getStringCellValue());assertNotNull(book.getSheet("Ventas").getCTWorksheet().getAutoFilter());}
    String text=new String(reports.export("txt","Octubre 2026","Mes: 2026-10",sections),java.nio.charset.StandardCharsets.UTF_8);assertTrue(text.contains("Cotitular mensual"));assertTrue(text.contains("Número de ventas: 1"));assertFalse(text.contains("Ingreso"));
    byte[] pdf=reports.export("pdf","Octubre 2026","Mes: 2026-10",sections);assertTrue(new String(pdf,java.nio.charset.StandardCharsets.ISO_8859_1).startsWith("%PDF-1.4"));assertTrue(pdf.length>2000);assertEquals(1,reports.sections(data,"ventas").size());assertThrows(IllegalArgumentException.class,()->reports.sections(data,"inventado"));
  }
  @Test void plazosPorMontoYManual(){assertEquals(3,ReservationDeadlines.days(new BigDecimal("100.00"),null));assertEquals(5,ReservationDeadlines.days(new BigDecimal("200"),null));assertEquals(14,ReservationDeadlines.days(new BigDecimal("500"),null));assertEquals(30,ReservationDeadlines.days(new BigDecimal("800"),30));assertThrows(IllegalArgumentException.class,()->ReservationDeadlines.days(new BigDecimal("800"),null));assertThrows(IllegalArgumentException.class,()->ReservationDeadlines.days(new BigDecimal("500"),15));}
  @Test void vencimientoNoLiberaYNoDuplicaAvisos(){deadlines.initialize(1,new BigDecimal("100"),null);deadlines.scan();deadlines.scan();assertEquals(1,d.scalar("select count(*) from notificacion where tipo='VENCIMIENTO'",Integer.class));assertEquals("ACTIVA",d.row("select estado from separacion where id=1").get("estado"));assertEquals(1L,operations.notifications(advisor).get("pendientes"));assertEquals(1L,operations.notifications(manager).get("pendientes"));var outsider=new Actor(999,"Otro asesor","ASESOR");assertEquals(0L,operations.notifications(outsider).get("pendientes"));}
  @Test void ampliarPlazoOcultaAlertaAntiguaYAudita(){deadlines.initialize(1,new BigDecimal("100"),null);deadlines.scan();assertThrows(BusinessRules.Forbidden.class,()->deadlines.change(1,3650,0,advisor));assertThrows(BusinessRules.Conflict.class,()->deadlines.change(1,3650,99,admin));deadlines.change(1,3650,0,manager);assertEquals(0L,operations.notifications(advisor).get("pendientes"));assertEquals(1,queries.history(admin,"OPERACION","",null,"PLAZO").size());assertEquals(3650,d.row("select plazo_dias from separacion where id=1").get("plazo_dias"));}
  @Test void historialFiltraAccionesYNoConfundeReasignaciones(){d.audit(admin,"OPERACION",1,"LIBERACION","Liberación",null,Map.of("estado","ANULADA"));d.audit(admin,"OPERACION",2,"REASIGNAR","Reasignación",null,Map.of("lote",5));assertEquals(1,queries.history(admin,"OPERACION",null,null,"LIBERACION").size());assertEquals(1,queries.history(admin,"OPERACION",null,null,"REASIGNAR").size());}
  @Test void sesionRecordadaYRevocacion(){var standard=auth.login(new Login("admin@casavip.pe","CasaVIP-demo-2026!",false));var remembered=auth.login(new Login("admin@casavip.pe","CasaVIP-demo-2026!",true));assertTrue(Duration.between(Instant.parse((String)standard.get("expires")),Instant.parse((String)remembered.get("expires"))).toDays()>=29);String token=(String)remembered.get("token");assertNotNull(auth.resolve(token));auth.logout(token);assertNull(auth.resolve(token));}
}
