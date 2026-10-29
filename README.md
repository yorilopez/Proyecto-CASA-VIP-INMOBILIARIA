# CASA VIP — Avance de proyecto 3 · revisión 0.3.1

Aplicación Flutter y API Java 21 / Spring Boot para el piloto académico SHENNAN HOUSE. Esta revisión reconstruye las 14 pantallas a partir del TypeScript, CSS, logotipo y capturas del prototipo aprobado del avance 2.

## Cambios de esta revisión

Se recuperaron la composición negra y dorada, los iconos de contorno, el encabezado con avatar, la navegación inferior, las tarjetas, los estados, los formularios y los cuatro pasos de separación. El acceso solo solicita correo y contraseña; la dirección del servidor se configura al compilar y no aparece en el login.

Los datos de dirección, correo, ocupación y cotitular se guardan en la API. Se pueden adjuntar las dos caras del documento de cada persona. Los planes de 12, 24, 36 y 48 meses se consultan por lote; la separación conserva el plan y sus condiciones calculadas por el servidor. La ficha y la constancia se comparten como imágenes de la propia interfaz.

El catálogo, las cantidades, las fechas y los nombres se obtienen de la base. Por ello pueden diferir de los valores ilustrativos del prototipo. Las funciones administrativas e historial siguen disponibles desde el avatar o el detalle correspondiente, según el rol.

## Demostración integrada

El paquete `Aplicativo_CASA_VIP_0.3.1.zip` incluye el servidor con la web Flutter incorporada. Requiere Java 21. Extraerlo en una carpeta y abrir `INICIAR_CASA_VIP.cmd`; ingresar a `http://127.0.0.1:8080`. Mantener abierta la ventana del servidor; detener con Ctrl+C.

Cuentas ficticias de demostración, contraseña común `CasaVIP-demo-2026!`:

| Rol | Correo |
| --- | --- |
| Asesor | asesor@casavip.pe |
| Responsable comercial | responsable@casavip.pe |
| Administrador | admin@casavip.pe |

La base H2 se conserva en `data/` y las imágenes privadas en `private-files/`, dentro de la carpeta del aplicativo. El perfil demo amplía de manera idempotente el catálogo y conserva los registros existentes. Para conservar una instalación anterior: detener el servidor, respaldar `data/` y `private-files/`, y copiar esas dos carpetas dentro de la nueva carpeta del aplicativo antes de iniciarlo. La revisión actualiza el esquema H2 al arrancar.

## Ejecución desde un celular

La web usa la API del mismo origen. Para una prueba en la misma red, el iniciador `INICIAR_CASA_VIP_RED_LOCAL.cmd` escucha en las interfaces del equipo. Abrir desde el navegador del teléfono `http://IP_DEL_EQUIPO:8080`. El teléfono y el equipo deben poder comunicarse y el firewall debe permitir el puerto. La IP se utiliza en la dirección del navegador, no en un campo del login.

El APK se descarga desde el artefacto Android de GitHub Actions indicado en `DESCARGAR_APK.url`. Es una compilación debug para Android arm64. Sin configuración adicional apunta al emulador (`http://10.0.2.2:8080`). Para un teléfono físico se debe compilar con una API accesible:

```powershell
flutter build apk --debug --target-platform android-arm64 --dart-define=API_URL=http://IP_DEL_EQUIPO:8080
```

También puede definirse la variable de repositorio `CASA_VIP_API_URL` para GitHub Actions. Esta configuración pertenece al entorno técnico. Los endpoint de una aplicación pueden inspeccionarse en el binario o el tráfico; retirarlos de la pantalla evita exponerlos en la interfaz, pero no los convierte en secretos de autenticación.

Las compilaciones de depuración pueden usar firmas diferentes entre ejecuciones. Si Android informa un conflicto de firma, desinstalar el APK de demostración anterior antes de instalar el nuevo; la base del servidor se conserva.

## Construir desde fuentes

Requisitos: JDK 21, Maven 3.9 y Flutter 3.41.9. Para Android se necesita un SDK compatible y sus licencias aceptadas.

En `mobile/` ejecutar `flutter pub get`, `flutter analyze`, `flutter test` y `flutter build web --release --no-web-resources-cdn`. Copiar `mobile/build/web/` a `backend/src/main/resources/static/`. En `backend/` ejecutar `mvn test package`.

Iniciar el resultado con:

```powershell
java -jar target/casa-vip-backend-0.3.1.jar --app.nio2=true --spring.profiles.active=demo
```

`--app.nio2=true` es una opción de compatibilidad del conector HTTP para este entorno Windows.

## PostgreSQL

Para una base nueva aplicar, en orden, los tres archivos de `database/`: `01_esquema_avance2.sql`, `02_ampliacion_avance3.sql` y `03_fidelidad_prototipo.sql`. Para una base con los dos primeros SQL, aplicar solo el tercero. La migración agrega campos y relaciones sin borrar registros.

Definir `DB_URL`, `DB_USER` y `DB_PASSWORD`, e iniciar con `--spring.profiles.active=postgres`. Este perfil no provisiona cuentas ni datos ficticios. Las contraseñas deben almacenarse como BCrypt. Las fotos se conservan en `PRIVATE_ROOT`.

## Verificación y límites

Se ejecutaron 35 casos Java con H2 y los mismos 35 con PostgreSQL 17.6, además de 11 casos Flutter: 46 casos distintos y 81 ejecuciones. Las pruebas incluyen permisos, aislamiento entre asesores, transacciones, cotitular, cuatro fotos, planes, formulario de acceso sin servidor y adaptación a 360 px. Los registros de esta revisión están en `evidence/revision_0_3_1/`.

La compilación Android y las comprobaciones de navegador se documentan en la entrega. La cámara y el envío a una instalación real de WhatsApp requieren validación en un teléfono físico; una compilación y una prueba web no sustituyen esa validación.

El informe acumulativo, la matriz y la presentación se actualizaron para 0.3.1. La matriz clasifica 30 de 33 requisitos completos (90,9 % por conteo sin ponderación); RF-12, RF-27 y RF-32 permanecen parciales. El prototipo y los archivos originales del avance 2 se conservaron.

Estudiante: Lopez Huaman, Yori Yasser — U21231292. Trabajo elaborado con asistencia de IA y sujeto a revisión y sustentación del estudiante.

La última comprobación integrada aprobó en [GitHub Actions](https://github.com/yorilopez/Proyecto-CASA-VIP-INMOBILIARIA/actions/runs/40899104478). El [APK](https://github.com/yorilopez/Proyecto-CASA-VIP-INMOBILIARIA/actions/runs/40899104478/artifacts/12907684576) y las [capturas vigentes](https://github.com/yorilopez/Proyecto-CASA-VIP-INMOBILIARIA/actions/runs/40899104478/artifacts/12908263137) se descargan por separado; requieren acceso al repositorio privado y tienen retención de 30 días. La procedencia de las capturas locales se detalla en `evidence/revision_0_3_1/LEEME_REVISION.md`.
