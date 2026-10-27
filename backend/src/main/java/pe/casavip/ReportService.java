package pe.casavip;

import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.*;
import java.util.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import pe.casavip.ApiModels.*;

/** Reportes separados de la logica transaccional y sin documentos personales. */
@Service
public class ReportService {
  private final CommercialDao dao;

  public ReportService(CommercialDao dao) {
    this.dao = dao;
  }

  public byte[] excel(Actor actor) throws IOException {
    BusinessRules.requireManager(actor.role());
    try (var book = new XSSFWorkbook();
        var out = new ByteArrayOutputStream()) {
      var sheet = book.createSheet("Separaciones");
      String[] columns = {"ID", "Proyecto", "Manzana", "Lote", "Estado", "Monto"};
      var header = sheet.createRow(0);
      for (int i = 0; i < columns.length; i++) header.createCell(i).setCellValue(columns[i]);
      var style = book.createCellStyle();
      var font = book.createFont();
      font.setBold(true);
      style.setFont(font);
      for (var c : header) c.setCellStyle(style);
      int r = 1;
      for (var item : dao.reservations(actor)) {
        var row = sheet.createRow(r++);
        row.createCell(0).setCellValue(((Number) item.get("id")).doubleValue());
        row.createCell(1).setCellValue((String) item.get("proyecto"));
        row.createCell(2).setCellValue((String) item.get("manzana"));
        row.createCell(3).setCellValue((String) item.get("lote"));
        row.createCell(4).setCellValue((String) item.get("estado"));
        row.createCell(5).setCellValue(((Number) item.get("monto")).doubleValue());
      }
      for (int i = 0; i < 6; i++) sheet.autoSizeColumn(i);
      sheet.createFreezePane(0, 1);
      book.write(out);
      return out.toByteArray();
    }
  }

  public byte[] card(long id, Actor actor) throws IOException {
    var lot = dao.lot(id, false);
    var image = new BufferedImage(1080, 1300, BufferedImage.TYPE_INT_RGB);
    Graphics2D g = image.createGraphics();
    g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
    g.setColor(new Color(247, 246, 242));
    g.fillRect(0, 0, 1080, 1300);
    g.setColor(new Color(23, 23, 20));
    g.fillRect(0, 0, 1080, 330);
    g.setColor(new Color(199, 149, 23));
    g.setFont(new Font("SansSerif", Font.BOLD, 76));
    g.drawString("CASA VIP", 80, 150);
    g.setColor(Color.WHITE);
    g.setFont(new Font("SansSerif", Font.PLAIN, 34));
    g.drawString("INVERSIONES INMOBILIARIAS", 80, 215);
    g.setColor(new Color(23, 23, 20));
    g.setFont(new Font("SansSerif", Font.BOLD, 54));
    g.drawString(String.valueOf(lot.get("proyecto")), 80, 430);
    g.setFont(new Font("SansSerif", Font.PLAIN, 38));
    String[] lines = {
      "Etapa: " + lot.get("etapa"),
      "Manzana " + lot.get("manzana") + "   Lote " + lot.get("codigo"),
      "Area: " + lot.get("area_m2") + " m2",
      "Precio: S/ " + lot.get("precio"),
      "Inicial: S/ " + lot.get("inicial"),
      "Plan: " + lot.get("numero_cuotas") + " cuotas",
      "Asesor: " + actor.name(),
      "Generada: " + java.time.LocalDate.now(),
      "Disponibilidad sujeta a confirmacion."
    };
    int y = 530;
    for (String line : lines) {
      g.drawString(line, 80, y);
      y += 70;
    }
    g.dispose();
    try (var out = new ByteArrayOutputStream()) {
      javax.imageio.ImageIO.write(image, "png", out);
      return out.toByteArray();
    }
  }
}
