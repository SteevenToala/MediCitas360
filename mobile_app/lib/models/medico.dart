class Medico {
  final int id;
  final String nombre;
  final String especialidad;
  final String consultorio;
  final double costoConsulta;
  final int duracionTurno;

  Medico({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.consultorio,
    required this.costoConsulta,
    required this.duracionTurno,
  });

  factory Medico.fromJson(Map<String, dynamic> json) {
    return Medico(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      especialidad: json['especialidad'] as String,
      consultorio: json['consultorio'] as String,
      costoConsulta: (json['costo_consulta'] as num).toDouble(),
      duracionTurno: json['duracion_turno'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'especialidad': especialidad,
      'consultorio': consultorio,
      'costo_consulta': costoConsulta,
      'duracion_turno': duracionTurno,
    };
  }
}
