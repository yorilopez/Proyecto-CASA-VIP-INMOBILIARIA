package pe.casavip;

import com.google.common.cache.Cache;
import com.google.common.cache.CacheBuilder;
import java.time.*;
import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import org.apache.commons.codec.digest.DigestUtils;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import pe.casavip.ApiModels.*;

/** Sesiones opacas con expiracion. La base solo conserva el hash del token. */
@Service
public class AuthService {
  private final CommercialDao dao;
  private final BCryptPasswordEncoder passwords = new BCryptPasswordEncoder(12);
  private final String dummy = passwords.encode("dummy-password-not-an-account");
  private final Cache<String, AtomicInteger> failures =
      CacheBuilder.newBuilder().maximumSize(10000).expireAfterWrite(15, TimeUnit.MINUTES).build();

  public AuthService(CommercialDao dao) {
    this.dao = dao;
  }

  public Map<String, Object> login(Login in) {
    if(in.password().codePointCount(0,in.password().length())>64 || in.password().getBytes(java.nio.charset.StandardCharsets.UTF_8).length>72)
      throw new IllegalArgumentException("La contraseña supera el límite de caracteres o bytes permitido.");
    String key = in.email().strip().toLowerCase(Locale.ROOT);
    AtomicInteger count = failures.asMap().computeIfAbsent(key, k -> new AtomicInteger());
    if (count.get() >= 5)
      throw new ResponseStatusException(
          HttpStatus.TOO_MANY_REQUESTS, "Espera 15 minutos antes de volver a intentar.");
    var user = dao.user(key);
    boolean valid =
        passwords.matches(in.password(), user == null ? dummy : (String) user.get("password_hash"));
    if (user == null || !valid) {
      count.incrementAndGet();
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Credenciales no validas.");
    }
    failures.invalidate(key);
    byte[] bytes = new byte[32];
    new java.security.SecureRandom().nextBytes(bytes);
    String token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    Instant expires = Instant.now().plus(in.remember()?Duration.ofDays(30):Duration.ofHours(2));
    dao.sessionAdd(CommercialService.id(user, "id"), DigestUtils.sha256Hex(token), expires);
    return Map.of("token", token, "expires", expires.toString(), "user", actor(user));
  }

  private Actor actor(Map<String, Object> row) {
    return new Actor(
        CommercialService.id(row, "id"),
        (String) row.get("nombre"),
        (String) row.get("rol"),
        (String) row.get("telefono"));
  }

  public Actor resolve(String token) {
    if (token == null || token.length() != 43) return null;
    var row = dao.session(DigestUtils.sha256Hex(token));
    return row == null ? null : actor(row);
  }

  public void logout(String token) {
    dao.sessionRemove(DigestUtils.sha256Hex(token));
  }
}
