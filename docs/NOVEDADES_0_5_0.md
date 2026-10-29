# CASA VIP 0.5.0

La revisión conserva las pantallas del prototipo aprobado y añade consultas mensuales, clientes potenciales y presentación visual de las operaciones y sus cambios.

## Interfaz

El logo mantiene sus proporciones y el encuadre muestra el símbolo y las letras. El inicio de sesión solicita correo y contraseña. Se retiran explicaciones técnicas y mensajes repetitivos de las pantallas, conservando las instrucciones de documentos y las confirmaciones necesarias.

Clientes utiliza un selector: todos, potenciales, con separación y con venta. Potencial significa que la persona no tiene separaciones activas ni ventas; una operación liberada no impide que vuelva a esta categoría. Una persona con varias operaciones puede aparecer tanto en separación como en venta. El cotitular también cuenta para esta clasificación.

Operaciones reúne todas, separaciones, ventas y liberadas en el botón de filtro. Las fichas ordenan proyecto, lote, personas, condiciones, asesor y fechas. La imagen compartida utiliza esa ficha y el envío textual mantiene un formato sencillo, con los permisos de la versión anterior.

El historial permite combinar tipo, usuario y mes. Incluye usuarios retirados que tienen registros históricos. Cada cambio muestra responsable, fecha, motivo y valores anterior y nuevo mediante campos legibles, sin presentar JSON ni rutas privadas.

## Períodos

Las listas abren el mes actual según America/Lima. Se puede seleccionar mes y año desde 1900 o todos los períodos. Clientes filtra por fecha de registro; separaciones activas por fecha de separación; ventas por fecha de venta; liberadas por fecha de liberación; auditoría por fecha del cambio. Los estados reflejan la situación actual de los registros, no reconstruyen el saldo histórico al cierre de cada mes.

Los límites son inclusivo al inicio y exclusivo al siguiente mes. Una separación antigua vendida este mes aparece al consultar las ventas de este mes. La fecha antigua de una liberada que carece de historial se toma de su registro, sin inventar un movimiento nuevo. El buscador se combina con el período y los indicadores de Operaciones corresponden al filtro aplicado.

## Organización y consultas

CommercialQueries concentra las lecturas parametrizadas. Se reemplaza la búsqueda repetida de operaciones por cliente por una agrupación en memoria. El perfil individual consulta únicamente las operaciones vinculadas a esa persona. Las listas no transportan las instantáneas completas de cada operación. El controlador Flutter consulta recursos independientes en paralelo y descarta respuestas antiguas de filtros anteriores.

listing_filter.dart concentra períodos, etiquetas y parámetros, y listing_ui.dart reúne filtros y fichas. El texto para compartir y la presentación de pantalla tienen funciones distintas. No se afirma una mejora porcentual de rendimiento sin medición.

## Base de datos y conservación

La base actual tiene 20 tablas. database/05_filtros_mensuales.sql añade seis índices sobre clientes, ventas, auditoría e historial. No agrega columnas ni modifica registros. Una instalación PostgreSQL 0.4.0 aplica solo 05 con el servidor detenido; una base vacía aplica 01 a 05. H2 aplica el esquema aditivo al arrancar. Se mantienen las condiciones negociadas y las instantáneas/documentos de operaciones anteriores.

## Demostración ampliada

MIRADOR DEL SOL DEMO añade 30 titulares y seis cotitulares, 18 lotes y 18 operaciones de seis meses: seis activas, seis vendidas y seis liberadas. Incluye dos asesores, administrador y responsable comercial en el historial. Con la base demo original hay 38 personas y 20 operaciones. Las fechas se calculan respecto del mes del primer inicio y se conservan después.

La carga se ejecuta solo en el perfil demo, una vez por proyecto y dentro de una transacción. No cambia las operaciones anteriores. app.demo-expanded=false permite omitirla. El perfil postgres no carga datos ficticios. Las personas nuevas no incorporan fotografías reales ni simulan una comprobación de identidad.

## Documentación y límites

El Word conserva su estructura acumulativa con cambios puntuales. La presentación tiene diez diapositivas y un guion de diez minutos que relaciona arquitectura, TDD, DAO, SOLID, seguridad, cuatro bibliotecas Java, Git/GitHub, interfaces y producto. El CSV Trazabilidad_AP3_0_5_0.csv actualiza RF-27: 31 de 33 completos, 93,9 % por conteo sin ponderación. RF-12 y RF-32 siguen parciales. El Excel de la versión 0.3.1 conserva su carácter de línea base anterior.

Los resultados reproducibles, sus ejecuciones y la procedencia de binarios figuran en el manifiesto de la entrega. Cámara y envío efectivo a WhatsApp requieren prueba física. Las notificaciones globales funcionan con la sesión abierta; el envío push con la app cerrada requiere configurar un proveedor.
