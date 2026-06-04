import 'package:flutter/material.dart';
import '../models/medico.dart';
import '../models/horario.dart';
import '../services/api_service.dart';
import 'payment_qr_screen.dart';

class HorariosScreen extends StatefulWidget {
  final Medico medico;
  const HorariosScreen({super.key, required this.medico});

  @override
  State<HorariosScreen> createState() => _HorariosScreenState();
}

class _HorariosScreenState extends State<HorariosScreen> {
  final ApiService apiService = ApiService();
  List<Horario> horarios = [];
  bool isLoading = true;
  Horario? selectedHorario;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pacienteCtrl = TextEditingController();
  final TextEditingController _cedulaCtrl = TextEditingController();

  // Token simulator settings (for testing Component 7)
  String tokenMode = "correcto"; // "correcto", "incorrecto", "ninguno"

  @override
  void initState() {
    super.initState();
    _loadHorarios();
  }

  Future<void> _loadHorarios() async {
    setState(() {
      isLoading = true;
      selectedHorario = null;
    });
    try {
      final list = await apiService.getHorarios(widget.medico.id);
      setState(() {
        horarios = list;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("Error al cargar horarios: $e", isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _registerCita() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedHorario == null) {
      _showSnackBar("Por favor, seleccione un horario.", isError: true);
      return;
    }

    String? customToken;
    if (tokenMode == "incorrecto") {
      customToken = "token_invalido_123";
    } else if (tokenMode == "ninguno") {
      customToken = ""; // Empty string triggers empty or invalid check
    }

    setState(() => isLoading = true);

    try {
      final res = await apiService.createCita(
        paciente: _pacienteCtrl.text.trim(),
        cedula: _cedulaCtrl.text.trim(),
        medicoId: widget.medico.id,
        fecha: selectedHorario!.fecha,
        hora: selectedHorario!.hora,
        customToken: customToken,
      );

      setState(() => isLoading = false);

      // Successfully booked!
      _showSnackBar("¡Cita registrada correctamente!");
      
      // Go to QR Payment code screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentQrScreen(
              citaId: res["cita_id"],
              paciente: _pacienteCtrl.text.trim(),
              cedula: _cedulaCtrl.text.trim(),
              medico: widget.medico.nombre,
              especialidad: widget.medico.especialidad,
              fecha: selectedHorario!.fecha,
              hora: selectedHorario!.hora,
              total: res["valor_pagar"].toDouble(),
              codigoPago: res["codigo_pago"],
              claveAcceso: res["clave_acceso"] ?? "Sin Factura",
              qrBase64: res["qr_base64"] ?? "",
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("Error al registrar: $e", isError: true);
      
      // If error due to occupied schedule, reload schedules
      _loadHorarios();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      appBar: AppBar(
        title: Text(
          "Horarios - ${widget.medico.nombre}",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor Info Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.blue.shade50,
                            child: const Icon(Icons.medical_services, color: Color(0xFF1E3A8A)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.medico.nombre,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  widget.medico.especialidad,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Costo: \$${widget.medico.costoConsulta.toStringAsFixed(2)} | Consultorio: ${widget.medico.consultorio}",
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Schedules Title
                  const Text(
                    "Selecciona un Horario Disponible:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(height: 10),

                  // Schedules Grid / List
                  horarios.isEmpty
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text("No hay horarios configurados para este médico."),
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: horarios.map((h) {
                            final isSelected = selectedHorario?.fecha == h.fecha && selectedHorario?.hora == h.hora;
                            return ChoiceChip(
                              label: Text("${h.fecha} ${h.hora}"),
                              selected: isSelected,
                              selectedColor: const Color(0xFF3B82F6),
                              backgroundColor: h.disponible ? Colors.white : Colors.grey.shade300,
                              labelStyle: TextStyle(
                                color: isSelected 
                                    ? Colors.white 
                                    : (h.disponible ? Colors.black : Colors.grey.shade600),
                                fontWeight: FontWeight.bold,
                              ),
                              avatar: h.disponible 
                                  ? const Icon(Icons.check_circle_outline, size: 16, color: Colors.green)
                                  : const Icon(Icons.block, size: 16, color: Colors.grey),
                              onSelected: h.disponible
                                  ? (selected) {
                                      setState(() {
                                        selectedHorario = selected ? h : null;
                                      });
                                    }
                                  : null,
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 25),

                  // Form for Patient Info
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Datos del Paciente",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _pacienteCtrl,
                              decoration: const InputDecoration(
                                labelText: "Nombre Completo",
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Por favor, ingrese el nombre del paciente.";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _cedulaCtrl,
                              decoration: const InputDecoration(
                                labelText: "Cédula de Identidad",
                                prefixIcon: Icon(Icons.badge),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Por favor, ingrese la cédula.";
                                }
                                if (value.length < 10) {
                                  return "La cédula debe tener al menos 10 dígitos.";
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Token Testing Section (Component 7 Requirements)
                  Card(
                    elevation: 1,
                    color: Colors.orange.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.security, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                "Simulación de Token de Seguridad (Unidad 3)",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Use estas opciones para simular y evidenciar las respuestas de la API ante tokens correctos, incorrectos o ausentes:",
                            style: TextStyle(fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              FilterChip(
                                label: const Text("Correcto"),
                                selected: tokenMode == "correcto",
                                selectedColor: Colors.green.shade200,
                                onSelected: (val) {
                                  setState(() => tokenMode = "correcto");
                                },
                              ),
                              FilterChip(
                                label: const Text("Incorrecto"),
                                selected: tokenMode == "incorrecto",
                                selectedColor: Colors.red.shade200,
                                onSelected: (val) {
                                  setState(() => tokenMode = "incorrecto");
                                },
                              ),
                              FilterChip(
                                label: const Text("Sin Token"),
                                selected: tokenMode == "ninguno",
                                selectedColor: Colors.grey.shade400,
                                onSelected: (val) {
                                  setState(() => tokenMode = "ninguno");
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _registerCita,
                      icon: const Icon(Icons.calendar_month),
                      label: const Text(
                        "Agendar Cita",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
