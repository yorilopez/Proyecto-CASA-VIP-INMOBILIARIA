package pe.casavip;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.LocalDate;

/** Objetos de entrada y principal autenticado. No contienen entidades JDBC. */
public final class ApiModels {
  private ApiModels() {}

  public record Actor(long id, String name, String role, String phone) {
    public Actor(long id, String name, String role) {
      this(id, name, role, null);
    }

    public boolean manager() {
      return !"ASESOR".equals(role);
    }
  }

  public record Login(
      @NotBlank @Email @Size(max = 254) String email, @NotBlank @Size(max = 128) String password, boolean remember) {
    public Login(String email,String password){this(email,password,false);}
  }

  public record Client(
      @NotBlank @Size(max = 160) String nombre,
      @NotBlank @Pattern(regexp = "DNI|CE") String tipo_documento,
      @NotBlank String numero_documento,
      @Pattern(regexp = "[0-9+ ()-]{6,25}") String telefono,
      @Email @Size(max = 120) String correo,
      @Positive long proyecto_id,
      @Size(max = 250) String direccion,
      @Size(max = 120) String ocupacion,
      @Valid CoClient cotitular) {
    public Client(
        String nombre,
        String tipo_documento,
        String numero_documento,
        String telefono,
        String correo,
        long proyecto_id) {
      this(
          nombre,
          tipo_documento,
          numero_documento,
          telefono,
          correo,
          proyecto_id,
          null,
          null,
          null);
    }
  }

  public record CoClient(
      @NotBlank @Size(max = 160) String nombre,
      @NotBlank @Pattern(regexp = "DNI|CE") String tipo_documento,
      @NotBlank String numero_documento,
      @Pattern(regexp = "[0-9+ ()-]{6,25}") String telefono,
      @Email @Size(max = 120) String correo,
      @Size(max = 250) String direccion,
      @Size(max = 120) String ocupacion) {}

  public record Reservation(
      @Positive long lote_id,
      @Positive long cliente_id,
      @NotNull @DecimalMin("0.01") BigDecimal monto,
      @Size(max = 500) String observacion,
      @Positive Long plan_id,
      @Positive Long cotitular_id,
      @DecimalMin("0.01") BigDecimal precio_acordado,
      @DecimalMin("0.01") BigDecimal inicial_acordada,
      @Min(1) @Max(600) Integer numero_cuotas_acordado,
      @PositiveOrZero Long version_catalogo,
      @Min(1) @Max(3650) Integer plazo_dias) {
    public Reservation(long lote_id,long cliente_id,BigDecimal monto,String observacion,Long plan_id,Long cotitular_id,BigDecimal precio_acordado,BigDecimal inicial_acordada,Integer numero_cuotas_acordado,Long version_catalogo){
      this(lote_id,cliente_id,monto,observacion,plan_id,cotitular_id,precio_acordado,inicial_acordada,numero_cuotas_acordado,version_catalogo,null);
    }
    public Reservation(long lote_id,long cliente_id,BigDecimal monto,String observacion,Long plan_id,Long cotitular_id) {
      this(lote_id,cliente_id,monto,observacion,plan_id,cotitular_id,null,null,null,null);
    }
    public Reservation(long lote_id, long cliente_id, BigDecimal monto, String observacion) {
      this(lote_id, cliente_id, monto, observacion, null, null);
    }
  }

  public record Reassign(@Positive long lote_id, @NotBlank @Size(max = 180) String motivo) {}

  public record ChangeState(@NotBlank String estado, @NotBlank @Size(max = 180) String motivo) {}

  public record Sale(
      @Positive long plan_id,
      @NotNull @DecimalMin("0.01") BigDecimal precio,
      @NotNull @DecimalMin("0.01") BigDecimal inicial,
      @AssertTrue boolean contrato_firmado,
      @NotNull @PastOrPresent LocalDate fecha,
      @Min(1) @Max(600) Integer numero_cuotas) {
    public Sale(long plan_id,BigDecimal precio,BigDecimal inicial,boolean contrato_firmado,LocalDate fecha) {
      this(plan_id,precio,inicial,contrato_firmado,fecha,null);
    }
  }
}
