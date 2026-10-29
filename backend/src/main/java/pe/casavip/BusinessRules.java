package pe.casavip;

import com.google.common.base.Preconditions;
import java.math.BigDecimal;
import java.util.Set;
import org.apache.commons.lang3.StringUtils;

/** Reglas puras compartidas por los servicios comerciales. */
public final class BusinessRules {
  private BusinessRules() {}

  public static final Set<String> STATES =
      Set.of("DISPONIBLE", "RESERVADO", "VENDIDO", "NO_DISPONIBLE");

  public static void requireAvailable(String state) {
    if (!"DISPONIBLE".equals(state))
      throw new Conflict("El lote ya no esta disponible. Actualiza la consulta.");
  }

  public static void amount(BigDecimal amount, BigDecimal price) {
    Preconditions.checkArgument(
        amount != null && amount.signum() > 0 && amount.compareTo(price) <= 0,
        "El monto debe ser mayor que cero y no superar el precio del lote.");
  }

  public static void requireManager(String role) {
    if (!Set.of("ADMINISTRADOR", "RESPONSABLE_COMERCIAL").contains(role))
      throw new Forbidden("Esta operacion requiere un responsable comercial o administrador.");
  }

  public static void requireAdmin(String role) {
    if (!"ADMINISTRADOR".equals(role))
      throw new Forbidden("Esta operacion requiere un administrador.");
  }

  public static String text(String value, int max) {
    String s = StringUtils.normalizeSpace(value);
    Preconditions.checkArgument(
        StringUtils.isNotBlank(s) && s.length() <= max, "Texto obligatorio o longitud no valida.");
    return s;
  }

  public static String document(String value) {
    String s = text(value, 30);
    Preconditions.checkArgument(
        s.matches("[0-9]{8}|[A-Za-z0-9]{9,15}"),
        "Documento no valido. DNI: 8 digitos. CE: 9 a 15 caracteres.");
    return s;
  }

  public static class Conflict extends RuntimeException {
    public Conflict(String s) {
      super(s);
    }
  }

  public static class Forbidden extends RuntimeException {
    public Forbidden(String s) {
      super(s);
    }
  }

  public static class Missing extends RuntimeException {
    public Missing() {
      super("Registro no encontrado.");
    }
  }
}
