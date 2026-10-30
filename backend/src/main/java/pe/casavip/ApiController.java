package pe.casavip;

import jakarta.validation.Valid;
import java.io.IOException;
import java.util.*;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import pe.casavip.ApiModels.*;

/** Controladores MVC. Validan solicitudes y delegan casos de uso a servicios. */
@RestController
@RequestMapping("/api")
public class ApiController {
  private final CommercialDao dao;
  private final CommercialService service;
  private final AuthService auth;
  private final DocumentService documents;
  private final ReportService reports;
  private final OperationsService operations;
  private final CommercialQueries queries;

  public ApiController(
      CommercialDao dao,
      CommercialService service,
      AuthService auth,
      DocumentService documents,
      ReportService reports,
      OperationsService operations,
      CommercialQueries queries) {
    this.dao = dao;
    this.service = service;
    this.auth = auth;
    this.documents = documents;
    this.reports = reports;
    this.operations = operations;
    this.queries = queries;
  }

  @GetMapping("/health")
  public Object health() {
    return Map.of("status", "UP", "version", "0.6.0");
  }

  @PostMapping("/auth/login")
  public Object login(@Valid @RequestBody Login in) {
    return auth.login(in);
  }

  @GetMapping("/auth/me")
  public Object me(@AuthenticationPrincipal Actor a) {
    return a;
  }

  @PostMapping("/auth/logout")
  public Object logout(@RequestHeader("Authorization") String header) {
    auth.logout(header.substring(7));
    return Map.of("ok", true);
  }

  @GetMapping("/projects")
  public Object projects() {
    return dao.projects();
  }

  @GetMapping("/projects/{id}/stages")
  public Object stages(@PathVariable long id) {
    return dao.stages(id);
  }

  @GetMapping("/projects/{id}/blocks")
  public Object blocks(@PathVariable long id) {
    return dao.blocks(id);
  }

  @GetMapping("/lots")
  public Object lots(
      @RequestParam(required = false) Long project,
      @RequestParam(required = false) Long block,
      @RequestParam(required = false) String state,
      @RequestParam(required = false) String q) {
    if (state != null && !state.isBlank() && !BusinessRules.STATES.contains(state))
      throw new IllegalArgumentException("Estado no valido.");
    return dao.lots(project, block, state, q);
  }

  @GetMapping("/lots/{id}")
  public Object lot(@PathVariable long id) {
    return dao.lot(id, false);
  }

  @GetMapping("/lots/{id}/history")
  public Object history(@PathVariable long id) {
    return dao.history(id);
  }

  @PatchMapping("/lots/{id}/state")
  public Object state(
      @PathVariable long id, @Valid @RequestBody ChangeState in, @AuthenticationPrincipal Actor a) {
    service.state(id, in, a);
    return Map.of("ok", true);
  }

  @PutMapping("/clients/{id}")
  public Object updateClient(
      @PathVariable long id,
      @Valid @RequestBody Client input,
      @AuthenticationPrincipal Actor actor) {
    return service.updateClient(id, input, actor);
  }

  @GetMapping("/clients/{id}")
  public Object clientProfile(@PathVariable long id, @AuthenticationPrincipal Actor actor) {
    return operations.clientProfile(id, actor);
  }

  @GetMapping("/clients")
  public Object clients(
      @AuthenticationPrincipal Actor a,
      @RequestParam(required = false) String q,
      @RequestParam(required = false) String month,
      @RequestParam(required = false) String category) {
    return queries.clients(a, q, month, category);
  }

  @PostMapping("/clients")
  public Object client(@Valid @RequestBody Client in, @AuthenticationPrincipal Actor a) {
    return service.addClient(in, a);
  }

  @GetMapping("/clients/{id}/documents")
  public Object documents(@PathVariable long id, @AuthenticationPrincipal Actor a) {
    service.client(id, a);
    return dao.documents(id);
  }

  @PostMapping("/clients/{id}/documents/{side}")
  public Object upload(
      @PathVariable long id,
      @PathVariable String side,
      @RequestParam("file") MultipartFile file,
      @AuthenticationPrincipal Actor a)
      throws IOException {
    documents.save(id, side, file, a);
    return Map.of("ok", true);
  }

  @GetMapping("/documents/{id}")
  public ResponseEntity<byte[]> document(@PathVariable long id, @AuthenticationPrincipal Actor a)
      throws IOException {
    return ResponseEntity.ok()
        .contentType(MediaType.APPLICATION_OCTET_STREAM)
        .header("Cache-Control", "no-store")
        .body(documents.read(id, a));
  }

  @GetMapping("/reservations")
  public Object reservations(
      @AuthenticationPrincipal Actor a,
      @RequestParam(required = false) String month,
      @RequestParam(required = false) String state) {
    return queries.operations(a, month, state);
  }

  @PostMapping("/reservations")
  public Object reserve(@Valid @RequestBody Reservation in, @AuthenticationPrincipal Actor a) {
    return service.reserve(in, a);
  }

  @PostMapping("/reservations/{id}/release")
  public Object release(
      @PathVariable long id, @Valid @RequestBody ChangeState in, @AuthenticationPrincipal Actor a) {
    service.release(id, in.motivo(), a);
    return Map.of("ok", true);
  }

  @PostMapping("/reservations/{id}/reassign")
  public Object reassign(
      @PathVariable long id, @Valid @RequestBody Reassign in, @AuthenticationPrincipal Actor a) {
    service.reassign(id, in, a);
    return Map.of("ok", true);
  }

  @PostMapping("/reservations/{id}/sale")
  public Object sell(
      @PathVariable long id, @Valid @RequestBody Sale in, @AuthenticationPrincipal Actor a) {
    service.sell(id, in, a);
    return Map.of("ok", true);
  }

  @GetMapping("/reports/reservations.xlsx")
  public ResponseEntity<byte[]> excel(@AuthenticationPrincipal Actor a) throws IOException {
    return ResponseEntity.ok()
        .header("Content-Disposition", "attachment; filename=separaciones.xlsx")
        .contentType(
            MediaType.parseMediaType(
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
        .body(reports.excel(a));
  }

  @GetMapping("/lots/{id}/card.png")
  public ResponseEntity<byte[]> card(@PathVariable long id, @AuthenticationPrincipal Actor a)
      throws IOException {
    return ResponseEntity.ok().contentType(MediaType.IMAGE_PNG).body(reports.card(id, a));
  }
}
