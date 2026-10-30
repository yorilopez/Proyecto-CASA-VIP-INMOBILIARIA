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
  private final PrototypeDao prototype;
  private final OperationsDao ledger;
  private final ReservationDeadlines deadlines;
  private static final Logger log = LoggerFactory.getLogger(CommercialService.class);

  public CommercialService(CommercialDao dao, PrototypeDao prototype, OperationsDao ledger, ReservationDeadlines deadlines) {
    this.dao = dao;
    this.prototype = prototype;
    this.ledger = ledger;
    this.deadlines = deadlines;
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
  public Map<String, Object> addClient(Client input, Actor actor) {
    var saved=attachCo(savePerson(input, actor), input, actor);
    ledger.audit(actor,"CLIENTE",id(saved,"id"),"REGISTRAR","Registro o selección de cliente",null,saved);
    return saved;
  }

  @Transactional
  public Map<String, Object> updateClient(long id, Client input, Actor actor) {
    var prior = client(id, actor);
    if (id(prior, "proyecto_id") != input.proyecto_id())
      throw new IllegalArgumentException("Conserva el proyecto del cliente.");
    String number = BusinessRules.document(input.numero_documento());
    if ("DNI".equals(input.tipo_documento()) && !number.matches("[0-9]{8}"))
      throw new IllegalArgumentException("El DNI debe contener 8 digitos.");
    var clean =
        new Client(
            BusinessRules.text(input.nombre(), 160),
            input.tipo_documento(),
            number,
            input.telefono(),
            input.correo(),
            input.proyecto_id(),
            optional(input.direccion()),
            optional(input.ocupacion()),
            input.cotitular());
    prototype.person(id, clean);
    var saved=attachCo(dao.client(id),clean,actor);
    ledger.audit(actor,"CLIENTE",id,"MODIFICAR","Datos de cliente actualizados",prior,saved);
    return saved;
  }

  private Map<String, Object> attachCo(Map<String, Object> primary, Client input, Actor actor) {
    if (input.cotitular() != null) {
      var co = input.cotitular();
      var secondary =
          savePerson(
              new Client(
                  co.nombre(),
                  co.tipo_documento(),
                  co.numero_documento(),
                  co.telefono(),
                  co.correo(),
                  input.proyecto_id(),
                  co.direccion(),
                  co.ocupacion(),
                  null),
              actor);
      long titular = id(primary, "id"), cotitular = id(secondary, "id");
      if (titular == cotitular)
        throw new IllegalArgumentException("El cotitular debe ser una persona diferente.");
      if (id(secondary, "proyecto_id") != input.proyecto_id())
        throw new IllegalArgumentException("El cotitular debe pertenecer al mismo proyecto.");
      prototype.person(cotitular,new Client(BusinessRules.text(co.nombre(),160),co.tipo_documento(),BusinessRules.document(co.numero_documento()),co.telefono(),co.correo(),input.proyecto_id(),optional(co.direccion()),optional(co.ocupacion()),null));
      prototype.link(titular, cotitular);
      primary.put("cotitular", secondary);
    }
    if(input.cotitular()==null){var existing=prototype.coClient(id(primary,"id"));if(existing!=null)primary.put("cotitular",existing);}
    return primary;
  }

  private Map<String, Object> savePerson(Client input, Actor actor) {
    String type = BusinessRules.text(input.tipo_documento(), 20),
        number = BusinessRules.document(input.numero_documento());
    if (type.equals("DNI") && !number.matches("[0-9]{8}"))
      throw new IllegalArgumentException("El DNI debe contener 8 digitos.");
    var prior = dao.clientByDocument(type, number);
    if (prior != null) {
      var existing=client(id(prior,"id"),actor);
      if(Boolean.FALSE.equals(existing.get("activo")))throw new BusinessRules.Conflict("El cliente fue retirado del registro activo.");
      return existing;
    }
    var clean =
        new Client(
            BusinessRules.text(input.nombre(), 160),
            type,
            number,
            input.telefono(),
            input.correo(),
            input.proyecto_id());
    long id = dao.clientAdd(clean, actor);
    prototype.profile(id, optional(input.direccion()), optional(input.ocupacion()));
    log.info("cliente_creado id={} actor={}", id, actor.id());
    return dao.client(id);
  }

  private static String optional(String text) {
    return text == null ? null : org.apache.commons.lang3.StringUtils.normalizeSpace(text);
  }

  public Map<String, Object> clientProfile(long id, Actor actor) {
    var primary = client(id, actor);
    var co = prototype.coClient(id);
    if (co != null) {
      client(id(co, "id"), actor);
      primary.put("cotitular", co);
    }
    return primary;
  }

  private Map<String, Object> selectedPlan(Map<String, Object> lot, Long requested) {
    var plans = (List<Map<String, Object>>) lot.get("planes");
    if (requested == null) return plans.isEmpty() ? null : plans.getLast();
    return plans.stream()
        .filter(p -> id(p, "id") == requested)
        .findFirst()
        .orElseThrow(() -> new IllegalArgumentException("Selecciona un plan vigente del lote."));
  }

  @Transactional
  public Map<String, Object> reserve(Reservation in, Actor a) {
    var lot = dao.lot(in.lote_id(), true);
    BusinessRules.requireAvailable((String) lot.get("estado"));
    var primary=client(in.cliente_id(), a);
    if(Boolean.FALSE.equals(primary.get("activo")))throw new IllegalArgumentException("El cliente está retirado del registro activo.");
    if(id(primary,"proyecto_id")!=id(lot,"proyecto_id"))throw new IllegalArgumentException("Selecciona un cliente del proyecto del lote.");
    if(in.version_catalogo()!=null&&in.version_catalogo()!=id(lot,"version"))throw new BusinessRules.Conflict("Los precios del catálogo cambiaron. Revisa el lote nuevamente.");
    var plan = selectedPlan(lot, in.plan_id());
    var price=in.precio_acordado()==null?(BigDecimal)lot.get("precio"):in.precio_acordado();
    if(!a.manager()&&price.compareTo((BigDecimal)lot.get("precio"))!=0)throw new BusinessRules.Forbidden("El asesor puede ajustar inicial y cuotas, conservando el precio del lote.");
    var initial=in.inicial_acordada()!=null?in.inicial_acordada():plan==null?price:(BigDecimal)plan.get("inicial");
    int count=in.numero_cuotas_acordado()!=null?in.numero_cuotas_acordado():plan==null?1:((Number)plan.get("numero_cuotas")).intValue();
    OperationsDao.financial(price,initial,count);BusinessRules.amount(in.monto(),price);
    if (in.cotitular_id() != null) {
      client(in.cotitular_id(), a);
      if (!prototype.linked(in.cliente_id(), in.cotitular_id()))
        throw new IllegalArgumentException("El cotitular no esta vinculado al titular.");
      for (long person : new long[] {in.cliente_id(), in.cotitular_id()}) {
        var sides = dao.documents(person).stream().map(d -> d.get("lado")).toList();
        if (!sides.containsAll(List.of("ANVERSO", "REVERSO")))
          throw new IllegalArgumentException(
              "Completa ambas caras del DNI del titular y cotitular.");
      }
    }
    long id = dao.reserve(in.lote_id(), in.cliente_id(), a.id(), in.monto(), in.observacion());
    deadlines.initialize(id,in.monto(),in.plazo_dias());
    prototype.terms(id, lot, plan, in.cotitular_id());
    ledger.terms(id,price,initial,count);
    dao.lotState(in.lote_id(), "RESERVADO");
    dao.history(in.lote_id(), a.id(), id, "DISPONIBLE", "RESERVADO", "Separacion registrada");
    ledger.created(id,a);
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
    ledger.released(id,a,reason);
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
    prototype.terms(
        id,
        next,
        selectedPlan(next, null),
        r.get("cotitular_id") == null ? null : ((Number) r.get("cotitular_id")).longValue());
    dao.lotState(previous, "DISPONIBLE");
    dao.lotState(input.lote_id(), "RESERVADO");
    dao.history(previous, a.id(), id, "RESERVADO", "DISPONIBLE", reason);
    dao.history(input.lote_id(), a.id(), id, "DISPONIBLE", "RESERVADO", reason);
    ledger.capture(id);
    ledger.audit(a,"OPERACION",id,"REASIGNAR",reason,r,dao.reservation(id,false));
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
        .stream().noneMatch(p -> id((Map<String, Object>) p, "id") == in.plan_id())
        && (r.get("plan_pago_id")==null || id(r,"plan_pago_id")!=in.plan_id()))
      throw new IllegalArgumentException("Selecciona un plan vigente del lote.");
    OperationsDao.financial(in.precio(),in.inicial(),in.numero_cuotas()!=null?in.numero_cuotas():r.get("numero_cuotas_acordado")==null?1:((Number)r.get("numero_cuotas_acordado")).intValue());
    dao.sale(id, a.id(), in);
    dao.reservationState(id, "CONFIRMADA");
    dao.lotState(lotId, "VENDIDO");
    ledger.sold(id,a,in.precio(),in.inicial(),in.numero_cuotas());
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
