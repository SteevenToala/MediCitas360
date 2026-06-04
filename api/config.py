import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    # Supabase PostgreSQL Database Settings
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_PORT = os.getenv("DB_PORT", "5432")
    DB_NAME = os.getenv("DB_NAME", "postgres")
    DB_USER = os.getenv("DB_USER", "postgres")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "")

    # Local SQLite Replica File
    SQLITE_DB = os.getenv("SQLITE_DB", "local_citas.db")

    # Security Token for protected routes
    API_TOKEN = os.getenv("API_TOKEN", "medicitas2026")

    # Independent Invoicing Service URL
    BILLING_SERVICE_URL = os.getenv("BILLING_SERVICE_URL", "http://localhost:5003/api/facturar")
