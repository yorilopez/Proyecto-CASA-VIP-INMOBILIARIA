package pe.casavip;

import java.math.BigDecimal;
import java.util.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import pe.casavip.ApiModels.*;

/** Casos de uso. Cada transicion agrupa datos e historial en una transaccion. */
@Service
public class CommercialService {
  private final CommercialDao dao;
  private static final Logger log = LoggerFactory.getLogger(CommercialService.class);

  public CommercialService(CommercialDao dao) {
    this.dao = dao;
  }

  public static long id(Map<String, Object> r, String key) {
    return ((Number) r.get(key)).longValue();
  }

  public Map<String, Object> client(long id, Actor a) {
    var c = dao.client(id);
    if (!a.manager() && id(c, "asesor_id") != a.id())
      throw new BusinessRules.Forbidden("El cliente pertenece a otro asesor.");
    return c;
  }

  @Transactional
  public Map<String, Object> addClient(Client input, Actor a) {
    String type = BusinessRules.text(input.tipo_documento(), 20),
        number = BusinessRules.document(input.numero_documento());
    if (type.equals("DNI") && !number.matches("[0-9]{8}"))
      throw new IllegalArgumentException("El DNI debe contener 8 digitos.");
    var prior = dao.clientByDocument(type, number);
    if (prior != null) return client(id(prior, "id"), a);
    var c =
        new Client(
            BusinessRules.text(input.nombre(), 160),
            type,
            number,
            input.telefono(),
            input.correo(),
            input.proyecto_id());
    long id = dao.clientAdd(c, a);
    log.info("cliente_creado id={} actor={}", id, a.id());
    return dao.client(id);
  }

  @Transactional
  public Map<String, Object> reserve(Reservation in, Actor a) {
    var lot = dao.lot(in.lote_id(), true);
    BusinessRules.requireAvailable((String) lot.get("estado"));
    client(in.cliente_id(), a);
    BusinessRules.amount(in.monto(), (BigDecimal) lot.get("precio"));
    long id = dao.reserve(in.lote_id(), in.cliente_id(), a.id(), in.monto(), in.observacion());
    dao.lotState(in.lote_id(), "RESERVADO");
    dao.history(in.lote_id(), a.id(), id, "DISPONIBLE", "RESERVADO", "Separacion registrada");
    log.info("separacion_creada id={} lote={} actor={}", id, in.lote_id(), a.id());
    return dao.reservation(id, false);
  }

  private Map<String, Object> active(long id) {
    var r = dao.reservation(id, true);
    if (!"ACTIVA".equals(r.get("estado")))
      throw new BusinessRules.Conflict("La separacion ya no esta activa.");
    return r;
  }

  @Transactional
  public void release(long id, String reason, Actor a) {
    BusinessRules.requireManager(a.role());
    var r = active(id);
    long lot = id(r, "lote_id");
    var row = dao.lot(lot, true);
    if (!"RESERVADO".equals(row.get("estado")))
      throw new BusinessRules.Conflict("El estado del lote no coincide con la reserva.");
    dao.reservationState(id, "ANULADA");
    dao.lotState(lot, "DISPONIBLE");
    dao.history(lot, a.id(), id, "RESERVADO", "DISPONIBLE", BusinessRules.text(reason, 180));
    log.info("reserva_liberada id={} actor={}", id, a.id());
  }

  @Transactional
  public void reassign(long id, Reassign input, Actor a) {
    BusinessRules.requireManager(a.role());
    var r = active(id);
    long previous = id(r, "lote_id");
    if (previous == input.lote_id())
      throw new IllegalArgumentException("Selecciona un lote diferente.");
    dao.lockLots(previous, input.lote_id());
    var old = dao.lot(previous, false);
    var next = dao.lot(input.lote_id(), false);
    if (!"RESERVADO".equals(old.get("estado")))
      throw new BusinessRules.Conflict("El lote anterior no esta reservado.");
    if (id(old, "proyecto_id") != id(next, "proyecto_id"))
      throw new IllegalArgumentException("La reasignacion debe permanecer en el mismo proyecto.");
    BusinessRules.requireAvailable((String) next.get("estado"));
    BusinessRules.amount((BigDecimal) r.get("monto"), (BigDecimal) next.get("precio"));
    String reason = BusinessRules.text(input.motivo(), 180);
    dao.reservationMove(id, input.lote_id());
    dao.lotState(previous, "DISPONIBLE");
    dao.lotState(input.lote_id(), "RESERVADO");
    dao.history(previous, a.id(), id, "RESERVADO", "DISPONIBLE", reason);
    dao.history(input.lote_id(), a.id(), id, "DISPONIBLE", "RESERVADO", reason);
    log.info("reserva_reasignada id={} actor={}", id, a.id());
  }

  @Transactional
  public void sell(long id, Sale in, Actor a) {
    BusinessRules.requireManager(a.role());
    var r = active(id);
    long lotId = id(r, "lote_id");
    var lot = dao.lot(lotId, true);
    if (!"RESERVADO".equals(lot.get("estado")))
      throw new BusinessRules.Conflict("La venta requiere un lote reservado.");
    if (!in.contrato_firmado()
        || in.fecha() == null
        || in.fecha().isAfter(java.time.LocalDate.now()))
      throw new IllegalArgumentException("Se requiere contrato firmado y fecha valida.");
    BusinessRules.amount(in.inicial(), in.precio());
    if (((java.util.List<?>) lot.get("planes"))
        .stream().noneMatch(p -> id((Map<String, Object>) p, "id") == in.plan_id()))
      throw new IllegalArgumentException("Selecciona un plan vigente del lote.");
    dao.sale(id, a.id(), in);
    dao.reservationState(id, "CONFIRMADA");
    dao.lotState(lotId, "VENDIDO");
    dao.history(lotId, a.id(), id, "RESERVADO", "VENDIDO", "Venta confirmada con contrato firmado");
  }

  @Transactional
  public void state(long id, ChangeState in, Actor a) {
    BusinessRules.requireAdmin(a.role());
    if (!Set.of("DISPONIBLE", "NO_DISPONIBLE").contains(in.estado()))
      throw new IllegalArgumentException(
          "Solo se permite deshabilitar o reactivar. Las ventas y reservas usan sus propios"
              + " flujos.");
    var l = dao.lot(id, true);
    String old = (String) l.get("estado");
    if (!Set.of("DISPONIBLE", "NO_DISPONIBLE").contains(old) || old.equals(in.estado()))
      throw new BusinessRules.Conflict("La transicion no esta permitida.");
    dao.lotState(id, in.estado());
    dao.history(id, a.id(), null, old, in.estado(), BusinessRules.text(in.motivo(), 180));
  }
}
