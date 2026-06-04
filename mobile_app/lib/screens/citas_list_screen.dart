import 'package:flutter/material.dart';
import '../models/cita.dart';
import '../services/api_service.dart';
import 'payment_qr_screen.dart';

class CitasListScreen extends StatefulWidget {
  const CitasListScreen({super.key});

  @override
  State<CitasListScreen> createState() => _CitasListScreenState();
}

class _CitasListScreenState extends State<CitasListScreen> {
  final ApiService apiService = ApiService();
  List<Cita> citas = [];
  bool isLoading = true;
  
  // Settings
  bool queryLocal = false; // Toggle between Supabase and Local SQLite
  String tokenMode = "correcto"; // "correcto", "incorrecto", "ninguno"

  @override
  void initState() {
    super.initState();
    _loadCitas();
  }

  Future<void> _loadCitas() async {
    setState(() => isLoading = true);
    
    String? customToken;
    if (tokenMode == "incorrecto") {
      customToken = "token_malo_987";
    } else if (tokenMode == "ninguno") {
      customToken = "";
    }

    try {
      final list = await apiService.getCitas(
        queryLocal: queryLocal,
        customToken: customToken,
      );
      setState(() {
        citas = list;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        citas = [];
        isLoading = false;
      });
      _showSnackBar("Error al cargar citas: $e", isError: true);
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

  Future<void> _syncDatabases() async {
    setState(() => isLoading = true);
    try {
      final res = await apiService.sincronizar();
      _showSnackBar(
        "Sincronización finalizada:\n- Citas: ${res['citas_sincronizadas']}\n- Facturas: ${res['facturas_sincronizadas']}",
      );
      setState(() {
        queryLocal = true; // Switch to local view to show the result of sync!
      });
      await _loadCitas();
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("Error al sincronizar: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      appBar: AppBar(
        title: const Text(
          "Listado de Citas",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: "Sincronizar Réplica Local (Opción B)",
            onPressed: _syncDatabases,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Recargar",
            onPressed: _loadCitas,
          )
        ],
      ),
      body: Column(
        children: [
          // Database Source Toggle Panel
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Origen de Datos:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                ToggleButtons(
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: const Color(0xFF1E3A8A),
                  constraints: const BoxConstraints(minHeight: 32, minWidth: 100),
                  isSelected: [!queryLocal, queryLocal],
                  onPressed: (index) {
                    setState(() {
                      queryLocal = index == 1;
                    });
                    _loadCitas();
                  },
                  children: const [
                    Text("Supabase", style: TextStyle(fontSize: 12)),
                    Text("Replica Local", style: TextStyle(fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          
          // Security Token Testing Toggle Panel
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Seguridad Token:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                DropdownButton<String>(
                  value: tokenMode,
                  underline: const SizedBox(),
                  style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        tokenMode = newValue;
                      });
                      _loadCitas();
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: "correcto", child: Text("Token Correcto (medicitas2026)")),
                    DropdownMenuItem(value: "incorrecto", child: Text("Token Incorrecto")),
                    DropdownMenuItem(value: "ninguno", child: Text("Sin Token")),
                  ],
                )
              ],
            ),
          ),

          const Divider(height: 1),

          // Status Banner indicating where we are reading from
          Container(
            color: queryLocal ? Colors.orange.shade50 : Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            width: double.infinity,
            child: Text(
              queryLocal
                  ? "Leyendo desde: Base local SQLite (Replica Desconectada)"
                  : "Leyendo desde: Base en la nube Supabase (PostgreSQL)",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: queryLocal ? Colors.orange.shade900 : Colors.blue.shade900,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : citas.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 15),
                              const Text(
                                "No se encontraron citas en este origen.",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 15),
                              ElevatedButton.icon(
                                onPressed: _loadCitas,
                                icon: const Icon(Icons.refresh),
                                label: const Text("Recargar"),
                              )
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: citas.length,
                        itemBuilder: (context, index) {
                          final c = citas[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.paciente,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    "\$${c.valorPagar.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green,
                                    ),
                                  )
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text("Cédula: ${c.cedula}"),
                                  Text("Médico ID: ${c.medicoId} | ${c.medico}"),
                                  if (c.especialidad != "No disponible")
                                    Text("Especialidad: ${c.especialidad}"),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${c.fecha} - ${c.hora}",
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        c.codigoPago,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade800,
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.qr_code_2, color: Color(0xFF1E3A8A)),
                                tooltip: "Ver QR y Factura",
                                onPressed: () {
                                  // In list view we don't have base64 QR, let's generate it in the QR Screen using the data
                                  final qrText = "CITA: ${c.id}\nPACIENTE: ${c.paciente}\nCEDULA: ${c.cedula}\nTOTAL: ${c.valorPagar.toStringAsFixed(2)}\nCODIGO_PAGO: ${c.codigoPago}\nESTADO: ${c.estado}";
                                  
                                  // Call helper to get Base64 bytes
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PaymentQrScreen(
                                        citaId: c.id,
                                        paciente: c.paciente,
                                        cedula: c.cedula,
                                        medico: c.medico,
                                        especialidad: c.especialidad,
                                        fecha: c.fecha,
                                        hora: c.hora,
                                        total: c.valorPagar,
                                        codigoPago: c.codigoPago,
                                        claveAcceso: "FAC-CITA-2026-${c.id:04d}", // Reconstruct
                                        qrBase64: "", // Empty will make the screen generate it or show fallback
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
