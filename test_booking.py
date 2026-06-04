import requests
import json

# Configuration
API_URL = "http://localhost:5001/api/citas"
TOKEN = "medicitas2026"

def test_successful_booking():
    headers = {
        "Authorization": f"Bearer {TOKEN}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "paciente": "Alexander Tasinchano",
        "cedula": "1804901234",
        "medico_id": 1,
        "fecha": "2026-06-04",
        "hora": "08:30"
    }
    
    print("--- 1. Probando agendamiento de cita con TOKEN CORRECTO ---")
    print(f"Payload: {json.dumps(payload, indent=2)}")
    
    res = requests.post(API_URL, headers=headers, json=payload)
    print(f"Status Code: {res.status_code}")
    print(f"Response:\n{json.dumps(res.json(), indent=2)}")
    
    print("\n--- 2. Probando agendamiento en el MISMO HORARIO (Debe fallar) ---")
    res_fail = requests.post(API_URL, headers=headers, json=payload)
    print(f"Status Code: {res_fail.status_code}")
    print(f"Response:\n{json.dumps(res_fail.json(), indent=2)}")

def test_security_token():
    print("\n--- 3. Probando seguridad de TOKEN INCORRECTO ---")
    headers = {
        "Authorization": "Bearer token_malo_xyz",
        "Content-Type": "application/json"
    }
    res = requests.post(API_URL, headers=headers, json={})
    print(f"Status Code: {res.status_code}")
    print(f"Response: {res.json()}")

    print("\n--- 4. Probando seguridad SIN TOKEN ---")
    res_no = requests.post(API_URL, json={})
    print(f"Status Code: {res_no.status_code}")
    print(f"Response: {res_no.json()}")

if __name__ == "__main__":
    test_successful_booking()
    test_security_token()
