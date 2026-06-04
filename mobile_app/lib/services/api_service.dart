import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medico.dart';
import '../models/horario.dart';
import '../models/cita.dart';

class ApiService {
  // Use http://localhost:8080 (NGINX Load Balancer) by default.
  // Can be dynamically changed from the UI for Android Emulator (10.0.2.2) or devices.
  static String apiBaseUrl = "http://localhost:8080";
  static const String token = "medicitas2026";

  Map<String, String> _getHeaders() {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    };
  }

  // Fetch all doctors
  Future<List<Medico>> getMedicos() async {
    final url = Uri.parse("$apiBaseUrl/api/medicos");
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => Medico.fromJson(e)).toList();
    }
    throw Exception("Error al cargar médicos: ${res.statusCode}");
  }

  // Fetch schedules for a specific doctor
  Future<List<Horario>> getHorarios(int medicoId) async {
    final url = Uri.parse("$apiBaseUrl/api/medicos/$medicoId/horarios");
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => Horario.fromJson(e)).toList();
    }
    throw Exception("Error al cargar horarios: ${res.statusCode}");
  }

  // Book an appointment (Protected with token)
  // Returns a map with success info, cita_id, valor_pagar, clave_acceso, and qr details
  Future<Map<String, dynamic>> createCita({
    required String paciente,
    required String cedula,
    required int medicoId,
    required String fecha,
    required String hora,
    String? customToken, # Option to simulate incorrect/empty token from UI
  }) async {
    final url = Uri.parse("$apiBaseUrl/api/citas");
    
    // Allow using an invalid token to demonstrate security checks
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${customToken ?? token}"
    };

    final body = jsonEncode({
      "paciente": paciente,
      "cedula": cedula,
      "medico_id": medicoId,
      "fecha": fecha,
      "hora": hora
    });

    final res = await http.post(url, headers: headers, body: body);
    final responseBody = jsonDecode(res.body);
    
    if (res.statusCode == 201) {
      return responseBody as Map<String, dynamic>;
    } else {
      // Return error message from backend
      throw Exception(responseBody["error"] ?? "Error al registrar cita: ${res.statusCode}");
    }
  }

  // Fetch all booked appointments (Protected with token)
  Future<List<Cita>> getCitas({bool queryLocal = false, String? customToken}) async {
    // Add ?local=true parameter if we want to query local SQLite replica directly
    final suffix = queryLocal ? "?local=true" : "";
    final url = Uri.parse("$apiBaseUrl/api/citas$suffix");
    
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${customToken ?? token}"
    };

    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => Cita.fromJson(e)).toList();
    }
    final responseBody = jsonDecode(res.body);
    throw Exception(responseBody["error"] ?? "Error al obtener citas: ${res.statusCode}");
  }

  // Sync Supabase to SQLite local database (Protected)
  Future<Map<String, dynamic>> sincronizar() async {
    final url = Uri.parse("$apiBaseUrl/api/sincronizar");
    final res = await http.post(url, headers: _getHeaders());
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    final responseBody = jsonDecode(res.body);
    throw Exception(responseBody["error"] ?? "Error al sincronizar: ${res.statusCode}");
  }
}
