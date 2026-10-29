# CASA VIP 0.4.0 — ampliación comercial

Esta versión amplía el aplicativo 0.3.1 conservando la composición visual del prototipo aprobado. Los informes académicos de 0.3.1 describen la entrega anterior; este documento y la matriz `Funciones_0_4_0.md` documentan el incremento solicitado el 29 de octubre de 2026.

## Acceso y permisos

El login admite hasta 254 caracteres de correo y 64 de contraseña. También se valida el máximo de 72 bytes UTF-8 que admite el mecanismo BCrypt utilizado. Los campos muestran su límite y rechazan el exceso; la interfaz no recorta ni modifica la contraseña. Las cuentas nuevas requieren como mínimo ocho caracteres.

| Función | Asesor | Responsable comercial | Administrador |
|---|---|---|---|
| Clientes y cotitulares | Propios | Todos | Todos |
| Operaciones y sus detalles | Propias | Todas | Todas |
| Inicial y cuotas al separar | Sí | Sí | Sí |
| Cambiar precio acordado | No | Sí | Sí |
| Corregir operaciones y ventas guardadas | No | Sí, con motivo e historial | Sí, con motivo e historial |
| Catálogo e importaciones | No | No | Sí |
| Consultar usuarios | No | Sí | Sí |
| Crear, editar, habilitar o eliminar usuarios | No | No | Sí |
| Deshabilitar usuarios | No | Sí | Sí |
| Historiales generales | No | Sí | Sí |
| Compartir operación como imagen | Propias | Todas | Todas |
| Compartir texto y DNI de una operación | No | Sí | Sí |
| Notificaciones generales | Sí | Sí | Sí |

Las autorizaciones se comprueban en el servidor. Deshabilitar o eliminar un usuario revoca sus sesiones. Se conserva al menos un administrador activo. La eliminación de cuentas y clientes retira el registro del uso habitual y conserva las referencias históricas de sus operaciones.

## Clientes y cotitulares

El formulario permite seleccionar un cliente registrado y completar o agregar su cotitular antes de continuar. También se puede seleccionar un cotitular ya registrado en la cartera correspondiente. Se admite un cotitular vigente por titular; cambiarlo no cambia el cotitular de operaciones anteriores.

La cartera dispone de Todos, Con separación y Con venta. Un cliente puede aparecer en los dos últimos filtros cuando tenga ambos tipos de operación. Su ficha muestra proyecto, etapa, manzana y lote de cada operación, con acceso al detalle permitido.

Desde la ficha se puede editar, desvincular el cotitular, retirar el registro del cotitular o retirar el cliente. Los documentos vinculados a una operación se conservan aunque posteriormente se sustituya una fotografía en la ficha de la persona.

## Operaciones, condiciones y ventas

La navegación antes llamada Separaciones se llama Operaciones y tiene filtros Todas, Separaciones, Ventas y Liberadas. Incluye búsqueda por proyecto, lote o cliente.

La inicial y el número de cuotas se pueden negociar al separar. El precio de catálogo se conserva para el asesor; el responsable comercial y el administrador pueden negociar el precio. El cálculo no añade intereses. Se trabaja en céntimos enteros en Flutter y con decimales en Java; la última cuota absorbe el residuo del reparto para que todas las cuotas sumen exactamente el saldo.

Se guarda una instantánea de datos, documentos y condiciones de cada operación. Una publicación posterior del catálogo no modifica esa instantánea. Al vender se parte de las condiciones de la separación y se guardan las condiciones finales en venta, sin escribir el precio del catálogo. Al liberar se desactivan las condiciones particulares; el lote vuelve a ofrecer el catálogo vigente y se conserva el historial de la operación liberada.

Las correcciones requieren motivo y versión vigente. Dos ediciones concurrentes no se sobreescriben silenciosamente. El formulario permite cambiar condiciones, monto, observación, titular, cotitular, asesor y fecha de venta. Conserva las referencias históricas de personas retiradas o usuarios deshabilitados. Para actualizar datos personales y DNI desde las fichas actuales debe marcarse expresamente esa opción; los valores anteriores quedan en auditoría.

## Catálogo de precios

Acceso del administrador: Inicio → Precios o avatar → Catálogo y precios. Cada lote muestra su ID estable. Se permite editar manualmente precio, área, ubicación y plan, o importar un archivo de hasta 5 MB y 1000 lotes.

Formatos: CSV UTF-8 separado por coma o punto y coma, Excel `.xlsx` sin fórmulas, y JSON como lista o como objeto con propiedad `lotes`. Las columnas obligatorias son `lote_id` y `precio`. Las opcionales son `area_m2`, `ubicacion`, `inicial` y `numero_cuotas`. Inicial y número de cuotas se proporcionan juntos. Los montos utilizan hasta dos decimales y no llevan símbolos monetarios ni separadores de miles.

El JSON admite `planes`, una lista de objetos con `inicial` y `numero_cuotas`, para publicar varios planes por lote. No se repite un número de cuotas dentro del mismo lote. Cuando se publica solo el precio, se conservan las iniciales y plazos de los planes y se recalculan sus mensualidades.

La edición manual publica un plan para el lote. Para mantener varios planes, se utiliza el JSON con la propiedad `planes`. Los ejemplos de `docs/plantillas/` contienen identificadores ficticios del entorno demo y deben adaptarse al catálogo de cada instalación.

La vista previa muestra precios anteriores y propuestos. Requiere un motivo para aplicar. Se validan identificadores, duplicados, montos, plazos y versiones; los errores no dejan una carga parcial. Los lotes vendidos se omiten, incluso si se vendieron después de la vista previa. Los lotes separados pueden actualizar su catálogo sin cambiar las condiciones de su operación. Los planes anteriores continúan existiendo para respaldar las operaciones que los referencian.

La importación modifica lotes existentes; no crea proyectos, manzanas ni inventario nuevo. No cambia estados comerciales desde el archivo. Cada actualización queda registrada con sus valores anteriores y nuevos.

## Historiales y compartición

El responsable comercial y el administrador acceden a historiales de clientes, operaciones, precios y usuarios. Cada entrada conserva usuario, fecha, acción, motivo y valores anteriores y actuales. El listado muestra hasta las 500 entradas más recientes por filtro.

El detalle de operación exporta una imagen con los datos guardados. Para responsable comercial y administrador también prepara texto y las fotografías de DNI guardadas en la operación. Android utiliza el selector de aplicaciones del sistema. En un navegador que admite compartir archivos se usa esa función; en otros navegadores se descargan el texto y las imágenes para adjuntarlos. Puede requerirse permitir descargas múltiples.

La información textual también es necesaria para mostrar la interfaz. La restricción de imagen para el asesor regula las funciones de compartición disponibles en la app y el acceso al endpoint de exportación de texto y documentos.

## Notificaciones globales

La campana muestra avisos persistentes de nuevas separaciones, ventas y liberaciones, con contador y lectura individual por usuario. Se consultan cada 15 segundos mientras la sesión está abierta. Los avisos generales contienen proyecto, manzana y lote; el enlace al detalle se entrega únicamente a quien puede consultar esa operación. No incluyen DNI, fotografías ni datos personales.

La inserción del aviso participa en la misma transacción que la operación, por lo que un registro fallido no genera un aviso confirmado. El historial de avisos muestra los 100 más recientes; el contador considera todos los pendientes.

Las notificaciones push con la aplicación cerrada requieren configurar un proveedor push y sus credenciales. Esta entrega implementa los avisos globales dentro de la aplicación y no declara habilitado ese servicio externo.

## Actualización de una instalación

1. Detener el servidor y respaldar `data/` y `private-files/`.
2. Extraer el aplicativo 0.4.0 en una carpeta nueva. Copiar dentro las dos carpetas respaldadas antes de iniciar.
3. Ejecutar el iniciador de 0.4.0. El perfil demo aplica el esquema aditivo e inicializa las instantáneas que faltan en registros anteriores. No emite notificaciones nuevas por esos registros históricos.
4. Para PostgreSQL ya actualizado a 0.3.1, aplicar solamente `database/04_operaciones_comerciales.sql` con el servidor detenido. Para una base nueva aplicar 01, 02, 03 y 04 en orden.

La prueba de migración utiliza una base independiente con el esquema 0.3.1, clientes, separación y venta anteriores. Comprueba conservación e idempotencia. No se ha ejecutado una migración sobre una base empresarial del usuario.

## Comprobaciones y límites

Los resultados finales, el commit compilado y los enlaces a APK y evidencias se consignan en `VERIFICACION_0_4_0.json` de la entrega. Las suites incluyen las reglas anteriores, permisos por rol, cotitular, condiciones independientes, catálogo, redondeo, usuarios, documentos históricos, correcciones y avisos. El navegador recorre el flujo base y las funciones nuevas con datos ficticios.

La selección de archivos y la compartición Android se compilan; la cámara y el envío efectivo mediante WhatsApp requieren validación en un teléfono físico. El APK predeterminado apunta al emulador; para el teléfono se necesita definir `API_URL` al compilar. El login no muestra esta configuración.
