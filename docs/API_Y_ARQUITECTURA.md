# API y arquitectura de CASA VIP

Base local: http://127.0.0.1:8080/api. JSON UTF-8. La sesión se envía como Authorization: Bearer TOKEN. Los identificadores se obtienen consultando el catálogo, nunca se asumen en producción.

| Método y ruta | Propósito | Acceso |
| --- | --- | --- |
| GET /health | Estado de la API | Público |
| POST /auth/login | Crear sesión con email y password | Público |
| GET /auth/me | Obtener identidad y rol | Autenticado |
| POST /auth/logout | Revocar la sesión | Autenticado |
| GET /projects | Consultar proyectos | Autenticado |
| GET /projects/{id}/stages | Etapas del proyecto | Autenticado |
| GET /projects/{id}/blocks | Manzanas y disponibilidad | Autenticado |
| GET /lots?project=&block=&state=&q= | Consultar lotes y filtros | Autenticado |
| GET /lots/{id} | Detalle y planes de pago | Autenticado |
| GET /lots/{id}/history | Historial de estados | Autenticado |
| PATCH /lots/{id}/state | Disponible / No disponible con motivo | Administrador |
| GET /clients?q= | Clientes visibles por el usuario | Autenticado |
| GET /clients/{id} | Perfil y cotitular autorizado | Usuario autorizado sobre el cliente |
| PUT /clients/{id} | Corregir datos personales autorizados | Usuario autorizado sobre el cliente |
| POST /clients | Registrar o recuperar un cliente autorizado | Autenticado |
| GET /clients/{id}/documents | Metadatos de imágenes del documento | Usuario autorizado sobre el cliente |
| POST /clients/{id}/documents/{side} | Cargar ANVERSO o REVERSO | Usuario autorizado sobre el cliente |
| GET /documents/{id} | Descargar imagen privada | Usuario autorizado sobre el cliente |
| GET /reservations | Consultar separaciones visibles | Autenticado |
| POST /reservations | Confirmar separación | Autenticado |
| POST /reservations/{id}/release | Liberar separación con motivo | Responsable / administrador |
| POST /reservations/{id}/reassign | Cambiar lote y conservar trazabilidad | Responsable / administrador |
| POST /reservations/{id}/sale | Registrar venta | Responsable / administrador |
| GET /reports/reservations.xlsx | Exportar separaciones | Responsable / administrador |
| GET /lots/{id}/card.png | Ficha comercial sin datos personales | Autenticado |

## Solicitudes principales

Cliente: nombre, tipo_documento (DNI o CE), numero_documento, telefono, correo, proyecto_id; direccion y ocupacion opcionales. El objeto cotitular opcional contiene los datos de la segunda persona y crea una relación COTITULAR. El servicio impide vincular clientes de otro asesor.

Separación: lote_id, cliente_id, monto (mayor que cero), observacion, plan_id y cotitular_id opcionales. El plan debe pertenecer al lote; precio, inicial, cuota y plazo se congelan desde el catálogo del servidor. Un cotitular debe estar vinculado y autorizado; requiere ambas caras del DNI del titular y del cotitular. El servidor obtiene el asesor de la sesión y genera la fecha e historial.

Liberación y cambio administrativo: estado y motivo. El servicio ignora el estado para liberar y aplica la transición autorizada. No permite usar el cambio administrativo para saltar una reserva o una venta.

Reasignación: lote_id del destino y motivo. Se bloquean ambos lotes en orden de identificador. Un conflicto conserva la reserva original.

Venta: plan_id, precio, inicial, contrato_firmado y fecha (ISO YYYY-MM-DD, no futura). El plan debe pertenecer al lote y estar activo. El precio y la inicial deben ser positivos.

Carga: multipart/form-data con campo file, fotografía PNG/JPEG legible de hasta 5 MB. No se aceptan rutas proporcionadas por el cliente. Los nombres son aleatorios y la lectura requiere autorización.

## Respuestas y errores

200 para operaciones correctas. Los formularios y servicios rechazan entradas inválidas con 400. Sesión ausente o inválida: 401. Rol o cliente no autorizado: 403. Registro inexistente: 404. Conflicto de disponibilidad o integridad: 409. Carga excesiva: 413.

Los textos de error no incluyen trazas internas. La aplicación interpreta los mensajes para informar al usuario y borra la sesión local ante 401.

## Diseño implementado

La vista Flutter delega la navegación en CasaController y el acceso HTTP en ApiClient. ApiController valida entradas y delega a servicios. CommercialService combina BusinessRules y CommercialDao dentro de transacciones. JdbcCommercialDao parametriza SQL. AuthService, DocumentService y ReportService mantienen responsabilidades separadas.

La implementación muestra responsabilidad única e inversión de dependencias. La interfaz DAO del piloto todavía puede dividirse en contratos más pequeños. El esquema de 15 tablas del avance 2 se amplía con sesion y columnas de asociación y venta. Los scripts no deben aplicarse sobre una base existente sin un respaldo y un proceso de migración.

Ver docs/javadoc/index.html para las clases y docs/diagrams para las fuentes editables de arquitectura y estados.
