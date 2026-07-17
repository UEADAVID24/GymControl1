class ExerciseModel {
  final int? id;
  final int rutinaId;
  final String nombre;
  final int series;
  final int repeticiones;
  final double peso;

  const ExerciseModel({
    this.id,
    required this.rutinaId,
    required this.nombre,
    required this.series,
    required this.repeticiones,
    required this.peso,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rutina_id': rutinaId,
      'nombre': nombre,
      'series': series,
      'repeticiones': repeticiones,
      'peso': peso,
    };
  }

  factory ExerciseModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ExerciseModel(
      id: map['id'] as int?,
      rutinaId: map['rutina_id'] as int,
      nombre: map['nombre'] as String,
      series: map['series'] as int,
      repeticiones: map['repeticiones'] as int,
      peso: (map['peso'] as num).toDouble(),
    );
  }

  ExerciseModel copyWith({
    int? id,
    int? rutinaId,
    String? nombre,
    int? series,
    int? repeticiones,
    double? peso,
  }) {
    return ExerciseModel(
      id: id ?? this.id,
      rutinaId: rutinaId ?? this.rutinaId,
      nombre: nombre ?? this.nombre,
      series: series ?? this.series,
      repeticiones: repeticiones ?? this.repeticiones,
      peso: peso ?? this.peso,
    );
  }
}