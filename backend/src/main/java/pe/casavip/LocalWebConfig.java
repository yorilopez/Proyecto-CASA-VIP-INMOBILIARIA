package pe.casavip;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.web.embedded.tomcat.TomcatServletWebServerFactory;
import org.springframework.boot.web.server.WebServerFactoryCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Permite usar el conector asincrono de Tomcat en entornos Windows con restricciones NIO. */
@Configuration
public class LocalWebConfig {
  @Bean
  @ConditionalOnProperty(name = "app.nio2", havingValue = "true")
  WebServerFactoryCustomizer<TomcatServletWebServerFactory> nio2Connector() {
    return factory -> factory.setProtocol("org.apache.coyote.http11.Http11Nio2Protocol");
  }
}
