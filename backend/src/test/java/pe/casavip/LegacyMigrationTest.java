package pe.casavip;
import static org.junit.jupiter.api.Assertions.*;
import java.math.BigDecimal;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import com.fasterxml.jackson.databind.ObjectMapper;

/** Migración real de una base con el esquema anterior, independiente de la base de pruebas de API. */
class LegacyMigrationTest {
 @Test void conservaClientesSeparacionesVentaYCondicionesAlMigrarDosVeces(){
   var source=new DriverManagerDataSource("jdbc:h2:mem:legacy_"+java.util.UUID.randomUUID()+";MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1","sa","");
   new ResourceDatabasePopulator(new ClassPathResource("schema-0.3.1.sql")).execute(source);var j=new JdbcTemplate(source);
   j.update("insert into rol(id,nombre) values(1,'ASESOR')");j.update("insert into usuario(id,rol_id,correo,nombre,password_hash) values(1,1,'historico@example.invalid','Asesor histórico','hash-ficticio')");
   j.update("insert into proyecto(id,codigo,nombre) values(1,'ANT','Proyecto anterior')");j.update("insert into etapa(id,proyecto_id,nombre,orden) values(1,1,'Etapa anterior',1)");j.update("insert into manzana(id,etapa_id,codigo) values(1,1,'A')");
   j.update("insert into lote(id,manzana_id,codigo,area_m2,precio,estado) values(1,1,'01',120,21000,'RESERVADO'),(2,1,'02',120,23000,'VENDIDO')");
   j.update("insert into plan_pago(id,proyecto_id,nombre,inicial,numero_cuotas,monto_cuota) values(1,1,'Plan anterior',3000,24,750)");j.update("insert into lote_plan_pago(lote_id,plan_pago_id) values(1,1),(2,1)");
   j.update("insert into cliente(id,tipo_documento,numero_documento,nombre,direccion,ocupacion,proyecto_id,asesor_id) values(1,'DNI','00112233','Cliente anterior','Dirección anterior','Comerciante',1,1)");
   j.update("insert into separacion(id,lote_id,cliente_id,asesor_id,monto,estado,plan_pago_id,precio_acordado,inicial_acordada,numero_cuotas_acordado,cuota_acordada) values(1,1,1,1,500,'ACTIVA',1,21000,3000,24,750),(2,2,1,1,500,'CONFIRMADA',1,23000,3000,24,833.33)");
   j.update("insert into venta(separacion_id,responsable_id,precio_final,inicial,contrato_firmado,fecha_venta,plan_pago_id) values(2,1,20000,4000,true,CURRENT_DATE,1)");
   new ResourceDatabasePopulator(new ClassPathResource("schema-demo.sql")).execute(source);
   var mapper=new ObjectMapper().findAndRegisterModules();var d=new OperationsDao(j,mapper);var migration=new OperationMigration(d,new JdbcCommercialDao(j));migration.migrate();migration.migrate();
   assertEquals(1,j.queryForObject("select count(*) from cliente",Integer.class));assertEquals(2,j.queryForObject("select count(*) from separacion",Integer.class));assertEquals(1,j.queryForObject("select count(*) from venta",Integer.class));
   assertEquals(new BigDecimal("21000.00"),j.queryForObject("select precio_acordado from separacion where id=1",BigDecimal.class));assertEquals("Dirección anterior",j.queryForObject("select direccion from cliente where id=1",String.class));
   String sale=j.queryForObject("select datos_finales from venta",String.class);assertTrue(sale.contains("20000.00"));assertTrue(sale.contains("4000.00"));assertEquals(0,j.queryForObject("select count(*) from notificacion",Integer.class));
   j.execute("DROP ALL OBJECTS");
 }
}
