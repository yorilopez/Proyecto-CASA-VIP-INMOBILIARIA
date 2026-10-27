# CASA VIP · Avance de proyecto 3

Piloto académico SHENNAN HOUSE. Interfaz Flutter conectada a una API Java 21 / Spring Boot y persistencia JDBC. Conserva el prototipo del avance 2.

## Alcance comprobado

- 14 pantallas y recorrido de separación confirmado mediante la API real.
- 29 de 33 requisitos completos (87,9 % por conteo sin ponderación). RF-07, RF-27 y RF-32 parciales, RF-12 pendiente.
- 26 casos Java aprobados con H2 y con PostgreSQL 17.6; cinco casos Flutter aprobados. Son 31 casos únicos y 57 ejecuciones.
- Análisis Flutter sin incidencias y compilación web correcta.
- Seguridad por rol, aislamiento entre asesores, sesiones con vencimiento y archivos privados.
- Reservas, liberaciones, reasignaciones y ventas con transacciones e historial.

## Estructura

- backend: API Java, reglas, DAO, seguridad y pruebas.
- mobile: fuentes Flutter para web y Android.
- database: esquema original de 15 tablas y ampliación del avance 3.
- docs: arquitectura, API, instrucciones y Javadoc.
- evidence: registros y capturas con datos ficticios.

## Demostración integrada

El paquete Aplicativo_CASA_VIP incluye casa-vip-backend-0.3.0.jar e INICIAR_CASA_VIP.cmd. Se necesita Java 21 instalado. Abrir el iniciador y visitar http://127.0.0.1:8080. Mantener la ventana del servidor abierta y detenerla con Ctrl+C.

El ejecutable incorpora la API y la versión web Flutter. No se requiere Maven ni Flutter para ejecutar ese paquete. El código fuente del repositorio requiere compilar la web antes de empaquetar la API.

Cuentas de demostración, contraseña común CasaVIP-demo-2026!:

| Rol | Correo |
| --- | --- |
| Asesor | asesor@casavip.pe |
| Responsable comercial | responsable@casavip.pe |
| Administrador | admin@casavip.pe |

La base H2 se guarda en data/ con escritura inmediata (WRITE_DELAY=0), y las imágenes privadas en private-files/, dentro de la carpeta de ejecución. Las cuentas y los clientes son ficticios. La aplicación escucha en la interfaz local de manera predeterminada. No usar estas credenciales en un entorno compartido.

## Construir desde fuentes

Requisitos: JDK 21, Maven 3.9, Flutter 3.41.9. Para Android: SDK compatible, licencias aceptadas y dispositivo o emulador.

En mobile:
1. flutter pub get
2. flutter analyze
3. flutter test
4. flutter build web --release

Copiar el contenido de mobile/build/web/ a backend/src/main/resources/static/. En backend ejecutar mvn test package. El archivo resultante es target/casa-vip-backend-0.3.0.jar. Para iniciar usar java -jar target/casa-vip-backend-0.3.0.jar --app.nio2=true.

El conector NIO2 es una opción de compatibilidad para el entorno Windows de Codex. No cambia el contrato HTTP ni las reglas del sistema.

## PostgreSQL

Crear una base vacía y aplicar database/01_esquema_avance2.sql y luego database/02_ampliacion_avance3.sql. Definir DB_URL (jdbc:postgresql://host:puerto/base), DB_USER y DB_PASSWORD. Iniciar con --spring.profiles.active=postgres. El perfil postgres no inserta usuarios ni datos ficticios; estos deben provisionarse expresamente y las contraseñas deben estar codificadas con BCrypt.

No copiar data/ de H2 a PostgreSQL. Los documentos se guardan fuera de la base en PRIVATE_ROOT. Configurar HTTPS, respaldos y credenciales antes de un despliegue compartido.

## Android

Desde mobile ejecutar flutter build apk --debug --target-platform android-arm64. GitHub Actions también contiene una compilación Linux reproducible. El APK debug es para revisión académica, no para publicar en una tienda.

En el emulador, la API predeterminada es http://10.0.2.2:8080. En un teléfono se necesita una API accesible desde su red y definir su dirección en Conexión. El servidor local predeterminado no se expone a la red. Una compilación no reemplaza la validación de selección de imágenes y compartición en un dispositivo real.

## Verificación reproducible

En backend: mvn test. Para repetir la suite con PostgreSQL, preparar una base de pruebas aislada y aplicar los dos SQL. Ejecutar mvn test con los parámetros -Dspring.datasource.url=jdbc:postgresql://host:puerto/base_pruebas, -Dspring.datasource.username=usuario_pruebas, -Dspring.datasource.password=clave y -Dspring.sql.init.mode=never. La suite utiliza el perfil test y limpia sus tablas antes de cada caso. No usar una base real de la empresa.

En mobile: flutter test y flutter analyze. Los resultados archivados incluyen las fases roja y verde de TDD. La evidencia de navegador muestra la creación de una separación mediante la API real.

## Pendientes

Filtro independiente por etapa, campos configurables y cotitulares, correcciones administrativas avanzadas y validación Android en dispositivo. La entrega no declara validación con usuarios finales ni despliegue productivo. El manifiesto distingue artefactos compilados de puntos aún no verificados.

Estudiante: Lopez Huaman, Yori Yasser — U21231292. Trabajo elaborado con asistencia de IA y sujeto a revisión y sustentación del estudiante.
