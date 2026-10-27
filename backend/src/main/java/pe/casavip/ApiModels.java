package pe.casavip;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.LocalDate;

/** Objetos de entrada y principal autenticado. No contienen entidades JDBC. */
public final class ApiModels {
  private ApiModels() {}

  public record Actor(long id, String name, String role) {
    public boolean manager() {
      return !"ASESOR".equals(role);
    }
  }

  public record Login(
      @NotBlank @Email @Size(max = 120) String email, @NotBlank @Size(max = 100) String password) {}

  public record Client(
      @NotBlank @Size(max = 160) String nombre,
      @NotBlank @Pattern(regexp = "DNI|CE") String tipo_documento,
      @NotBlank String numero_documento,
      @Pattern(regexp = "[0-9+ ()-]{6,25}") String telefono,
      @Email @Size(max = 120) String correo,
      @Positive long proyecto_id) {}

  public record Reservation(
      @Positive long lote_id,
      @Positive long cliente_id,
      @NotNull @DecimalMin("0.01") BigDecimal monto,
      @Size(max = 500) String observacion) {}

  public record Reassign(@Positive long lote_id, @NotBlank @Size(max = 180) String motivo) {}

  public record ChangeState(@NotBlank String estado, @NotBlank @Size(max = 180) String motivo) {}

  public record Sale(
      @Positive long plan_id,
      @NotNull @DecimalMin("0.01") BigDecimal precio,
      @NotNull @DecimalMin("0.01") BigDecimal inicial,
      @AssertTrue boolean contrato_firmado,
      @NotNull @PastOrPresent LocalDate fecha) {}
}
