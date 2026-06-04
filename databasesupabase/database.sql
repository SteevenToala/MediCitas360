-- ==========================================
-- MEDICITAS 360
-- Base de Datos Principal (Supabase PostgreSQL)
-- ==========================================

-- Eliminar tablas si existen

DROP TABLE IF EXISTS facturas CASCADE;
DROP TABLE IF EXISTS citas CASCADE;
DROP TABLE IF EXISTS horarios CASCADE;
DROP TABLE IF EXISTS medicos CASCADE;

-- ==========================================
-- TABLA MEDICOS
-- ==========================================

CREATE TABLE medicos (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    especialidad VARCHAR(100) NOT NULL,
    consultorio VARCHAR(50) NOT NULL,
    costo_consulta NUMERIC(10,2) NOT NULL,
    duracion_turno INTEGER NOT NULL CHECK (duracion_turno IN (30,60))
);

-- ==========================================
-- TABLA HORARIOS
-- ==========================================

CREATE TABLE horarios (
    id BIGSERIAL PRIMARY KEY,
    medico_id BIGINT NOT NULL REFERENCES medicos(id),
    fecha DATE NOT NULL,
    hora TIME NOT NULL,
    disponible BOOLEAN DEFAULT TRUE
);

-- ==========================================
-- TABLA CITAS
-- ==========================================

CREATE TABLE citas (
    id BIGSERIAL PRIMARY KEY,

    paciente VARCHAR(150) NOT NULL,
    cedula VARCHAR(20) NOT NULL,

    medico_id BIGINT NOT NULL REFERENCES medicos(id),

    fecha DATE NOT NULL,
    hora TIME NOT NULL,

    valor_pagar NUMERIC(10,2) NOT NULL,

    estado VARCHAR(20) DEFAULT 'PENDIENTE',

    codigo_pago VARCHAR(100) UNIQUE,

    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Evita doble reserva para mismo médico,
-- fecha y hora

ALTER TABLE citas
ADD CONSTRAINT uq_cita_medico_horario
UNIQUE (medico_id, fecha, hora);

-- ==========================================
-- TABLA FACTURAS
-- ==========================================

CREATE TABLE facturas (
    id BIGSERIAL PRIMARY KEY,

    cita_id BIGINT NOT NULL REFERENCES citas(id),

    paciente VARCHAR(150) NOT NULL,

    total NUMERIC(10,2) NOT NULL,

    estado VARCHAR(20) DEFAULT 'GENERADA',

    clave_acceso VARCHAR(100) UNIQUE,

    xml_generado TEXT,

    fecha_generacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- INSERT MEDICOS
-- ==========================================

INSERT INTO medicos
(nombre, especialidad, consultorio, costo_consulta, duracion_turno)
VALUES
('Dra. Ana Lopez', 'Medicina General', 'C101', 25.00, 30),
('Dr. Carlos Perez', 'Cardiologia', 'C202', 40.00, 60),
('Dra. Maria Torres', 'Pediatria', 'C303', 30.00, 30),
('Dr. Luis Gomez', 'Traumatologia', 'C404', 50.00, 60),
('Dra. Sofia Ramirez', 'Dermatologia', 'C505', 35.00, 30);

-- ==========================================
-- INSERT HORARIOS
-- ==========================================

INSERT INTO horarios
(medico_id, fecha, hora, disponible)
VALUES

-- Dra. Ana Lopez
(1,'2026-06-04','08:00',TRUE),
(1,'2026-06-04','08:30',TRUE),
(1,'2026-06-04','09:00',TRUE),
(1,'2026-06-04','09:30',TRUE),

-- Dr. Carlos Perez
(2,'2026-06-04','10:00',TRUE),
(2,'2026-06-04','11:00',TRUE),
(2,'2026-06-04','12:00',TRUE),

-- Dra. Maria Torres
(3,'2026-06-04','14:00',TRUE),
(3,'2026-06-04','14:30',TRUE),
(3,'2026-06-04','15:00',TRUE),

-- Dr. Luis Gomez
(4,'2026-06-04','16:00',TRUE),
(4,'2026-06-04','17:00',TRUE),

-- Dra. Sofia Ramirez
(5,'2026-06-04','18:00',TRUE),
(5,'2026-06-04','18:30',TRUE);

-- ==========================================
-- INSERT CITA DE PRUEBA
-- ==========================================

INSERT INTO citas
(
    paciente,
    cedula,
    medico_id,
    fecha,
    hora,
    valor_pagar,
    estado,
    codigo_pago
)
VALUES
(
    'Juan Perez',
    '1800000001',
    1,
    '2026-06-04',
    '08:00',
    25.00,
    'PENDIENTE',
    'PAGO-CITA-2026-0001'
);

-- ==========================================
-- INSERT FACTURA DE PRUEBA
-- ==========================================

INSERT INTO facturas
(
    cita_id,
    paciente,
    total,
    estado,
    clave_acceso,
    xml_generado
)
VALUES
(
    1,
    'Juan Perez',
    25.00,
    'GENERADA',
    'FAC-CITA-2026-0001',
    '<FacturaCita>
        <Paciente>Juan Perez</Paciente>
        <Cedula>1800000001</Cedula>
        <Medico>Dra. Ana Lopez</Medico>
        <Especialidad>Medicina General</Especialidad>
        <Fecha>2026-06-04</Fecha>
        <Hora>08:00</Hora>
        <Total>25.00</Total>
        <Estado>GENERADA</Estado>
        <ClaveAcceso>FAC-CITA-2026-0001</ClaveAcceso>
     </FacturaCita>'
);

-- ==========================================
-- CONSULTAS DE PRUEBA
-- ==========================================

SELECT * FROM medicos;
SELECT * FROM horarios;
SELECT * FROM citas;
SELECT * FROM facturas;