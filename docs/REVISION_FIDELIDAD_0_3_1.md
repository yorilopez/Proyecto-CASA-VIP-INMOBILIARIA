# Revisión de diseño y funciones — CASA VIP 0.3.1

Se reconstruyeron las 14 pantallas utilizando como referencia el prototipo del avance 2. Se preservaron el encabezado, avatar, navegación, tarjetas, iconos, estados, pasos de separación y composición de ficha y constancia. El acceso solo contiene correo y contraseña.

| Flujo | Comprobación |
| --- | --- |
| Acceso | Validación y errores sin dirección del servidor |
| Inicio, proyectos, manzanas y lotes | Tarjetas y filtros; cantidades reales de la API |
| Detalle | Cuatro planes por lote y condiciones consultables |
| Ficha comercial | Imagen de la interfaz exportada |
| Cliente | Nombres, DNI, teléfono, dirección, correo y ocupación persistidos |
| Cotitular | Datos reales asociados y acceso autorizado |
| Documentos | Dos fotos por persona; cuatro cuando existe cotitular |
| Separación | Plan seleccionado y monto real |
| Revisión | Resumen y aceptación explícita antes de registrar |
| Confirmación | Código, fecha y constancia con datos persistidos |
| Clientes y separaciones | Registros reales, búsqueda, tabs y permisos |

La prueba de navegador realizó una separación del lote 06 con titular, cotitular, cuatro imágenes ficticias y plan de 24 cuotas. La API conservó precio S/ 21,000, inicial S/ 3,000 y cuota S/ 750. La ficha y la constancia se descargaron como PNG. El navegador no reportó excepciones.

Se aprobaron 35 casos Java con H2 y 35 con PostgreSQL 17.6, junto con 11 casos Flutter: 46 casos distintos, 81 ejecuciones. La interfaz se verificó en 430 × 900 px y se incluyó una regresión de 360 × 800 px. Estas pruebas no reemplazan la validación de cámara y WhatsApp en un teléfono físico.

Los números, nombres, fechas y algunos textos provienen de datos reales del entorno demo y difieren de los ejemplos estáticos del prototipo. El marco redondeado del prototipo simula un teléfono; la app ocupa la pantalla disponible. Puede haber diferencias de tipografía entre renderizadores.

La base demo existente se conserva; para PostgreSQL se agrega la migración 03 sin borrar datos. El aplicativo anterior y los documentos académicos 0.3.0 permanecen como referencia histórica. El informe acumulativo de 56 páginas, los artefactos Excel y la presentación también se actualizaron. La matriz identifica 30 de 33 requisitos completos (90,9 % sin ponderación); RF-12, RF-27 y RF-32 son parciales.

Abrir COMPARAR_DISENO.html dentro del ZIP de comparación para revisar las 14 pantallas lado a lado. Las fotografías de documentos utilizadas son imágenes con la leyenda DOCUMENTO FICTICIO - PRUEBA.

## Evidencia vigente

El recorrido integrado vigente y la compilación Android aprobaron el 29 de octubre de 2026 en [GitHub Actions](https://github.com/yorilopez/Proyecto-CASA-VIP-INMOBILIARIA/actions/runs/40899104478), sobre el commit `83ac6f0369d4d7685e037aaa0fbae5ab2dea0c34`.

- [APK Android arm64](https://github.com/yorilopez/Proyecto-CASA-VIP-INMOBILIARIA/actions/runs/40899104478/artifacts/12907684576): compilación de depuración; sin prueba en teléfono físico.
- [Capturas y resultado del navegador de la revisión vigente](https://github.com/yorilopez/Proyecto-CASA-VIP-INMOBILIARIA/actions/runs/40899104478/artifacts/12908263137).
- `ci_web_20261029.txt`, `ci_android_20261029.txt` y `ci_web_verificacion.json` conservan los registros de esta ejecución. El flujo recorre las 14 pantallas con API real, titular, cotitular, cuatro imágenes ficticias, plan de 24 cuotas y descarga de ficha y constancia.

Las imágenes de `screens/` y la comparación HTML se obtuvieron el 27 de octubre en una ejecución real anterior de la misma revisión. La versión vigente agrega la etapa a la ficha comercial (RF-30); las capturas locales anteriores no incluyen ese último texto. Las capturas vigentes se encuentran en el artefacto de navegador enlazado arriba. Los documentos académicos usan las capturas locales con esa limitación.

Las suites registran 35 casos Java repetidos en H2 y PostgreSQL 17.6 y 11 casos Flutter: 46 casos distintos y 81 ejecuciones. El navegador y la actualización de la base se comprueban por separado. La cámara y el envío efectivo por WhatsApp en teléfono físico siguen pendientes de validación.

Los artefactos de Actions tienen retención de 30 días y requieren acceso al repositorio privado. Las fuentes y el procedimiento de compilación se incluyen en la entrega para reproducirlos.
