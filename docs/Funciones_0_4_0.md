# Matriz del incremento 0.4.0

Implementación de las solicitudes nuevas; complementa los 33 requisitos académicos de la entrega anterior.

| ID | Solicitud | Implementación | Comprobación |
|---|---|---|---|
| 01 | Máximo de caracteres en login | Flutter y API: correo 254; contraseña 64 y límite UTF-8 | Pruebas de login Java y Flutter |
| 02 | Cotitular al escoger un cliente existente | Formulario editable con selección de personas registradas | Prueba Flutter de selección y Java de vínculo |
| 03 | Eliminar clientes o cotitulares | Retiro de registro y desvinculación con historial conservado | Pruebas Java de archivo y desvinculación |
| 04 | Lotes por cliente | Proyecto, etapa, manzana, lote y estado en su ficha | Consulta autorizada de operaciones |
| 05 | Filtros de clientes | Todos, Con separación, Con venta | Prueba Flutter de filtros |
| 06 | Renombrar listado comercial | Operaciones: Todas, Separaciones, Ventas y Liberadas | Navegador con API real |
| 07 | Negociar condiciones y guardar venta aparte | Inicial/cuotas para asesor; precio para responsables; snapshots por operación | Pruebas de independencia, venta y redondeo |
| 08 | Correcciones del responsable comercial | Condiciones, cliente/cotitular, asesor, observación, monto, fecha y actualización explícita de fichas | Pruebas Java de versión, venta e históricos |
| 09 | Administrar precios e importar archivos | CSV/XLSX/JSON; vista previa, versiones, planes por lote y vendidos omitidos | Pruebas de tres formatos, atomicidad y concurrencia de versiones |
| 10 | Administrar usuarios por rol | CRUD admin; deshabilitación comercial; revocación de sesiones | Pruebas Java de permisos, alta, edición, baja y último administrador |
| 11 | Historiales comerciales | Clientes, operaciones, precios y usuarios con detalle antes/después | Auditoría transaccional y recorrido de administración |
| 12 | Compartir operación por rol | Imagen para asesor; texto y DNI para comercial/admin | Permisos Java; exportación de navegador; Android compilado |
| 13 | Notificaciones globales | Eventos persistentes, campana, lectura individual y permisos de detalle | Pruebas Java de privacidad y lectura; navegador |

La validación final se registra en el manifiesto de la entrega. La prueba física de cámara y WhatsApp está pendiente. Las notificaciones con la app cerrada requieren configurar el servicio push; los avisos dentro de la app están implementados.
