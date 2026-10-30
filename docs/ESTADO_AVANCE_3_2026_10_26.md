# Estado del Avance 3 de CASA VIP

Fecha de trabajo: 26 de octubre de 2026, hora de Lima.

La ejecución quedó interrumpida por la desconexión del entorno local. Este archivo es un punto de continuidad; no constituye la entrega final del avance.

## Ubicación del trabajo

El código nuevo y las evidencias se guardaron en:

`C:\Users\LAPTOP-YORI\.codex\.chatgpt-projects\g-p-6ab804ca84d08191848aac345f882d9f\avance3_work\repository`

La carpeta de trabajo completa es su carpeta superior `avance3_work`. Contiene los generadores utilizados, referencias extraídas, compilaciones, cachés y herramientas aisladas. No es necesario volver a desarrollar lo implementado.

Carpeta de entrega solicitada:

`D:\almacenamiento-nube\012-UNIVERSIDAD\CURSO INTEGRADOR I, SISTEMAS - SOFTWARE\sem 12 - informe avance proy 3`

Fuentes originales: los resúmenes Markdown del curso, el informe y el prototipo del avance 2, y la rúbrica original PDF de la semana 12.

## Implementación local

- Flutter con las 14 pantallas del prototipo y su línea visual negra y dorada.
- API Java 21 y Spring Boot 3.5.16 con controladores, servicios y DAO JDBC.
- Autenticación con BCrypt, sesiones opacas con expiración y hash del token, permisos por rol y límite de intentos fallidos.
- Catálogo de proyectos, etapas, manzanas, lotes y planes.
- Registro, búsqueda y reutilización de clientes según permisos.
- Separación transaccional, bloqueo de filas y prevención de reservas duplicadas.
- Liberación, reasignación, venta y cambios administrativos controlados con historial.
- Fotografías privadas PNG/JPEG, validación del contenido y lectura autorizada.
- Reportes Excel con Apache POI y ficha comercial PNG sin datos de clientes.
- Guava, Apache Commons y Logback utilizados en funciones reales.
- Esquema PostgreSQL del avance 2 conservado y ampliación del avance 3 separada.
- Perfil de demostración H2 y configuración PostgreSQL.
- Adaptadores de archivos para navegador y Android.

Los campos adicionales de cliente configurables por proyecto requieren todavía revisar el alcance. La corrección administrativa se limita a transiciones seguras; no permite alterar arbitrariamente reservas o ventas.

## Verificación realizada antes de la desconexión

| Verificación | Resultado confirmado |
|---|---|
| Suite Java inicial con H2 | 24 pruebas, 0 fallos, 0 errores |
| La misma suite con PostgreSQL 17.6 real y aislado | 24 pruebas, 0 fallos, 0 errores |
| Flutter | 5 pruebas aprobadas |
| Compilación Flutter para navegador | Completada |
| TDD | Fase roja y fase verde registradas |

Las 24 pruebas incluyen concurrencia sobre el mismo lote, permisos, estados, reasignación, venta, documentos privados y exportación. Las cinco pruebas Flutter incluyen el recorrido desde inicio de sesión hasta confirmación de separación, validación del formulario, error de autenticación y revocación del token.

Después de esos resultados se añadieron dos pruebas Java adicionales sobre aislamiento entre asesores y vencimiento de sesión. Esas dos pruebas todavía no tienen un resultado confirmado.

El análisis Flutter más reciente mostraba únicamente una observación de estilo en una prueba. Se aplicó la corrección, pero queda pendiente conservar el resultado de un nuevo análisis limpio.

## Pendientes para cerrar la entrega

1. Recuperar la conexión al entorno y comprobar el contenido de la carpeta local.
2. Ejecutar las dos pruebas Java añadidas y guardar los resultados finales de H2 y PostgreSQL.
3. Conservar el análisis final de Flutter sin incidencias.
4. Revisar visualmente las pantallas y guardar capturas.
5. Empaquetar la compilación Flutter junto con la API en un ejecutable Java.
6. Comprobar la compilación Android. No hay APK final confirmado.
7. Generar Javadoc y diagramas coherentes con el código final.
8. Actualizar el informe acumulativo Word a partir del avance 2, conservar sus secciones aprobadas y verificar la maquetación.
9. Actualizar el Excel de artefactos con trazabilidad, alcance y resultados.
10. Preparar presentación y guion de aproximadamente diez minutos.
11. Publicar la implementación completa y sus evidencias en GitHub. Hasta este punto, el repositorio remoto contiene la definición inicial de pruebas y este registro; la implementación completa sigue en la carpeta local.
12. Empaquetar, verificar, guardar y copiar los entregables a la carpeta solicitada.

Se preparó una instancia PostgreSQL exclusiva de pruebas en `avance3_work\cache\pg-data`, con puerto local 55432. Antes de iniciar otra instancia o cerrarla, comprobar su estado y que corresponda a esta carpeta.

## Autoría y continuidad

La implementación se realizó con asistencia de IA. No se atribuyeron colaboraciones o validaciones a integrantes inexistentes. El estudiante debe revisar y dominar el código para la sustentación.

La desconexión impide acceder a los archivos locales y terminar el empaquetado. No se ha declarado concluida la entrega.
