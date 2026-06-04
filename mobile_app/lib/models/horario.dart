class Horario {
  final String fecha;
  final String hora;
  final bool disponible;

  Horario({
    required this.fecha,
    required this.hora,
    required this.disponible,
  });

  factory Horario.fromJson(Map<String, dynamic> json) {
    return Horario(
      fecha: json['fecha'] as String,
      hora: json['hora'] as String,
      disponible: json['disponible'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fecha': fecha,
      'hora': hora,
      'disponible': disponible,
    };
  }
}
