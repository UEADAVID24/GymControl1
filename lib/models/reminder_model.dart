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
      'activo': activo,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    final activoValue = map['activo'];

    return ReminderModel(
      id: map['id'] as int?,
      usuarioId: map['usuario_id'] as int,
      titulo: map['titulo']?.toString() ?? '',
      mensaje: map['mensaje']?.toString() ?? '',
      diaSemana: map['dia_semana'] as int,
      hora: map['hora'] as int,
      minuto: map['minuto'] as int,
      activo: activoValue is bool
          ? activoValue
          : activoValue is num
              ? activoValue == 1
              : activoValue.toString().toLowerCase() == 'true',
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