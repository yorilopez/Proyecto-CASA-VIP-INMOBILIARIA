package pe.casavip;

import java.util.*;
import org.slf4j.*;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.*;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.server.ResponseStatusException;

/** Traduce errores de negocio a respuestas sin trazas ni datos sensibles. */
@RestControllerAdvice
public class ApiErrors {
  private static final Logger log = LoggerFactory.getLogger(ApiErrors.class);

  @ExceptionHandler(BusinessRules.Conflict.class)
  ResponseEntity<?> conflict(RuntimeException e) {
    return response(409, e.getMessage());
  }

  @ExceptionHandler(BusinessRules.Forbidden.class)
  ResponseEntity<?> denied(RuntimeException e) {
    return response(403, e.getMessage());
  }

  @ExceptionHandler(BusinessRules.Missing.class)
  ResponseEntity<?> missing() {
    return response(404, "Registro no encontrado.");
  }

  @ExceptionHandler(IllegalArgumentException.class)
  ResponseEntity<?> invalid(RuntimeException e) {
    return response(400, e.getMessage());
  }

  @ExceptionHandler(MethodArgumentNotValidException.class)
  ResponseEntity<?> validation(MethodArgumentNotValidException e) {
    return response(400, "Revisa los campos obligatorios y sus formatos.");
  }
  @ExceptionHandler(org.springframework.http.converter.HttpMessageNotReadableException.class)
  ResponseEntity<?> unreadable() {return response(400,"Revisa los tipos y el formato de los datos enviados.");}

  @ExceptionHandler(ResponseStatusException.class)
  ResponseEntity<?> status(ResponseStatusException e) {
    return response(e.getStatusCode().value(), e.getReason());
  }

  @ExceptionHandler(DataIntegrityViolationException.class)
  ResponseEntity<?> integrity() {
    return response(409, "La operacion entra en conflicto con un registro existente.");
  }

  @ExceptionHandler(MaxUploadSizeExceededException.class)
  ResponseEntity<?> size() {
    return response(413, "La fotografia supera el limite de 5 MB.");
  }

  @ExceptionHandler(Exception.class)
  ResponseEntity<?> unexpected(Exception e) {
    String id = UUID.randomUUID().toString();
    log.error("error_no_controlado id={} tipo={}", id, e.getClass().getSimpleName());
    return response(500, "No fue posible completar la operacion. Referencia: " + id);
  }

  private ResponseEntity<?> response(int code, String message) {
    return ResponseEntity.status(code).body(Map.of("message", message));
  }
}
