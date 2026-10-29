-- Índices aditivos. Se conservan tablas, datos y contratos de las versiones anteriores.
CREATE INDEX IF NOT EXISTS ix_cliente_asesor_fecha ON cliente(asesor_id,fecha_registro);
CREATE INDEX IF NOT EXISTS ix_cliente_fecha ON cliente(fecha_registro);
CREATE INDEX IF NOT EXISTS ix_venta_fecha ON venta(fecha_venta);
CREATE INDEX IF NOT EXISTS ix_auditoria_usuario_fecha ON auditoria_comercial(usuario_id,fecha);
CREATE INDEX IF NOT EXISTS ix_auditoria_entidad_fecha ON auditoria_comercial(entidad,fecha);
CREATE INDEX IF NOT EXISTS ix_historial_separacion_fecha ON historial_lote(separacion_id,fecha_cambio);
