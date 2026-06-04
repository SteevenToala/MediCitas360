import 'dart:convert';
import 'package:flutter/material.dart';

class PaymentQrScreen extends StatelessWidget {
  final int citaId;
  final String paciente;
  final String cedula;
  final String medico;
  final String especialidad;
  final String fecha;
  final String hora;
  final double total;
  final String codigoPago;
  final String claveAcceso;
  final String qrBase64;

  const PaymentQrScreen({
    super.key,
    required this.citaId,
    required this.paciente,
    required this.cedula,
    required this.medico,
    required this.especialidad,
    required this.fecha,
    required this.hora,
    required this.total,
    required this.codigoPago,
    required this.claveAcceso,
    required this.qrBase64,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      appBar: AppBar(
        title: const Text(
          "Comprobante de Cita",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success Card Banner
            Card(
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.green.shade200, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "¡Cita Reservada con Éxito!",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Su cita fue registrada correctamente. Acérquese a ventanilla con el código QR para realizar el pago respectivo.",
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Main Receipt details card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "DETALLES DE LA CITA",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "PENDIENTE",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        )
                      ],
                    ),
                    const Divider(height: 20),
                    
                    _buildDetailRow("ID Cita", "#$citaId"),
                    _buildDetailRow("Paciente", paciente),
                    _buildDetailRow("Cédula", cedula),
                    _buildDetailRow("Médico", medico),
                    _buildDetailRow("Especialidad", especialidad),
                    _buildDetailRow("Fecha", fecha),
                    _buildDetailRow("Hora", hora),
                    
                    const Divider(height: 20),
                    _buildDetailRow(
                      "Clave Acceso Factura (XML)", 
                      claveAcceso, 
                      isImportant: true,
                      textColor: Colors.blue.shade800
                    ),
                    _buildDetailRow(
                      "Código de Pago Ventanilla", 
                      codigoPago, 
                      isImportant: true,
                      textColor: Colors.orange.shade800
                    ),
                    
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total a Pagar:",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "\$${total.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // QR Code Rendering Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "Código QR para Pago",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Presente este código en ventanilla para facturación automática",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    
                    // Render base64 image if available, otherwise use public network QR API fallback
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: qrBase64.isNotEmpty
                          ? Image.memory(
                              base64Decode(qrBase64),
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                            )
                          : Image.network(
                              "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent("CITA: $citaId\nPACIENTE: $paciente\nCEDULA: $cedula\nTOTAL: ${total.toStringAsFixed(2)}\nCODIGO_PAGO: $codigoPago\nESTADO: PENDIENTE")}",
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const SizedBox(
                                  width: 180,
                                  height: 180,
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox(
                                  width: 180,
                                  height: 180,
                                  child: Center(
                                    child: Icon(Icons.qr_code, size: 100, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      codigoPago,
                      style: const TextStyle(
                        fontFamily: "monospace",
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Return to dashboard button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Volver al Inicio", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isImportant = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isImportant ? FontWeight.bold : FontWeight.w500,
                color: textColor ?? Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          )
        ],
      ),
    );
  }
}

// Simple Helper for layout fit
class BoxValues {
  static const BoxFit contain = BoxFit.contain;
}
