-- Migración aditiva e idempotente de 0.5.0 a 0.6.0.
ALTER TABLE separacion ADD COLUMN IF NOT EXISTS plazo_dias INTEGER;
ALTER TABLE separacion ADD COLUMN IF NOT EXISTS fecha_vencimiento TIMESTAMP WITH TIME ZONE;
ALTER TABLE separacion ADD COLUMN IF NOT EXISTS vencimiento_avisado TIMESTAMP WITH TIME ZONE;
UPDATE separacion SET plazo_dias=CASE WHEN monto=100 THEN 3 WHEN monto=200 THEN 5 WHEN monto=500 THEN 14 ELSE NULL END WHERE plazo_dias IS NULL;
UPDATE separacion SET fecha_vencimiento=fecha_registro + (plazo_dias * interval '1' day) WHERE fecha_vencimiento IS NULL AND plazo_dias IS NOT NULL;
CREATE INDEX IF NOT EXISTS ix_separacion_vencimiento ON separacion(estado,fecha_vencimiento);
CREATE INDEX IF NOT EXISTS ix_auditoria_accion_fecha ON auditoria_comercial(accion,fecha);

ALTER TABLE notificacion ADD COLUMN IF NOT EXISTS vencimiento_referencia TIMESTAMP WITH TIME ZONE;
