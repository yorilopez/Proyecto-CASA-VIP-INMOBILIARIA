-- Revision de fidelidad al prototipo. Migracion aditiva e idempotente.
ALTER TABLE cliente ADD COLUMN IF NOT EXISTS direccion VARCHAR(250);
ALTER TABLE cliente ADD COLUMN IF NOT EXISTS ocupacion VARCHAR(120);
ALTER TABLE lote ADD COLUMN IF NOT EXISTS ubicacion VARCHAR(160);
ALTER TABLE usuario ADD COLUMN IF NOT EXISTS telefono VARCHAR(30);
ALTER TABLE separacion ADD COLUMN IF NOT EXISTS plan_pago_id BIGINT REFERENCES plan_pago(id);
ALTER TABLE separacion ADD COLUMN IF NOT EXISTS cotitular_id BIGINT REFERENCES cliente(id);
ALTER TABLE separacion ADD COLUMN IF NOT EXISTS precio_acordado NUMERIC(14,2);
ALTER TABLE separacion ADD COLUMN IF NOT EXISTS inicial_acordada NUMERIC(14,2);
ALTER TABLE separacion ADD COLUMN IF NOT EXISTS cuota_acordada NUMERIC(14,2);
ALTER TABLE separacion ADD COLUMN IF NOT EXISTS numero_cuotas_acordado INTEGER;
