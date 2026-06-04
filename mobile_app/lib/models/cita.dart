class Cita {
  final int id;
  final String paciente;
  final String cedula;
  final int medicoId;
  final String medico;
  final String especialidad;
  final String fecha;
  final String hora;
  final double valorPagar;
  final String estado;
  final String codigoPago;

  Cita({
    required this.id,
    required this.paciente,
    required this.cedula,
    required this.medicoId,
    required this.medico,
    required this.especialidad,
    required this.fecha,
    required this.hora,
    required this.valorPagar,
    required this.estado,
    required this.codigoPago,
  });

  factory Cita.fromJson(Map<String, dynamic> json) {
    return Cita(
      id: json['id'] as int,
      paciente: json['paciente'] as String,
      cedula: json['cedula'] as String,
      medicoId: json['medico_id'] as int,
      medico: json['medico'] ?? "No disponible",
      especialidad: json['especialidad'] ?? "No disponible",
      fecha: json['fecha'] as String,
      hora: json['hora'] as String,
      valorPagar: (json['valor_pagar'] as num).toDouble(),
      estado: json['estado'] as String,
      codigoPago: json['codigo_pago'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paciente': paciente,
      'cedula': cedula,
      'medico_id': medicoId,
      'medico': medico,
      'especialidad': especialidad,
      'fecha': fecha,
      'hora': hora,
      'valor_pagar': valorPagar,
      'estado': estado,
      'codigo_pago': codigoPago,
    };
  }
}
