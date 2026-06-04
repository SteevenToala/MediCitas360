import os
import requests
import io
import base64
import qrcode
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv

from config import Config
from database import get_db_connection
from local_db import init_local_db, get_local_connection, insert_cita_local, insert_factura_local

load_dotenv()

app = Flask(__name__)
app.url_map.strict_slashes = False
CORS(app)

# Initialize local SQLite database
init_local_db()

# ==========================================
# TOKEN AUTHENTICATION HELPER
# ==========================================
def verify_token():
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return False
    
    # Check if header starts with "Bearer "
    parts = auth_header.split(" ")
    if len(parts) != 2 or parts[0].lower() != "bearer":
        return False
    
    token = parts[1]
    return token == Config.API_TOKEN

def require_token(f):
    from functools import wraps
    @wraps(f)
    def decorated(*args, **kwargs):
        if not verify_token():
            return jsonify({"error": "Token no válido o no autorizado"}), 401
        return f(*args, **kwargs)
    return decorated

# ==========================================
# HELPER: QR CODE GENERATOR
# ==========================================
def get_qr_base64(text_data):
    try:
        qr = qrcode.QRCode(version=1, box_size=5, border=2)
        qr.add_data(text_data)
        qr.make(fit=True)
        img = qr.make_image(fill_color="black", back_color="white")
        buffered = io.BytesIO()
        img.save(buffered, format="PNG")
        return base64.b64encode(buffered.getvalue()).decode("utf-8")
    except Exception as e:
        print(f"Error generando QR code: {e}")
        return ""

# ==========================================
# ROUTES
# ==========================================

@app.route("/")
def index():
    return jsonify({
        "success": True,
        "api": "API REST MediCitas 360",
        "endpoints": [
            "/api/medicos",
            "/api/medicos/{id}",
            "/api/medicos/{id}/horarios",
            "/api/citas",
            "/api/sincronizar"
        ]
    })

# 1. GET /api/medicos - Get all doctors
@app.route("/api/medicos", methods=["GET"])
def get_medicos():
    conn = get_db_connection()
    if conn is None:
        return jsonify({"error": "No se pudo conectar a la base de datos Supabase"}), 500
    
    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute("SELECT * FROM medicos ORDER BY id;")
                medicos = cur.fetchall()
                # Format Numeric / Decimal values to float for JSON compatibility
                for m in medicos:
                    m["costo_consulta"] = float(m["costo_consulta"])
                return jsonify(medicos)
    except Exception as e:
        return jsonify({"error": f"Error al obtener medicos: {str(e)}"}), 500

# 2. GET /api/medicos/{id} - Get a single doctor
@app.route("/api/medicos/<int:medico_id>", methods=["GET"])
def get_medico(medico_id):
    conn = get_db_connection()
    if conn is None:
        return jsonify({"error": "No se pudo conectar a la base de datos Supabase"}), 500
    
    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute("SELECT * FROM medicos WHERE id = %s;", (medico_id,))
                medico = cur.fetchone()
                if not medico:
                    return jsonify({"error": "Médico no encontrado"}), 404
                medico["costo_consulta"] = float(medico["costo_consulta"])
                return jsonify(medico)
    except Exception as e:
        return jsonify({"error": f"Error al obtener médico: {str(e)}"}), 500

# 3. GET /api/medicos/{id}/horarios - Get schedules for a doctor
@app.route("/api/medicos/<int:medico_id>/horarios", methods=["GET"])
def get_horarios(medico_id):
    conn = get_db_connection()
    if conn is None:
        return jsonify({"error": "No se pudo conectar a la base de datos Supabase"}), 500
    
    try:
        with conn:
            with conn.cursor() as cur:
                # Check if doctor exists first
                cur.execute("SELECT id FROM medicos WHERE id = %s;", (medico_id,))
                if not cur.fetchone():
                    return jsonify({"error": "Médico no encontrado"}), 404
                
                # Fetch schedules
                cur.execute("""
                    SELECT fecha, hora, disponible 
                    FROM horarios 
                    WHERE medico_id = %s 
                    ORDER BY fecha, hora;
                """, (medico_id,))
                horarios = cur.fetchall()
                
                # Format DATE and TIME to strings for clean JSON output
                formatted_horarios = []
                for h in horarios:
                    formatted_horarios.append({
                        "fecha": h["fecha"].strftime("%Y-%m-%d"),
                        "hora": h["hora"].strftime("%H:%M"),
                        "disponible": h["disponible"]
                    })
                return jsonify(formatted_horarios)
    except Exception as e:
        return jsonify({"error": f"Error al obtener horarios: {str(e)}"}), 500

# 4. POST /api/citas - Book an appointment (Protected)
@app.route("/api/citas", methods=["POST"])
@require_token
def create_cita():
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Datos de cita no proporcionados o vacíos"}), 400

    paciente = data.get("paciente", "").strip()
    cedula = data.get("cedula", "").strip()
    medico_id = data.get("medico_id")
    fecha = data.get("fecha", "").strip()
    hora = data.get("hora", "").strip()

    # Validations
    if not paciente:
        return jsonify({"error": "El nombre del paciente es obligatorio"}), 400
    if not cedula:
        return jsonify({"error": "La cédula del paciente es obligatoria"}), 400
    if not medico_id:
        return jsonify({"error": "El ID del médico es obligatorio"}), 400
    if not fecha or not hora:
        return jsonify({"error": "La fecha y la hora no pueden estar vacías"}), 400

    conn = get_db_connection()
    if conn is None:
        return jsonify({"error": "No se pudo conectar a la base de datos principal Supabase"}), 500

    try:
        with conn:
            with conn.cursor() as cur:
                # 1. Check if doctor exists and get details
                cur.execute("SELECT nombre, especialidad, costo_consulta FROM medicos WHERE id = %s;", (medico_id,))
                medico = cur.fetchone()
                if not medico:
                    return jsonify({"error": "El médico especificado no existe"}), 404
                
                costo_consulta = float(medico["costo_consulta"])
                nombre_medico = medico["nombre"]
                especialidad_medico = medico["especialidad"]

                # 2. Check if the schedule exists and is available
                cur.execute("""
                    SELECT disponible 
                    FROM horarios 
                    WHERE medico_id = %s AND fecha = %s AND hora = %s;
                """, (medico_id, fecha, hora))
                horario = cur.fetchone()
                
                if not horario:
                    return jsonify({"error": "El horario especificado no existe para este médico"}), 400
                if not horario["disponible"]:
                    return jsonify({"error": "El médico ya tiene una cita registrada en ese horario"}), 400

                # 3. Check if there's already a citation in 'citas' for safety
                cur.execute("""
                    SELECT id 
                    FROM citas 
                    WHERE medico_id = %s AND fecha = %s AND hora = %s;
                """, (medico_id, fecha, hora))
                if cur.fetchone():
                    return jsonify({"error": "El médico ya tiene una cita registrada en ese horario"}), 400

                # 4. Insert citation into Supabase (status is PENDIENTE)
                # First insert without codigo_pago to get the ID, or with temporary code
                cur.execute("""
                    INSERT INTO citas (paciente, cedula, medico_id, fecha, hora, valor_pagar, estado)
                    VALUES (%s, %s, %s, %s, %s, %s, 'PENDIENTE')
                    RETURNING id;
                """, (paciente, cedula, medico_id, fecha, hora, costo_consulta))
                cita_id = cur.fetchone()["id"]

                # Construct unique payment code and access key
                codigo_pago = f"PAGO-CITA-2026-{cita_id:04d}"
                
                # Update citation with payment code
                cur.execute("""
                    UPDATE citas SET codigo_pago = %s WHERE id = %s;
                """, (codigo_pago, cita_id))

                # 5. Set schedule available = FALSE in Supabase
                cur.execute("""
                    UPDATE horarios 
                    SET disponible = FALSE 
                    WHERE medico_id = %s AND fecha = %s AND hora = %s;
                """, (medico_id, fecha, hora))

                # Commit Supabase transaction so far to ensure IDs and constraints
                conn.commit()

                # 6. Save to local SQLite replica (Option A)
                local_cita = {
                    "id": cita_id,
                    "paciente": paciente,
                    "cedula": cedula,
                    "medico_id": medico_id,
                    "fecha": fecha,
                    "hora": hora,
                    "valor_pagar": costo_consulta,
                    "estado": "PENDIENTE",
                    "codigo_pago": codigo_pago
                }
                insert_cita_local(local_cita)

                # 7. Call the independent SOAP/REST Invoicing XML Service
                clave_acceso = ""
                xml_generado = ""
                try:
                    invoice_payload = {
                        "cita_id": cita_id,
                        "paciente": paciente,
                        "cedula": cedula,
                        "medico": nombre_medico,
                        "especialidad": especialidad_medico,
                        "fecha": fecha,
                        "hora": hora,
                        "total": costo_consulta
                    }
                    
                    bill_res = requests.post(Config.BILLING_SERVICE_URL, json=invoice_payload, timeout=5)
                    if bill_res.status_code == 200:
                        bill_data = bill_res.json()
                        clave_acceso = bill_data.get("clave_acceso")
                        xml_generado = bill_data.get("xml")
                        print(f"Factura generada exitosamente por el servicio SOA. Clave: {clave_acceso}")
                    else:
                        print(f"Servicio de facturacion devolvio error {bill_res.status_code}: {bill_res.text}")
                except Exception as ex_bill:
                    print(f"No se pudo contactar al servicio de facturacion XML: {ex_bill}")

                # 8. Save Invoice to Supabase
                if clave_acceso:
                    try:
                        cur.execute("""
                            INSERT INTO facturas (cita_id, paciente, total, estado, clave_acceso)
                            VALUES (%s, %s, %s, 'GENERADA', %s)
                            RETURNING id;
                        """, (cita_id, paciente, costo_consulta, clave_acceso))
                        factura_id = cur.fetchone()["id"]
                        conn.commit()

                        # Save invoice to SQLite local database
                        local_factura = {
                            "id": factura_id,
                            "cita_id": cita_id,
                            "paciente": paciente,
                            "total": costo_consulta,
                            "estado": "GENERADA",
                            "clave_acceso": clave_acceso
                        }
                        insert_factura_local(local_factura)
                    except Exception as ex_ins_bill:
                        print(f"Error al registrar la factura en la BD: {ex_ins_bill}")

                # 9. Generate QR Code details for counter payment (Component 12)
                qr_text = f"CITA: {cita_id}\nPACIENTE: {paciente}\nCEDULA: {cedula}\nTOTAL: {costo_consulta:.2f}\nCODIGO_PAGO: {codigo_pago}\nESTADO: PENDIENTE"
                qr_base64 = get_qr_base64(qr_text)

                return jsonify({
                    "mensaje": "Cita registrada correctamente",
                    "cita_id": cita_id,
                    "valor_pagar": costo_consulta,
                    "codigo_pago": codigo_pago,
                    "clave_acceso": clave_acceso,
                    "qr_data": qr_text,
                    "qr_base64": qr_base64
                }), 201

    except Exception as e:
        conn.rollback()
        return jsonify({"error": f"Error al procesar la cita: {str(e)}"}), 500

# 5. GET /api/citas - Get appointments (Protected, supports fallback to local SQLite)
@app.route("/api/citas", methods=["GET"])
@require_token
def get_citas():
    # If query param local=true is specified, force using local SQLite database
    use_local = request.args.get("local", "false").lower() == "true"
    
    if use_local:
        print("Obteniendo citas desde la REPLICA LOCAL SQLite...")
        return get_citas_from_local()
    
    # Try fetching from Supabase first
    conn = get_db_connection()
    if conn is None:
        print("Supabase inalcanzable. Usando REPLICA LOCAL SQLite como respaldo de alta disponibilidad...")
        return get_citas_from_local()

    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT c.id, c.paciente, c.cedula, c.medico_id, m.nombre as medico, 
                           m.especialidad, c.fecha, c.hora, c.valor_pagar, c.estado, c.codigo_pago 
                    FROM citas c
                    JOIN medicos m ON c.medico_id = m.id
                    ORDER BY c.fecha_registro DESC;
                """)
                citas = cur.fetchall()
                
                # Format values
                formatted_citas = []
                for c in citas:
                    formatted_citas.append({
                        "id": c["id"],
                        "paciente": c["paciente"],
                        "cedula": c["cedula"],
                        "medico_id": c["medico_id"],
                        "medico": c["medico"],
                        "especialidad": c["especialidad"],
                        "fecha": c["fecha"].strftime("%Y-%m-%d"),
                        "hora": c["hora"].strftime("%H:%M"),
                        "valor_pagar": float(c["valor_pagar"]),
                        "estado": c["estado"],
                        "codigo_pago": c["codigo_pago"]
                    })
                return jsonify(formatted_citas)
    except Exception as e:
        print(f"Error consultando Supabase ({e}). Usando REPLICA LOCAL SQLite...")
        return get_citas_from_local()

def get_citas_from_local():
    try:
        conn = get_local_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM citas ORDER BY fecha_registro DESC;")
        rows = cursor.fetchall()
        citas = []
        for r in rows:
            citas.append({
                "id": r["id"],
                "paciente": r["paciente"],
                "cedula": r["cedula"],
                "medico_id": r["medico_id"],
                "fecha": r["fecha"],
                "hora": r["hora"],
                "valor_pagar": float(r["valor_pagar"]),
                "estado": r["estado"],
                "codigo_pago": r["codigo_pago"],
                "medico": "No disponible (Replica Local)",
                "especialidad": "No disponible (Replica Local)"
            })
        conn.close()
        return jsonify(citas)
    except Exception as e:
        return jsonify({"error": f"Error al consultar replica local: {str(e)}"}), 500

# 6. POST /api/sincronizar - Sync citations and invoices from Supabase to local SQLite (Component 10, Option B)
@app.route("/api/sincronizar", methods=["POST"])
@require_token
def sincronizar_citas():
    conn = get_db_connection()
    if conn is None:
        return jsonify({"error": "No se puede conectar a la base de datos principal Supabase para sincronizar"}), 500

    try:
        citas_sincronizadas = 0
        facturas_sincronizadas = 0
        
        with conn:
            with conn.cursor() as cur:
                # Get all appointments
                cur.execute("SELECT * FROM citas;")
                citas = cur.fetchall()
                
                # Get all invoices
                cur.execute("SELECT * FROM facturas;")
                facturas = cur.fetchall()
                
                # Write appointments to SQLite
                for c in citas:
                    c_dict = {
                        "id": c["id"],
                        "paciente": c["paciente"],
                        "cedula": c["cedula"],
                        "medico_id": c["medico_id"],
                        "fecha": c["fecha"].strftime("%Y-%m-%d"),
                        "hora": c["hora"].strftime("%H:%M"),
                        "valor_pagar": float(c["valor_pagar"]),
                        "estado": c["estado"],
                        "codigo_pago": c["codigo_pago"]
                    }
                    insert_cita_local(c_dict)
                    citas_sincronizadas += 1
                
                # Write invoices to SQLite
                for f in facturas:
                    f_dict = {
                        "id": f["id"],
                        "cita_id": f["cita_id"],
                        "paciente": f["paciente"],
                        "total": float(f["total"]),
                        "estado": f["estado"],
                        "clave_acceso": f["clave_acceso"]
                    }
                    insert_factura_local(f_dict)
                    facturas_sincronizadas += 1
                    
        return jsonify({
            "mensaje": "Sincronización completada con éxito",
            "citas_sincronizadas": citas_sincronizadas,
            "facturas_sincronizadas": facturas_sincronizadas
        }), 200
    except Exception as e:
        return jsonify({"error": f"Error durante la sincronizacion: {str(e)}"}), 500

if __name__ == "__main__":
    # Get port from environment or default to 5001
    port = int(os.environ.get("PORT", 5001))
    print(f"Iniciando API REST MediCitas 360 en puerto {port}...")
    app.run(host="0.0.0.0", port=port, debug=True)
