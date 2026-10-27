package pe.casavip;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import static org.junit.jupiter.api.Assertions.*;
/** Casos escritos antes de implementar las reglas de negocio. */
class BusinessRulesTest {
 @Test void reservaExigeLoteDisponible(){
  assertDoesNotThrow(()->BusinessRules.requireAvailable("DISPONIBLE"));
  for(String state:new String[]{"RESERVADO","VENDIDO","NO_DISPONIBLE"})
   assertThrows(BusinessRules.Conflict.class,()->BusinessRules.requireAvailable(state));
 }
 @Test void montoPositivoDentroDelPrecio(){
  assertThrows(IllegalArgumentException.class,()->BusinessRules.amount(BigDecimal.ZERO,new BigDecimal("21000")));
  assertThrows(IllegalArgumentException.class,()->BusinessRules.amount(new BigDecimal("21001"),new BigDecimal("21000")));
  assertDoesNotThrow(()->BusinessRules.amount(new BigDecimal("500"),new BigDecimal("21000")));
 }
 @Test void asesorNoLiberaReservas(){
  assertThrows(BusinessRules.Forbidden.class,()->BusinessRules.requireManager("ASESOR"));
  assertDoesNotThrow(()->BusinessRules.requireManager("RESPONSABLE_COMERCIAL"));
  assertDoesNotThrow(()->BusinessRules.requireManager("ADMINISTRADOR"));
 }
 @Test void normalizaTextoYConservaCeros(){
  assertEquals("Ana Maria",BusinessRules.text("  Ana   Maria  ",160));
  assertEquals("00123456",BusinessRules.document("00123456"));
  assertThrows(IllegalArgumentException.class,()->BusinessRules.document("123"));
 }
}
