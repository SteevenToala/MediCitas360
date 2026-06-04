import 'package:flutter/material.dart';
import '../models/medico.dart';
import '../services/api_service.dart';
import 'horarios_screen.dart';
import 'citas_list_screen.dart';

class MedicosScreen extends StatefulWidget {
  const MedicosScreen({super.key});

  @override
  State<MedicosScreen> createState() => _MedicosScreenState();
}

class _MedicosScreenState extends State<MedicosScreen> {
  final ApiService apiService = ApiService();
  List<Medico> medicos = [];
  bool isLoading = true;
  final TextEditingController _ipController = TextEditingController(text: ApiService.apiBaseUrl);

  @override
  void initState() {
    super.initState();
    _loadMedicos();
  }

  Future<void> _loadMedicos() async {
    setState(() => isLoading = true);
    try {
      final list = await apiService.getMedicos();
      setState(() {
        medicos = list;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar("Error al cargar médicos: $e");
    }
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Configuración de Red"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Ingrese la URL del Balanceador de Carga (NGINX):"),
              const SizedBox(height: 10),
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: "API Base URL",
                  hintText: "http://localhost:8080",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Nota: Para emulador Android use http://10.0.2.2:8080",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  ApiService.apiBaseUrl = _ipController.text.trim();
                });
                Navigator.pop(context);
                _loadMedicos();
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      appBar: AppBar(
        title: const Text(
          "MediCitas 360",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3A8A), // Medical Dark Blue
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: "Configurar IP",
            onPressed: _openSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            tooltip: "Mis Citas",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CitasListScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Elegant Promo / Welcome card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Bienvenido a tu salud",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Agenda tu Cita Médica",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Conectado al balanceador: ${ApiService.apiBaseUrl}",
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : medicos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                            const SizedBox(height: 10),
                            const Text(
                              "No se encontraron médicos.",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _loadMedicos,
                              icon: const Icon(Icons.refresh),
                              label: const Text("Reintentar"),
                            )
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMedicos,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: medicos.length,
                          itemBuilder: (context, index) {
                            final doc = medicos[index];
                            
                            // Nice avatars based on doctor gender/name
                            final bool isDra = doc.nombre.startsWith("Dra");
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => HorariosScreen(medico: doc),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: isDra 
                                            ? Colors.teal.shade100 
                                            : Colors.blue.shade100,
                                        child: Icon(
                                          isDra ? Icons.woman : Icons.man,
                                          size: 40,
                                          color: isDra ? Colors.teal.shade800 : Colors.blue.shade800,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              doc.nombre,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E3A8A),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              doc.especialidad,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(Icons.meeting_room, size: 16, color: Colors.blue.shade600),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "Consultorio: ${doc.consultorio}",
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                                const SizedBox(width: 16),
                                                Icon(Icons.timer, size: 16, color: Colors.blue.shade600),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "${doc.duracionTurno} min",
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "\$${doc.costoConsulta.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey,
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
