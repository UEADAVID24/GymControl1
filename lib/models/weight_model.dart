class WeightModel {
  final int? id;
  final int usuarioId;
  final double peso;
  final String fecha;

  const WeightModel({
    this.id,
    required this.usuarioId,
    required this.peso,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'peso': peso,
      'fecha': fecha,
    };
  }

  factory WeightModel.fromMap(Map<String, dynamic> map) {
    return WeightModel(
      id: map['id'] as int?,
      usuarioId: map['usuario_id'] as int,
      peso: (map['peso'] as num).toDouble(),
      fecha: map['fecha'] as String,
    );
  }

  WeightModel copyWith({
    int? id,
    int? usuarioId,
    double? peso,
    String? fecha,
  }) {
    return WeightModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      peso: peso ?? this.peso,
      fecha: fecha ?? this.fecha,
    );
  }
}