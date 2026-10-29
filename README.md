# CASA VIP · ampliación comercial 0.4.0

Aplicativo Flutter con API Java 21 / Spring Boot y base H2 de demostración o PostgreSQL. Amplía la versión 0.3.1 conservando el diseño del prototipo del avance 2.

## Funciones nuevas

Login con límites de longitud; clientes existentes con cotitular; eliminación con conservación del historial; cartera con filtros de separación y venta; y navegación Operaciones para ambos tipos de registro.

Cada operación conserva sus condiciones negociadas y documentos. El asesor puede ajustar inicial y cuotas; administrador y responsable comercial también pueden negociar precio y corregir operaciones guardadas con motivo y control de versión. Los cálculos usan céntimos y la última cuota absorbe el redondeo.

El administrador dispone de catálogo, edición e importación CSV/XLSX/JSON y gestión de usuarios. El responsable comercial puede deshabilitar usuarios y revisar historiales generales. Hay compartición por rol y notificaciones globales dentro de la aplicación.

Consulta [Novedades y funcionamiento](docs/NOVEDADES_0_4_0.md), [matriz funcional](docs/Funciones_0_4_0.md) y [plantillas de importación](docs/plantillas).

## Ejecutar el aplicativo integrado

Extraer `Aplicativo_CASA_VIP_0.4.0.zip`, abrir `INICIAR_CASA_VIP.cmd` con Java 21 instalado y visitar `http://127.0.0.1:8080`. Mantener la ventana abierta; detener con Ctrl+C. La web Flutter ya está dentro del servidor y no requiere instalar Flutter o Maven para esta demostración.

Cuentas ficticias de demostración, contraseña común `CasaVIP-demo-2026!`:

| Rol | Correo |
|---|---|
| Asesor | asesor@casavip.pe |
| Responsable comercial | responsable@casavip.pe |
| Administrador | admin@casavip.pe |

Estas cuentas pertenecen al entorno demo. La base se conserva en `data/` y los archivos privados en `private-files/`, dentro de la carpeta donde se inicia el servidor.

## Conservar datos de la versión anterior

Detener el servidor, respaldar `data/` y `private-files/` y copiarlas dentro de una carpeta nueva del aplicativo 0.4.0 antes del primer inicio. Conservar el respaldo. El perfil demo aplica un esquema aditivo e inicializa instantáneas faltantes. Las condiciones finales de ventas anteriores se obtienen de la venta, conservando sus importes.

Para PostgreSQL existente en 0.3.1 aplicar `database/04_operaciones_comerciales.sql` con el servidor detenido. Para una base vacía aplicar 01, 02, 03 y 04 en orden. Configurar `DB_URL`, `DB_USER`, `DB_PASSWORD` y `PRIVATE_ROOT`, e iniciar con `--spring.profiles.active=postgres`. Este perfil no provisiona cuentas.

## Ingresar desde el celular

Para usar la web en la misma red, abrir `INICIAR_CASA_VIP_RED_LOCAL.cmd` y visitar `http://IP_DEL_EQUIPO:8080` desde el navegador del teléfono. El equipo y el teléfono deben poder comunicarse y el firewall debe permitir el puerto. La IP no aparece como campo del login.

El APK Android arm64 de depuración se obtiene desde GitHub Actions. La compilación predeterminada utiliza la API del emulador `http://10.0.2.2:8080`. Para un teléfono físico se necesita una API accesible y definirla al compilar:

```powershell
flutter build apk --debug --target-platform android-arm64 --dart-define=API_URL=http://IP_DEL_EQUIPO:8080
```

También puede configurarse la variable del repositorio `CASA_VIP_API_URL` para Actions. Retirar la dirección de la interfaz no la convierte en un secreto del binario o del tráfico. Si una instalación debug anterior tiene una firma distinta, puede ser necesario desinstalarla antes de instalar el nuevo APK; la base del servidor se conserva.

## Compilar y probar

Requisitos: JDK 21, Maven 3.9 y Flutter 3.41.9. Para Android se requiere SDK y licencias aceptadas.

En `mobile/` ejecutar `flutter pub get`, `flutter analyze`, `flutter test` y `flutter build web --release --no-web-resources-cdn`. Copiar `mobile/build/web/` a `backend/src/main/resources/static/`. En `backend/` ejecutar `mvn test package` y `mvn javadoc:javadoc`.

```powershell
java -jar target/casa-vip-backend-0.4.0.jar --app.nio2=true --spring.profiles.active=demo
```

El conector NIO2 proporciona compatibilidad con el entorno Windows utilizado. GitHub Actions ejecuta pruebas de Flutter, pruebas Java con H2 y PostgreSQL 17, compilación Android y navegador con API real. `LegacyMigrationTest` usa una base H2 independiente con esquema 0.3.1 para comprobar conservación e idempotencia.

Las pruebas PostgreSQL requieren una base aislada con los cuatro SQL y los parámetros `-Dspring.datasource.url`, `-Dspring.datasource.username`, `-Dspring.datasource.password` y `-Dspring.sql.init.mode=never`. Las pruebas limpian registros; nunca apuntarlas a una base empresarial.

## Alcance de la validación

Los resultados y enlaces de la revisión vigente se incluyen en `VERIFICACION_0_4_0.json` de la entrega y en las ejecuciones de GitHub Actions. Los artefactos requieren acceso al repositorio privado y se conservan 30 días; las fuentes permiten reproducir las compilaciones.

Los avisos globales se actualizan cada 15 segundos con la sesión abierta. Las notificaciones push con la app cerrada requieren un proveedor y credenciales adicionales. La cámara y el envío efectivo mediante WhatsApp todavía requieren prueba en un teléfono físico.

Los informes académicos 0.3.1 conservan su carácter de línea base anterior. Este incremento se documenta mediante las novedades, la matriz funcional, las fuentes y las nuevas evidencias, sin atribuir resultados nuevos a capturas anteriores.

Estudiante: Lopez Huaman, Yori Yasser — U21231292. Trabajo con asistencia de IA, sujeto a revisión y sustentación del estudiante.
