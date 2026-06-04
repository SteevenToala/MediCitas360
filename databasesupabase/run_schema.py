import os
import psycopg
from dotenv import load_dotenv

# Load database credentials from .env file
load_dotenv()

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "postgres")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")

def run_sql_file():
    if not all([DB_HOST, DB_USER, DB_PASSWORD]):
        print("Error: Credenciales de base de datos incompletas en el archivo .env")
        return
        
    conn_str = f"host={DB_HOST} port={DB_PORT} dbname={DB_NAME} user={DB_USER} password={DB_PASSWORD}"
    print(f"Conectando a Supabase ({DB_HOST})...")
    try:
        with psycopg.connect(conn_str) as conn:
            with conn.cursor() as cur:
                print("Leyendo database.sql...")
                with open("database.sql", "r", encoding="utf-8") as f:
                    sql = f.read()
                
                print("Ejecutando script SQL...")
                cur.execute(sql)
                conn.commit()
                print("¡Tablas y datos iniciales creados exitosamente en Supabase!")
    except Exception as e:
        print(f"Error al ejecutar el script de base de datos: {e}")

if __name__ == "__main__":
    run_sql_file()
