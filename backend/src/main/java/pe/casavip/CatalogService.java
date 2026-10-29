package pe.casavip;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.*;
import java.math.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import pe.casavip.ApiModels.Actor;

/** Importación en dos pasos, con versiones y sin modificar condiciones de operaciones. */
@Service
public class CatalogService {
 final OperationsDao d;final CommercialDao dao;final ObjectMapper json;
 public CatalogService(OperationsDao d,CommercialDao dao,ObjectMapper json){this.d=d;this.dao=dao;this.json=json;}
 private static long number(Object value){try{return new BigDecimal(value.toString()).longValueExact();}catch(Exception e){throw new IllegalArgumentException("Usa identificadores y cantidades enteras.");}}
 private static Object value(Map<String,Object> r,String key,Object fallback){return r.get(key)==null||r.get(key).toString().isBlank()?fallback:r.get(key);}
 private List<Map<String,Object>> parse(MultipartFile file)throws IOException {
   if(file.isEmpty()||file.getSize()>5*1024*1024)throw new IllegalArgumentException("El catálogo debe pesar entre 1 byte y 5 MB.");
   String name=Objects.toString(file.getOriginalFilename(),"").toLowerCase(Locale.ROOT);
   if(name.endsWith(".json")){
     var root=json.readTree(file.getBytes());if(root.isObject())root=root.get("lotes");
     if(root==null||!root.isArray())throw new IllegalArgumentException("El JSON debe ser una lista de lotes o contener la propiedad lotes.");
     var rows=new ArrayList<Map<String,Object>>();for(var item:root){if(!item.isObject())throw new IllegalArgumentException("Cada lote debe ser un objeto.");rows.add(json.convertValue(item,new com.fasterxml.jackson.core.type.TypeReference<Map<String,Object>>(){}));}return rows;
   }
   if(name.endsWith(".xlsx")){
     try(var book=new XSSFWorkbook(file.getInputStream())){
       var sheet=book.getSheetAt(0);if(sheet.getLastRowNum()>1000)throw new IllegalArgumentException("Máximo 1000 lotes por carga.");
       var fmt=new DataFormatter(Locale.ROOT);var table=new ArrayList<List<String>>();
       for(var row:sheet){var cells=new ArrayList<String>();for(int i=0;i<row.getLastCellNum();i++){var cell=row.getCell(i);if(cell!=null&&cell.getCellType()==CellType.FORMULA)throw new IllegalArgumentException("Reemplaza las fórmulas por valores antes de importar.");cells.add(cell==null?"":fmt.formatCellValue(cell));}table.add(cells);}return table(table);
     }
   }
   if(!name.endsWith(".csv"))throw new IllegalArgumentException("Usa CSV UTF-8, Excel .xlsx o JSON.");
   String text=new String(file.getBytes(),StandardCharsets.UTF_8).replace("\ufeff","");
   String first=text.lines().findFirst().orElse("");char separator=first.contains(";")?';':',';
   var rows=new ArrayList<List<String>>();var row=new ArrayList<String>();var cell=new StringBuilder();boolean quoted=false;
   for(int i=0;i<text.length();i++){
     char ch=text.charAt(i);
     if(ch=='"'){if(quoted&&i+1<text.length()&&text.charAt(i+1)=='"'){cell.append('"');i++;}else quoted=!quoted;}
     else if(ch==separator&&!quoted){row.add(cell.toString());cell.setLength(0);}
     else if((ch=='\n'||ch=='\r')&&!quoted){if(ch=='\r'&&i+1<text.length()&&text.charAt(i+1)=='\n')i++;row.add(cell.toString());cell.setLength(0);rows.add(row);row=new ArrayList<>();}
     else cell.append(ch);
   }
   if(quoted)throw new IllegalArgumentException("El CSV contiene comillas sin cerrar.");
   if(!row.isEmpty()||!cell.isEmpty()){row.add(cell.toString());rows.add(row);}return table(rows);
 }
 private List<Map<String,Object>> table(List<List<String>> table){
   if(table.isEmpty())throw new IllegalArgumentException("El archivo no contiene encabezados.");
   var headers=table.getFirst().stream().map(s->s.strip().toLowerCase(Locale.ROOT)).toList();
   if(new HashSet<>(headers).size()!=headers.size()||!headers.containsAll(List.of("lote_id","precio")))throw new IllegalArgumentException("Incluye encabezados únicos lote_id y precio.");
   var rows=new ArrayList<Map<String,Object>>();for(int i=1;i<table.size();i++){var cells=table.get(i);if(cells.stream().allMatch(String::isBlank))continue;if(cells.size()>headers.size())throw new IllegalArgumentException("La fila "+(i+1)+" tiene columnas adicionales.");var row=new LinkedHashMap<String,Object>();for(int j=0;j<headers.size();j++)row.put(headers.get(j),j<cells.size()?cells.get(j).strip():"");rows.add(row);}return rows;
 }
 private List<Map<String,Object>> normalize(List<Map<String,Object>> rows,boolean applying){
   if(rows.isEmpty()||rows.size()>1000)throw new IllegalArgumentException("Carga entre 1 y 1000 lotes.");
   var ids=new HashSet<Long>();var clean=new ArrayList<Map<String,Object>>();
   // Orden estable para que dos cargas concurrentes bloqueen las filas en el mismo orden.
   rows=new ArrayList<>(rows);rows.sort(Comparator.comparingLong(r->number(r.get("lote_id"))));
   for(var input:rows){
     long id=number(input.get("lote_id"));if(!ids.add(id))throw new IllegalArgumentException("El lote "+id+" está duplicado.");
     var lot=dao.lot(id,applying);var raw=d.row("select version from lote where id=?",id);
     var r=new LinkedHashMap<String,Object>();r.put("lote_id",id);r.put("proyecto",lot.get("proyecto"));r.put("manzana",lot.get("manzana"));r.put("lote",lot.get("codigo"));r.put("estado",lot.get("estado"));r.put("version",raw.get("version"));r.put("precio_anterior",lot.get("precio"));
     if("VENDIDO".equals(lot.get("estado"))){r.put("omitido",true);clean.add(r);continue;}
     if(applying&&(input.get("version")==null||number(input.get("version"))!=number(raw.get("version"))))throw new BusinessRules.Conflict("El catálogo cambió para el lote "+id+". Genera una vista previa nueva.");
     var price=OperationsDao.money(input.get("precio"));if(price.signum()<=0)throw new IllegalArgumentException("El precio debe ser mayor que cero.");r.put("precio",price);
     var area=OperationsDao.money(value(input,"area_m2",lot.get("area_m2")));if(area.signum()<=0)throw new IllegalArgumentException("El área debe ser positiva.");r.put("area_m2",area);
     String location=Objects.toString(value(input,"ubicacion",Objects.toString(lot.get("referencia"),"")));if(location.length()>160)throw new IllegalArgumentException("La ubicación admite hasta 160 caracteres.");r.put("ubicacion",location);
     var plans=(List<Map<String,Object>>)lot.get("planes");var next=new ArrayList<Map<String,Object>>();
     Object initial=value(input,"inicial",null),count=value(input,"numero_cuotas",null);
     if(input.get("planes") instanceof List<?> list){if(list.isEmpty()||list.size()>12)throw new IllegalArgumentException("Incluye de 1 a 12 planes.");for(var p:list){if(!(p instanceof Map<?,?> plan))throw new IllegalArgumentException("Revisa los planes del lote.");next.add(plan(price,plan.get("inicial"),plan.get("numero_cuotas")));}}
     else if(initial!=null||count!=null){if(initial==null||count==null)throw new IllegalArgumentException("Indica inicial y numero_cuotas juntos.");next.add(plan(price,initial,count));}
     else for(var p:plans)next.add(plan(price,p.get("inicial"),p.get("numero_cuotas")));
     if(next.isEmpty())throw new IllegalArgumentException("El lote requiere un plan de pago.");
     var counts=new HashSet<Object>();for(var p:next)if(!counts.add(p.get("numero_cuotas")))throw new IllegalArgumentException("No repitas el número de cuotas de un lote.");
     r.put("planes",next);r.put("omitido",false);clean.add(r);
   }return clean;
 }
 private Map<String,Object> plan(BigDecimal price,Object initial,Object count){var f=OperationsDao.financial(price,OperationsDao.money(initial),Math.toIntExact(number(count)));if(((BigDecimal)f.get("mensualidad")).signum()<=0)throw new IllegalArgumentException("El plan del catálogo debe tener saldo y mensualidad positivos.");return f;}
 public Map<String,Object> preview(MultipartFile file,Actor a)throws IOException {BusinessRules.requireAdmin(a.role());try{return Map.of("rows",normalize(parse(file),false));}catch(org.springframework.dao.DataAccessException e){throw e;}catch(IllegalArgumentException e){throw e;}catch(Exception e){throw new IllegalArgumentException("No se pudo leer el archivo. Revisa la plantilla y sus valores.");}}
 @Transactional public Map<String,Object> apply(List<Map<String,Object>> rows,String reason,Actor a){
   BusinessRules.requireAdmin(a.role());reason=BusinessRules.text(reason,500);var normalized=normalize(rows,true);int applied=0,skipped=0;
   for(var r:normalized){if(Boolean.TRUE.equals(r.get("omitido"))){skipped++;continue;}long lot=((Number)r.get("lote_id")).longValue();var before=dao.lot(lot,false);long version=((Number)r.get("version")).longValue()+1;
     d.execute("update lote set precio=?,area_m2=?,ubicacion=?,version=version+1 where id=?",r.get("precio"),r.get("area_m2"),r.get("ubicacion"),lot);
     // Se crean planes por lote y versión; nunca se muta un plan referenciado por una venta.
     d.execute("delete from lote_plan_pago where lote_id=?",lot);
     for(var p:(List<Map<String,Object>>)r.get("planes")){
       String name="Cat L"+lot+" V"+version+" "+p.get("numero_cuotas")+" cuotas";
       d.execute("insert into plan_pago(proyecto_id,nombre,inicial,numero_cuotas,monto_cuota) values(?,?,?,?,?)",before.get("proyecto_id"),name,p.get("inicial"),p.get("numero_cuotas"),p.get("mensualidad"));
       var pp=d.row("select id from plan_pago where proyecto_id=? and nombre=?",before.get("proyecto_id"),name);d.execute("insert into lote_plan_pago(lote_id,plan_pago_id) values(?,?)",lot,pp.get("id"));
     }
     d.audit(a,"CATALOGO",lot,"ACTUALIZAR",reason,before,dao.lot(lot,false));applied++;
   }
   return Map.of("actualizados",applied,"vendidos_omitidos",skipped,"rows",normalized);
 }
 public List<Map<String,Object>> list(Actor a){BusinessRules.requireAdmin(a.role());return d.list("select l.id as lote_id,p.nombre as proyecto,e.nombre as etapa,m.codigo as manzana,l.codigo as lote,l.precio,l.area_m2,l.estado,l.ubicacion,l.version from lote l join manzana m on m.id=l.manzana_id join etapa e on e.id=m.etapa_id join proyecto p on p.id=e.proyecto_id order by p.id,m.codigo,l.id");}
}
