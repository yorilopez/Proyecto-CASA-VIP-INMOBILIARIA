package pe.casavip;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.LocalDate;

/** Entradas explícitas; nunca se aceptan roles, estados ni rutas arbitrarios. */
public final class OperationModels {
 private OperationModels(){}
 public record Correction(@NotNull @PositiveOrZero Long version,
   @NotNull BigDecimal precio,@NotNull BigDecimal inicial,@Min(1) @Max(600) int numero_cuotas,
   @NotNull BigDecimal monto,@Size(max=500) String observacion,
   @NotBlank @Size(max=500) String motivo,Long cliente_id,Long cotitular_id,boolean quitar_cotitular,Long asesor_id,
   @PastOrPresent LocalDate fecha,boolean actualizar_personas){}
 public record UserInput(@NotBlank @Size(max=160) String nombre,@NotBlank @Email @Size(max=254) String correo,
   @NotBlank @Pattern(regexp="ASESOR|RESPONSABLE_COMERCIAL|ADMINISTRADOR") String rol,
   @Size(max=30) String telefono,@Size(max=128) String password,boolean activo){}
 public record ActiveUser(boolean activo){}
 public record ReadNotifications(@PositiveOrZero long hasta){}
}
