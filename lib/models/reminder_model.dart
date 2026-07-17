class ReminderModel {
  final int? id;
  final int usuarioId;
  final String titulo;
  final String mensaje;
  final int diaSemana;
  final int hora;
  final int minuto;
  final bool activo;

  const ReminderModel({
    this.id,
    required this.usuarioId,
    required this.titulo,
    required this.mensaje,
    required this.diaSemana,
    required this.hora,
    required this.minuto,
    this.activo = true,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'usuario_id': usuarioId,
      'titulo': titulo,
      'mensaje': mensaje,
      'dia_semana': diaSemana,
      'hora': hora,
      'minuto': minuto,
      'activo': activo ? 1 : 0,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] as int?,
      usuarioId: map['usuario_id'] as int,
      titulo: map['titulo'] as String,
      mensaje: map['mensaje'] as String,
      diaSemana: map['dia_semana'] as int,
      hora: map['hora'] as int,
      minuto: map['minuto'] as int,
      activo: (map['activo'] as int) == 1,
    );
  }

  ReminderModel copyWith({
    int? id,
    int? usuarioId,
    String? titulo,
    String? mensaje,
    int? diaSemana,
    int? hora,
    int? minuto,
    bool? activo,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      diaSemana: diaSemana ?? this.diaSemana,
      hora: hora ?? this.hora,
      minuto: minuto ?? this.minuto,
      activo: activo ?? this.activo,
    );
  }
}