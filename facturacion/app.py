import os
import xml.etree.ElementTree as ET
from xml.dom import minidom
from flask import Flask, request, jsonify, Response

app = Flask(__name__)

# Ensure the output directory for facturas XML files exists
FACTURAS_DIR = os.path.join(os.path.dirname(__file__), "facturas")
os.makedirs(FACTURAS_DIR, exist_ok=True)

@app.route("/")
def home():
    return jsonify({
        "status": "active",
        "service": "Servicio de Facturacion XML SOA (MediCitas 360)"
    })

@app.route("/api/facturar", methods=["POST"])
def facturar():
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Datos invalidos o vacios"}), 400

    cita_id = data.get("cita_id")
    paciente = data.get("paciente")
    cedula = data.get("cedula")
    medico = data.get("medico")
    especialidad = data.get("especialidad")
    fecha = data.get("fecha")
    hora = data.get("hora")
    total = data.get("total")

    # Basic validations
    if not all([cita_id, paciente, cedula, medico, especialidad, fecha, hora, total]):
        return jsonify({"error": "Faltan campos obligatorios para generar la factura"}), 400

    # Format the access key using the cita_id
    # Format: FAC-CITA-2026-XXXX
    try:
        cita_num = int(cita_id)
        clave_acceso = f"FAC-CITA-2026-{cita_num:04d}"
    except ValueError:
        clave_acceso = f"FAC-CITA-2026-{cita_id}"

    # Generate XML
    factura_elem = ET.Element("FacturaCita")
    
    ET.SubElement(factura_elem, "Paciente").text = str(paciente)
    ET.SubElement(factura_elem, "Cedula").text = str(cedula)
    ET.SubElement(factura_elem, "Medico").text = str(medico)
    ET.SubElement(factura_elem, "Especialidad").text = str(especialidad)
    ET.SubElement(factura_elem, "Fecha").text = str(fecha)
    ET.SubElement(factura_elem, "Hora").text = str(hora)
    ET.SubElement(factura_elem, "Total").text = f"{float(total):.2f}"
    ET.SubElement(factura_elem, "Estado").text = "GENERADA"
    ET.SubElement(factura_elem, "ClaveAcceso").text = clave_acceso

    # Convert to formatted XML string
    xml_raw = ET.tostring(factura_elem, encoding="utf-8")
    xml_pretty = minidom.parseString(xml_raw).toprettyxml(indent="  ")

    # Save XML to local folder
    xml_filename = f"factura_{cita_id}.xml"
    xml_filepath = os.path.join(FACTURAS_DIR, xml_filename)
    with open(xml_filepath, "w", encoding="utf-8") as f:
        f.write(xml_pretty)

    print(f"Factura guardada localmente en: {xml_filepath}")

    return jsonify({
        "mensaje": "Factura generada correctamente",
        "clave_acceso": clave_acceso,
        "estado": "GENERADA",
        "xml": xml_pretty
    })

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5003))
    print(f"Iniciando servicio de facturacion en puerto {port}...")
    app.run(host="0.0.0.0", port=port, debug=True)
