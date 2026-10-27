package pe.casavip;

import java.math.BigDecimal;
import java.util.*;
import pe.casavip.ApiModels.*;

/** Contrato DAO. La capa de servicio depende de esta abstraccion. */
public interface CommercialDao {
  Map<String, Object> user(String email);

  Map<String, Object> session(String tokenHash);

  void sessionAdd(long userId, String tokenHash, java.time.Instant expires);

  void sessionRemove(String hash);

  List<Map<String, Object>> projects();

  List<Map<String, Object>> stages(long project);

  List<Map<String, Object>> blocks(long project);

  List<Map<String, Object>> lots(Long project, Long block, String state, String query);

  Map<String, Object> lot(long id, boolean lock);

  void lockLots(long a, long b);

  List<Map<String, Object>> clients(Actor actor, String query);

  Map<String, Object> client(long id);

  long clientAdd(Client input, Actor actor);

  Map<String, Object> clientByDocument(String type, String number);

  List<Map<String, Object>> reservations(Actor actor);

  Map<String, Object> reservation(long id, boolean lock);

  long reserve(long lot, long client, long actor, BigDecimal amount, String observation);

  void lotState(long lot, String state);

  void reservationState(long id, String state);

  void reservationMove(long id, long lot);

  void history(long lot, long actor, Long reservation, String previous, String next, String reason);

  List<Map<String, Object>> history(long lot);

  void sale(long reservation, long responsible, Sale input);

  void document(long client, String side, String privatePath);

  List<Map<String, Object>> documents(long client);

  Map<String, Object> document(long id);
}
