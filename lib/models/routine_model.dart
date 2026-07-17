class RoutineModel {
  final int? id;
  final int usuarioId;
  final String nombre;
  final String descripcion;

  const RoutineModel({
    this.id,
    required this.usuarioId,
    required this.nombre,
    required this.descripcion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }

  factory RoutineModel.fromMap(Map<String, dynamic> map) {
    return RoutineModel(
      id: map['id'] as int?,
      usuarioId: map['usuario_id'] as int,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String? ?? '',
    );
  }

  RoutineModel copyWith({
    int? id,
    int? usuarioId,
    String? nombre,
    String? descripcion,
  }) {
    return RoutineModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
    );
  }
}