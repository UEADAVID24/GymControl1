import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool ocultarPassword = true;
  bool cargando = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String? validarCorreo(String? value) {
    final correo = value?.trim() ?? '';

    if (correo.isEmpty) {
      return 'El correo electrónico es obligatorio.';
    }

    final expresionCorreo = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    if (!expresionCorreo.hasMatch(correo)) {
      return 'Ingrese un correo electrónico válido.';
    }

    return null;
  }

  String? validarPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria.';
    }

    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }

    return null;
  }

  Future<void> iniciarSesion() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final correo = emailController.text.trim();
    final password = passwordController.text;

    setState(() {
      cargando = true;
    });

    try {
      final respuesta = await ApiService.instance.login(
        correo: correo,
        password: password,
      );

      final usuario = respuesta['usuario'];

      if (usuario is! Map<String, dynamic>) {
        throw const ApiException(
          'No se recibieron correctamente los datos del usuario.',
        );
      }

      final usuarioId = usuario['id'];
      final nombreUsuario = usuario['nombre'];
      final correoUsuario = usuario['correo'];

      if (usuarioId is! int || nombreUsuario == null) {
        throw const ApiException(
          'Los datos del usuario son inválidos.',
        );
      }

      if (!mounted) return;

      context.read<SessionProvider>().iniciarSesion(
        usuarioId: usuarioId,
        nombreUsuario: nombreUsuario.toString(),
        correoUsuario: correoUsuario?.toString(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bienvenido, ${nombreUsuario.toString()}',
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(
            usuarioId: usuarioId,
            nombreUsuario: nombreUsuario.toString(),
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo conectar con el servidor.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100),

                const Icon(
                  Icons.fitness_center,
                  size: 80,
                  color: Colors.deepPurple,
                ),

                const SizedBox(height: 16),

                const Text(
                  'GymControl',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: validarCorreo,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'ejemplo@correo.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: passwordController,
                  obscureText: ocultarPassword,
                  validator: validarPassword,
                  onFieldSubmitted: (_) {
                    if (!cargando) {
                      iniciarSesion();
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          ocultarPassword = !ocultarPassword;
                        });
                      },
                      icon: Icon(
                        ocultarPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        cargando ? null : iniciarSesion,
                    child: cargando
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Ingresar'),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: cargando
                      ? null
                      : () {
                          Navigator.pushReplacementNamed(
                            context,
                            '/register',
                          );
                        },
                  child: const Text(
                    '¿No tienes cuenta? Regístrate',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}