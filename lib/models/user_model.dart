class UserModel {
  final int? id;
  final String nombre;
  final String correo;
  final String password;

  const UserModel({
    this.id,
    required this.nombre,
    required this.correo,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'password': password,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      correo: map['correo'] as String,
      password: map['password'] as String,
    );
  }
}