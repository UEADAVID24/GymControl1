class TrainingModel {
  final int? id;
  final int usuarioId;
  final int? rutinaId;
  final String nombreRutina;
  final String fecha;
  final int duracionMinutos;
  final String observaciones;

  const TrainingModel({
    this.id,
    required this.usuarioId,
    this.rutinaId,
    required this.nombreRutina,
    required this.fecha,
    required this.duracionMinutos,
    required this.observaciones,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'rutina_id': rutinaId,
      'nombre_rutina': nombreRutina,
      'fecha': fecha,
      'duracion_minutos': duracionMinutos,
      'observaciones': observaciones,
    };
  }

  factory TrainingModel.fromMap(Map<String, dynamic> map) {
    return TrainingModel(
      id: map['id'] as int?,
      usuarioId: map['usuario_id'] as int,
      rutinaId: map['rutina_id'] as int?,
      nombreRutina: map['nombre_rutina'] as String,
      fecha: map['fecha'] as String,
      duracionMinutos: map['duracion_minutos'] as int,
      observaciones: map['observaciones'] as String? ?? '',
    );
  }

  TrainingModel copyWith({
    int? id,
    int? usuarioId,
    int? rutinaId,
    String? nombreRutina,
    String? fecha,
    int? duracionMinutos,
    String? observaciones,
  }) {
    return TrainingModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      rutinaId: rutinaId ?? this.rutinaId,
      nombreRutina: nombreRutina ?? this.nombreRutina,
      fecha: fecha ?? this.fecha,
      duracionMinutos: duracionMinutos ?? this.duracionMinutos,
      observaciones: observaciones ?? this.observaciones,
    );
  }
}