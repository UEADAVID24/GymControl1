import 'package:flutter/material.dart';

import '../services/api_service.dart';

class SessionProvider extends ChangeNotifier {
  int? _usuarioId;
  String? _nombreUsuario;
  String? _correoUsuario;
  bool _autenticado = false;

  int? get usuarioId => _usuarioId;
  String? get nombreUsuario => _nombreUsuario;
  String? get correoUsuario => _correoUsuario;
  bool get autenticado => _autenticado;

  void iniciarSesion({
    required int usuarioId,
    required String nombreUsuario,
    String? correoUsuario,
  }) {
    _usuarioId = usuarioId;
    _nombreUsuario = nombreUsuario;
    _correoUsuario = correoUsuario;
    _autenticado = true;

    notifyListeners();
  }

  Future<void> cerrarSesion() async {
    await ApiService.instance.logout();

    _usuarioId = null;
    _nombreUsuario = null;
    _correoUsuario = null;
    _autenticado = false;

    notifyListeners();
  }
}