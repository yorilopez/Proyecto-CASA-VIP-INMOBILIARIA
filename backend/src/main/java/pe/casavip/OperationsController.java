package pe.casavip;
import jakarta.validation.Valid;
import java.util.*;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import pe.casavip.ApiModels.*;
import pe.casavip.OperationModels.*;

/** Entradas de la ampliación comercial; las reglas se aplican en los servicios. */
@RestController @RequestMapping("/api")
public class OperationsController {
 final OperationsService ops;final CatalogService catalog;final DocumentService documents;
 public OperationsController(OperationsService ops,CatalogService catalog,DocumentService documents){this.ops=ops;this.catalog=catalog;this.documents=documents;}
 @DeleteMapping("/clients/{id}") public Object deleteClient(@PathVariable long id,@AuthenticationPrincipal Actor a){ops.archiveClient(id,a);return Map.of("ok",true);}
 @DeleteMapping("/clients/{id}/cotitular") public Object unlink(@PathVariable long id,@AuthenticationPrincipal Actor a){ops.unlink(id,a);return Map.of("ok",true);}
 @GetMapping("/operations/{id}") public Object detail(@PathVariable long id,@AuthenticationPrincipal Actor a){return ops.detail(id,a);}
 @PutMapping("/operations/{id}") public Object correct(@PathVariable long id,@Valid @RequestBody Correction in,@AuthenticationPrincipal Actor a){return ops.correct(id,in,a);}
 @GetMapping("/operations/{id}/share") public Object share(@PathVariable long id,@AuthenticationPrincipal Actor a){return ops.share(id,a);}
 @GetMapping("/operations/{id}/documents/{doc}") public ResponseEntity<byte[]> document(@PathVariable long id,@PathVariable long doc,@AuthenticationPrincipal Actor a)throws java.io.IOException{return ResponseEntity.ok().header("Cache-Control","no-store").body(documents.readOperation(id,doc,a));}
 @GetMapping("/admin/users") public Object users(@AuthenticationPrincipal Actor a){return ops.users(a);}
 @PostMapping("/admin/users") public Object addUser(@Valid @RequestBody UserInput in,@AuthenticationPrincipal Actor a){return ops.saveUser(null,in,a);}
 @PutMapping("/admin/users/{id}") public Object user(@PathVariable long id,@Valid @RequestBody UserInput in,@AuthenticationPrincipal Actor a){return ops.saveUser(id,in,a);}
 @PatchMapping("/admin/users/{id}/active") public Object active(@PathVariable long id,@RequestBody ActiveUser in,@AuthenticationPrincipal Actor a){ops.activeUser(id,in.activo(),a);return Map.of("ok",true);}
 @DeleteMapping("/admin/users/{id}") public Object deleteUser(@PathVariable long id,@AuthenticationPrincipal Actor a){ops.deleteUser(id,a);return Map.of("ok",true);}
 @GetMapping("/admin/history") public Object history(@RequestParam(required=false) String entity,@AuthenticationPrincipal Actor a){return ops.history(a,entity);}
 @GetMapping("/admin/catalog") public Object catalog(@AuthenticationPrincipal Actor a){return catalog.list(a);}
 @PostMapping("/admin/catalog/preview") public Object preview(@RequestParam("file")MultipartFile file,@AuthenticationPrincipal Actor a)throws java.io.IOException{return catalog.preview(file,a);}
 @PostMapping("/admin/catalog/apply") public Object apply(@RequestBody Map<String,Object> in,@AuthenticationPrincipal Actor a){
   if(!(in.get("rows") instanceof List<?> list))throw new IllegalArgumentException("Genera primero la vista previa del catálogo.");
   var rows=new ArrayList<Map<String,Object>>();for(var r:list){if(!(r instanceof Map<?,?>))throw new IllegalArgumentException("Revisa las filas del catálogo.");rows.add((Map<String,Object>)r);}
   return catalog.apply(rows,Objects.toString(in.get("motivo"),""),a);
 }
 @GetMapping("/notifications") public Object notifications(@AuthenticationPrincipal Actor a){return ops.notifications(a);}
 @PostMapping("/notifications/read") public Object read(@RequestBody ReadNotifications in,@AuthenticationPrincipal Actor a){ops.read(in.hasta(),a);return Map.of("ok",true);}
 @PostMapping("/notifications/{id}/read") public Object readOne(@PathVariable long id,@AuthenticationPrincipal Actor a){ops.readOne(id,a);return Map.of("ok",true);}
}
