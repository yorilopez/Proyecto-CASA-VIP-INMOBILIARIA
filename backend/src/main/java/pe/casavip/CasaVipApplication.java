package pe.casavip;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/** Punto de entrada de la API de CASA VIP. */
@org.springframework.scheduling.annotation.EnableScheduling
@SpringBootApplication
public class CasaVipApplication {
  public static void main(String[] args) {
    SpringApplication.run(CasaVipApplication.class, args);
  }
}
