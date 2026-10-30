package pe.casavip;

import java.io.*;
import java.nio.charset.*;
import java.util.*;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;

@Service
public class DashboardReports {
  public record Section(String title,List<String> fields,List<String> labels,List<Map<String,Object>> rows) {}
  static final Map<String,String> TITLES=new LinkedHashMap<>();
  static { TITLES.put("separaciones","Separaciones");TITLES.put("ventas","Ventas");TITLES.put("clientes","Clientes nuevos");TITLES.put("asesores","Actividad por asesor");TITLES.put("ranking","Ranking de ventas");TITLES.put("liberaciones","Liberaciones"); }
  @SuppressWarnings("unchecked")
  public List<Section> sections(Map<String,Object> data,String selected) {
    if(!"general".equals(selected)&&!TITLES.containsKey(selected))throw new IllegalArgumentException("Selecciona una sección válida.");
    var result=new ArrayList<Section>();
    for(var e:TITLES.entrySet())if("general".equals(selected)||e.getKey().equals(selected)) {
      String[] fields,labels;
      switch(e.getKey()) {
        case "clientes" -> {fields=new String[]{"nombre","participacion","tipo_documento","numero_documento","telefono","correo","fecha_registro","proyecto","lotes"};labels=new String[]{"Nombre","Participación","Documento","Número","Teléfono","Correo","Registro","Proyecto","Lotes separados o vendidos"};}
        case "asesores" -> {fields=new String[]{"asesor","separaciones","ventas","lotes_separados","lotes_vendidos"};labels=new String[]{"Asesor","Número de separaciones","Número de ventas","Proyectos y lotes separados","Proyectos y lotes vendidos"};}
        case "ranking" -> {fields=new String[]{"posicion","asesor","ventas","lotes_vendidos"};labels=new String[]{"Puesto","Asesor","Número de ventas","Proyectos y lotes vendidos"};}
        case "liberaciones" -> {fields=new String[]{"id","fecha_liberacion","proyecto","manzana","lote","cliente","asesor","responsable","motivo"};labels=new String[]{"Operación","Fecha de liberación","Proyecto","Manzana","Lote","Cliente","Asesor","Responsable","Motivo"};}
        default -> {fields=new String[]{"id",e.getKey().equals("ventas")?"fecha_venta":"fecha_registro","proyecto","manzana","lote","cliente","documento","telefono","cotitular","documento_cotitular","asesor","estado","fecha_vencimiento"};labels=new String[]{"Operación","Fecha","Proyecto","Manzana","Lote","Titular","Documento","Teléfono","Cotitular","Documento cotitular","Asesor","Estado actual","Vencimiento"};}
      }
      result.add(new Section(e.getValue(),List.of(fields),List.of(labels),(List<Map<String,Object>>)data.get(e.getKey())));
    }
    return result;
  }

  public Section history(List<Map<String,Object>> rows) {
    return new Section("Historial comercial",List.of("fecha","usuario","rol","entidad","registro_id","accion","motivo","anterior","actual"),List.of("Fecha","Usuario","Rol","Tipo","Registro","Acción","Motivo","Antes","Después"),rows);
  }
  public byte[] export(String format,String heading,String context,List<Section> sections) throws IOException {
    return switch(format){case "xlsx"->excel(heading,context,sections);case "txt"->text(heading,context,sections).getBytes(StandardCharsets.UTF_8);case "pdf"->pdf(heading,context,sections);default->throw new IllegalArgumentException("Selecciona PDF, Excel o TXT.");};
  }
  static String value(Object value) {
    if(value==null)return "—";
    if(value instanceof Collection<?> list)return list.isEmpty()?"—":String.join("; ",list.stream().map(DashboardReports::value).toList());
    if(value instanceof Map<?,?> map)return String.join("; ",map.entrySet().stream().map(e->e.getKey()+": "+value(e.getValue())).toList());
    if(value instanceof java.sql.Date date)return date.toLocalDate().format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy"));
    if(value instanceof java.time.LocalDate date)return date.format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy"));
    if(value instanceof java.time.OffsetDateTime || value instanceof java.util.Date)return CommercialDashboard.instant(value).atZone(CommercialDashboard.LIMA).format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));
    return switch(value.toString()){case "ACTIVA"->"Separada";case "CONFIRMADA"->"Vendida";case "ANULADA","VENCIDA"->"Liberada";default->value.toString();};
  }
  String text(String heading,String context,List<Section> sections) {
    var out=new StringBuilder("CASA VIP\n"+heading+"\n"+context+"\n");
    for(var s:sections){out.append("\n").append(s.title()).append(" ( ").append(s.rows().size()).append(" registros )\n");if(s.rows().isEmpty())out.append("Sin movimientos.\n");int n=0;for(var row:s.rows()){out.append("\nRegistro ").append(++n).append("\n");for(int i=0;i<s.fields().size();i++)out.append(s.labels().get(i)).append(": ").append(value(row.get(s.fields().get(i)))).append("\n");}}
    return out.toString();
  }
  byte[] excel(String heading,String context,List<Section> sections)throws IOException {
    try(var book=new XSSFWorkbook();var out=new ByteArrayOutputStream()) {
      var header=book.createCellStyle();header.setFillForegroundColor(IndexedColors.BLACK.getIndex());header.setFillPattern(FillPatternType.SOLID_FOREGROUND);var font=book.createFont();font.setBold(true);font.setColor(IndexedColors.GOLD.getIndex());header.setFont(font);header.setWrapText(true);
      var body=book.createCellStyle();body.setWrapText(true);body.setVerticalAlignment(VerticalAlignment.TOP);body.setBorderBottom(BorderStyle.HAIR);body.setBottomBorderColor(IndexedColors.GREY_25_PERCENT.getIndex());
      var summary=book.createSheet("Resumen");summary.createRow(0).createCell(0).setCellValue("CASA VIP · "+heading);summary.createRow(1).createCell(0).setCellValue(context);
      int sr=3;for(var section:sections){var row=summary.createRow(sr++);row.createCell(0).setCellValue(section.title());row.createCell(1).setCellValue(section.rows().size());}
      summary.setColumnWidth(0,70*256);summary.setColumnWidth(1,20*256);
      for(var s:sections){var sheet=book.createSheet(s.title());sheet.createRow(0).createCell(0).setCellValue(heading);sheet.createRow(1).createCell(0).setCellValue(context);var h=sheet.createRow(3);h.setHeightInPoints(32);
        for(int i=0;i<s.labels().size();i++){var cell=h.createCell(i);cell.setCellValue(s.labels().get(i));cell.setCellStyle(header);sheet.setColumnWidth(i,(s.fields().get(i).contains("lotes")||s.fields().get(i).equals("motivo")?55:25)*256);}
        int r=4;for(var record:s.rows()){var row=sheet.createRow(r++);int lines=1;for(int i=0;i<s.fields().size();i++){var cell=row.createCell(i);Object v=record.get(s.fields().get(i));if(v instanceof Number n)cell.setCellValue(n.doubleValue());else{String t=value(v);cell.setCellValue(t);lines=Math.max(lines,(int)Math.ceil(t.length()/(sheet.getColumnWidth(i)/256.0-2)));}cell.setCellStyle(body);}row.setHeightInPoints(Math.min(409,Math.max(30,lines*15)));}
        if(s.rows().isEmpty())sheet.createRow(4).createCell(0).setCellValue("Sin movimientos.");
        sheet.setAutoFilter(new CellRangeAddress(3,Math.max(3,r-1),0,s.fields().size()-1));sheet.createFreezePane(0,4);sheet.getPrintSetup().setLandscape(true);sheet.setFitToPage(true);sheet.getPrintSetup().setFitWidth((short)1);sheet.getPrintSetup().setFitHeight((short)0);sheet.setRepeatingRows(new CellRangeAddress(0,3,-1,-1));
      }
      book.write(out);return out.toByteArray();
    }
  }

  byte[] pdf(String heading,String context,List<Section> sections)throws IOException {
    var lines=new ArrayList<String>();
    for(var section:sections){lines.add("");lines.add(section.title().toUpperCase(Locale.ROOT)+" · "+section.rows().size()+" registros");if(section.rows().isEmpty())lines.add("Sin movimientos.");int n=0;for(var row:section.rows()){lines.add("");lines.add("Registro "+(++n));for(int i=0;i<section.fields().size();i++)wrap(section.labels().get(i)+": "+value(row.get(section.fields().get(i))),lines);}}
    List<List<String>> pages=new ArrayList<>();for(int start=0;start<Math.max(1,lines.size());start+=42)pages.add(lines.subList(start,Math.min(lines.size(),start+42)));
    var objects=new ArrayList<byte[]>();objects.add(bytes("<< /Type /Catalog /Pages 2 0 R >>"));
    var kids=new StringBuilder();for(int i=0;i<pages.size();i++)kids.append(4+i*2).append(" 0 R ");objects.add(bytes("<< /Type /Pages /Kids ["+kids+"] /Count "+pages.size()+" >>"));objects.add(bytes("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>"));
    for(int p=0;p<pages.size();p++){
      objects.add(bytes("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 3 0 R >> >> /Contents "+(5+p*2)+" 0 R >>"));
      var stream=new StringBuilder("0.09 0.09 0.08 rg 0 748 595 94 re f\n0.83 0.67 0.28 rg\nBT /F1 20 Tf 40 804 Td (CASA VIP) Tj ET\n1 1 1 rg\nBT /F1 12 Tf 40 780 Td ("+escape(heading)+") Tj ET\n");
      stream.append("0.3 0.3 0.3 rg\nBT /F1 9 Tf 40 727 Td (").append(escape(context)).append(") Tj ET\n0.1 0.1 0.1 rg\nBT /F1 10 Tf 40 703 Td 15 TL\n");
      for(String line:pages.get(p))stream.append('(').append(escape(line)).append(") Tj T*\n");
      stream.append("ET\nBT /F1 9 Tf 40 34 Td (Página ").append(p+1).append(" de ").append(pages.size()).append(") Tj ET\n");
      byte[] content=bytes(stream.toString());var out=new ByteArrayOutputStream();out.write(bytes("<< /Length "+content.length+" >>\nstream\n"));out.write(content);out.write(bytes("\nendstream"));objects.add(out.toByteArray());
    }
    var out=new ByteArrayOutputStream();out.write(bytes("%PDF-1.4\n%âãÏÓ\n"));var offsets=new ArrayList<Integer>();offsets.add(0);for(int i=0;i<objects.size();i++){offsets.add(out.size());out.write(bytes((i+1)+" 0 obj\n"));out.write(objects.get(i));out.write(bytes("\nendobj\n"));}int xref=out.size();out.write(bytes("xref\n0 "+offsets.size()+"\n0000000000 65535 f \n"));for(int i=1;i<offsets.size();i++)out.write(bytes(String.format(Locale.ROOT,"%010d 00000 n \n",offsets.get(i))));out.write(bytes("trailer\n<< /Size "+offsets.size()+" /Root 1 0 R >>\nstartxref\n"+xref+"\n%%EOF\n"));return out.toByteArray();
  }
  static void wrap(String raw,List<String> lines){for(String part:raw.replace('\r',' ').split("\n",-1)){String text=part;while(text.length()>88){int at=text.lastIndexOf(' ',88);if(at<20)at=88;lines.add(text.substring(0,at));text="  "+text.substring(at).stripLeading();}lines.add(text);}}
  static byte[] bytes(String s){return s.getBytes(Charset.forName("windows-1252"));}
  static String escape(String s){return s.replace("\\","\\\\").replace("(","\\(").replace(")","\\)").replace('\n',' ').replace('\r',' ');}
}
