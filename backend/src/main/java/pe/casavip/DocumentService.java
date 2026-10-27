package pe.casavip;

import java.io.*;
import java.nio.file.*;
import java.util.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.*;
import org.springframework.web.multipart.MultipartFile;
import pe.casavip.ApiModels.*;

/** Fotografias privadas con nombres generados por el servidor y lectura autorizada. */
@Service
public class DocumentService {
  private final CommercialDao dao;
  private final CommercialService commercial;
  private final Path root;

  public DocumentService(
      CommercialDao dao, CommercialService commercial, @Value("${app.private-root}") String root) {
    this.dao = dao;
    this.commercial = commercial;
    this.root = Path.of(root).toAbsolutePath().normalize();
  }

  private static String imageType(byte[] bytes) {
    if (bytes.length >= 8
        && bytes[0] == (byte) 0x89
        && bytes[1] == 0x50
        && bytes[2] == 0x4e
        && bytes[3] == 0x47
        && bytes[4] == 13
        && bytes[5] == 10
        && bytes[6] == 26
        && bytes[7] == 10) return "png";
    if (bytes.length >= 3
        && bytes[0] == (byte) 0xff
        && bytes[1] == (byte) 0xd8
        && bytes[2] == (byte) 0xff) return "jpg";
    throw new IllegalArgumentException("Solo se aceptan fotografias PNG o JPEG.");
  }

  @Transactional
  public void save(long client, String side, MultipartFile file, Actor actor) throws IOException {
    commercial.client(client, actor);
    if (!Set.of("ANVERSO", "REVERSO").contains(side))
      throw new IllegalArgumentException("Lado de documento no valido.");
    if (file.isEmpty() || file.getSize() > 5 * 1024 * 1024)
      throw new IllegalArgumentException("La fotografia debe pesar entre 1 byte y 5 MB.");
    byte[] bytes = file.getBytes();
    String ext = imageType(bytes);
    if (javax.imageio.ImageIO.read(new ByteArrayInputStream(bytes)) == null)
      throw new IllegalArgumentException("La fotografia no se puede leer.");
    Files.createDirectories(root);
    Path dest = root.resolve(UUID.randomUUID() + "." + ext);
    var previous =
        dao.documents(client).stream()
            .filter(d -> side.equals(d.get("lado")))
            .findFirst()
            .map(d -> dao.document(CommercialService.id(d, "id")))
            .orElse(null);
    Files.write(dest, bytes, StandardOpenOption.CREATE_NEW);
    try {
      dao.document(client, side, dest.getFileName().toString());
    } catch (RuntimeException e) {
      Files.deleteIfExists(dest);
      throw e;
    }
    TransactionSynchronizationManager.registerSynchronization(
        new TransactionSynchronization() {
          public void afterCompletion(int status) {
            try {
              if (status != STATUS_COMMITTED) Files.deleteIfExists(dest);
              else if (previous != null)
                Files.deleteIfExists(safe((String) previous.get("ruta_privada")));
            } catch (IOException ignored) {
            }
          }
        });
  }

  private Path safe(String name) {
    Path p = root.resolve(name).normalize();
    if (!p.startsWith(root)) throw new BusinessRules.Forbidden("Ruta no permitida.");
    return p;
  }

  public byte[] read(long document, Actor actor) throws IOException {
    var d = dao.document(document);
    commercial.client(CommercialService.id(d, "cliente_id"), actor);
    return Files.readAllBytes(safe((String) d.get("ruta_privada")));
  }
}
