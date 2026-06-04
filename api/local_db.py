import sqlite3
import os
from config import Config

def get_local_connection():
    """
    Creates and returns a connection to the local SQLite database.
    """
    db_path = os.path.join(os.path.dirname(__file__), Config.SQLITE_DB)
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn

def init_local_db():
    """
    Initializes the local SQLite database and creates the necessary tables.
    """
    conn = get_local_connection()
    cursor = conn.cursor()
    
    # Create tables locally to match Supabase's citas table schema
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS citas (
            id INTEGER PRIMARY KEY,
            paciente TEXT NOT NULL,
            cedula TEXT NOT NULL,
            medico_id INTEGER NOT NULL,
            fecha TEXT NOT NULL,
            hora TEXT NOT NULL,
            valor_pagar REAL NOT NULL,
            estado TEXT DEFAULT 'PENDIENTE',
            codigo_pago TEXT UNIQUE,
            fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    """)
    
    # Create local facturas table to store replicas of invoices as well
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS facturas (
            id INTEGER PRIMARY KEY,
            cita_id INTEGER NOT NULL,
            paciente TEXT NOT NULL,
            total REAL NOT NULL,
            estado TEXT DEFAULT 'GENERADA',
            clave_acceso TEXT UNIQUE,
            fecha_generacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (cita_id) REFERENCES citas (id)
        );
    """)
    
    conn.commit()
    conn.close()
    print("Base de datos SQLite local inicializada correctamente.")

def insert_cita_local(cita_data):
    """
    Inserts an appointment directly into the local SQLite database (Option A).
    """
    conn = get_local_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            INSERT OR REPLACE INTO citas (id, paciente, cedula, medico_id, fecha, hora, valor_pagar, estado, codigo_pago)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            cita_data.get("id"),
            cita_data.get("paciente"),
            cita_data.get("cedula"),
            cita_data.get("medico_id"),
            str(cita_data.get("fecha")),
            str(cita_data.get("hora")),
            float(cita_data.get("valor_pagar")),
            cita_data.get("estado", "PENDIENTE"),
            cita_data.get("codigo_pago")
        ))
        conn.commit()
        print(f"Cita {cita_data.get('id')} guardada en la replica SQLite local.")
    except Exception as e:
        print(f"Error al guardar la cita en la replica local SQLite: {e}")
    finally:
        conn.close()

def insert_factura_local(factura_data):
    """
    Inserts an invoice directly into the local SQLite database.
    """
    conn = get_local_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            INSERT OR REPLACE INTO facturas (id, cita_id, paciente, total, estado, clave_acceso)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            factura_data.get("id"),
            factura_data.get("cita_id"),
            factura_data.get("paciente"),
            float(factura_data.get("total")),
            factura_data.get("estado", "GENERADA"),
            factura_data.get("clave_acceso")
        ))
        conn.commit()
        print(f"Factura {factura_data.get('clave_acceso')} guardada en la replica SQLite local.")
    except Exception as e:
        print(f"Error al guardar la factura en la replica local SQLite: {e}")
    finally:
        conn.close()
