package pe.casavip;

import static org.junit.jupiter.api.Assertions.*;

import java.time.*;
import java.util.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;
import pe.casavip.ApiModels.Actor;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class MonthlyQueriesTest {
  @Autowired CommercialQueries q;
  @Autowired JdbcTemplate jdbc;
  @Autowired OperationsDao d;
  Actor admin = new Actor(3, "Admin", "ADMINISTRADOR"), advisor = new Actor(1, "Asesor", "ASESOR");

  @BeforeEach
  void fixture() {
    for (String table :
        List.of(
            "notificacion_lectura",
            "notificacion",
            "auditoria_comercial",
            "operacion_documento",
            "cliente_documento",
            "historial_lote",
            "venta",
            "separacion",
            "cliente_relacion",
            "cliente")) jdbc.update("delete from " + table);
    jdbc.update(
        "insert into cliente(id,tipo_documento,numero_documento,nombre,proyecto_id,asesor_id)"
            + " values(1,'DNI','88050001','Cliente mensual uno',1,1),(2,'DNI','88050002','Cliente"
            + " mensual dos',1,1)");
    jdbc.update("update lote set estado='RESERVADO' where id=4");
    jdbc.update("update lote set estado='VENDIDO' where id=5");
    jdbc.update(
        "insert into separacion(id,lote_id,cliente_id,asesor_id,monto,estado)"
            + " values(1,4,1,1,500,'ACTIVA'),(2,5,2,1,500,'CONFIRMADA')");
    jdbc.update(
        "insert into"
            + " venta(separacion_id,responsable_id,precio_final,inicial,contrato_firmado,fecha_venta)"
            + " values(2,2,21000,3000,true,CURRENT_DATE)");
  }

  @Test
  void limitaElMesEnZonaLima() {
    jdbc.update(
        "update cliente set fecha_registro=? where id=1",
        OffsetDateTime.parse("2026-11-01T04:59:59Z"));
    jdbc.update(
        "update cliente set fecha_registro=? where id=2",
        OffsetDateTime.parse("2026-11-01T05:00:00Z"));
    assertEquals(
        List.of(1L),
        q.clients(admin, null, "2026-10", null).stream()
            .map(r -> ((Number) r.get("id")).longValue())
            .toList());
    assertEquals(
        List.of(2L),
        q.clients(admin, null, "2026-11", null).stream()
            .map(r -> ((Number) r.get("id")).longValue())
            .toList());
  }

  @Test
  void ventaUsaSuFechaAunqueLaSeparacionSeaAnterior() {
    jdbc.update(
        "update separacion set fecha_registro=? where id=2",
        OffsetDateTime.parse("2025-12-15T15:00:00Z"));
    jdbc.update("update venta set fecha_venta=? where separacion_id=2", LocalDate.of(2026, 1, 10));
    assertEquals(1, q.operations(admin, "2026-01", "CONFIRMADA").size());
    assertTrue(q.operations(admin, "2025-12", "CONFIRMADA").isEmpty());
  }

  @Test
  void liberacionUsaLaFechaDeLiberacion() {
    jdbc.update(
        "update separacion set estado='ANULADA',fecha_registro=? where id=1",
        OffsetDateTime.parse("2025-12-15T15:00:00Z"));
    jdbc.update(
        "insert into"
            + " historial_lote(lote_id,usuario_id,separacion_id,estado_anterior,estado_nuevo,motivo,fecha_cambio)"
            + " values(4,3,1,'RESERVADO','DISPONIBLE','Liberación de prueba',?)",
        OffsetDateTime.parse("2026-01-20T18:00:00Z"));
    assertEquals(1, q.operations(admin, "2026-01", "LIBERADA").size());
    assertTrue(q.operations(admin, "2025-12", "LIBERADA").isEmpty());
  }

  @Test
  void mesActualNoOcultaConsultaSinPeriodo() {
    assertEquals(2, q.operations(admin, null, null).size());
    assertEquals(2, q.clients(admin, null, "", null).size());
  }

  @Test
  void potencialExcluyeActivasYVentasEIncluyeLiberadas() {
    assertTrue(q.clients(admin, null, null, "POTENCIAL").isEmpty());
    jdbc.update("update separacion set estado='ANULADA' where id=1");
    assertEquals(1, q.clients(admin, null, null, "POTENCIAL").size());
    assertEquals(1, q.clients(admin, null, null, "VENTA").size());
  }

  @Test
  void cotitularTambienClasificaPorSuOperacion() {
    jdbc.update("update separacion set cotitular_id=2 where id=1");
    assertEquals(2, q.clients(admin, null, null, "SEPARACION").size());
  }

  @Test
  void asesorSoloConsultaSusRegistrosConFiltros() {
    jdbc.update("update cliente set asesor_id=2 where id=2");
    jdbc.update("update separacion set asesor_id=2 where id=2");
    assertTrue(q.operations(advisor, null, "CONFIRMADA").isEmpty());
    assertTrue(q.clients(advisor, null, null, "VENTA").isEmpty());
    assertEquals(1, q.clients(advisor, null, null, null).size());
  }

  @Test
  void historialCombinaUsuarioTipoYMes() {
    insertHistory(1, "CLIENTE", "2025-12-10T15:00:00Z");
    insertHistory(3, "CLIENTE", "2025-12-10T15:00:00Z");
    insertHistory(1, "USUARIO", "2025-12-10T15:00:00Z");
    assertEquals(1, q.history(admin, "CLIENTE", "2025-12", 1L).size());
    assertEquals(3, q.history(admin, null, "2025-12", null).size());
    assertThrows(BusinessRules.Forbidden.class, () -> q.history(advisor, null, null, null));
  }

  @Test
  void historialDeUsuarioRetiradoSigueConsultable() {
    insertHistory(2, "CLIENTE", "2025-12-10T15:00:00Z");
    jdbc.update("update usuario set eliminado=true,activo=false where id=2");
    assertTrue(
        q.historyUsers(admin).stream().anyMatch(u -> ((Number) u.get("id")).longValue() == 2));
    assertEquals(1, q.history(admin, null, "2025-12", 2L).size());
  }

  @Test
  void filtraMesHistoricoAntesDeCualquierLimite() {
    for (int i = 0; i < 501; i++) insertHistory(3, "CLIENTE", "2026-10-10T15:00:00Z");
    insertHistory(1, "CLIENTE", "2025-01-10T15:00:00Z");
    assertEquals(1, q.history(admin, null, "2025-01", null).size());
  }

  @Test
  void rechazaFiltrosInvalidos() {
    for (String month : List.of("2026-13", "2026-2", "algo", "0000-01"))
      assertThrows(IllegalArgumentException.class, () -> q.operations(admin, month, null));
    assertThrows(IllegalArgumentException.class, () -> q.clients(admin, null, null, "OTRO"));
    assertThrows(IllegalArgumentException.class, () -> q.operations(admin, null, "BORRAR"));
  }

  @Test
  void listasNoDevuelvenInstantaneasCompletas() {
    assertFalse(q.operations(admin, null, null).getFirst().containsKey("datos_acordados"));
    assertTrue(q.clients(admin, null, null, null).getFirst().containsKey("fecha_registro"));
  }

  @Test
  void datosAmpliadosSonIdempotentesYCoherentes() {
    var seed = new ExpandedDemoData(jdbc, d, "CasaVIP-demo-2026!");
    seed.run();
    long clients = jdbc.queryForObject("select count(*) from cliente", Long.class),
        operations = jdbc.queryForObject("select count(*) from separacion", Long.class);
    seed.run();
    assertEquals(38, clients);
    assertEquals(20, operations);
    assertEquals(clients, jdbc.queryForObject("select count(*) from cliente", Long.class));
    assertEquals(operations, jdbc.queryForObject("select count(*) from separacion", Long.class));
    assertEquals(
        6,
        jdbc.queryForObject(
            "select count(distinct fecha_venta) from venta where separacion_id>2", Integer.class));
  }

  void insertHistory(long user, String entity, String date) {
    jdbc.update(
        "insert into auditoria_comercial(usuario_id,entidad,registro_id,accion,motivo,actual,fecha)"
            + " values(?,?,1,'CREAR','Prueba de período','{}',?)",
        user,
        entity,
        OffsetDateTime.parse(date));
  }
}
