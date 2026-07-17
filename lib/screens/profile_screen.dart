import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final int usuarioId;

  const ProfileScreen({
    super.key,
    required this.usuarioId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? usuario;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarUsuario();
  }

  Future<void> cargarUsuario() async {
    try {
      final resultado =
          await DatabaseHelper.instance.getUserById(widget.usuarioId);

      if (!mounted) return;

      setState(() {
        usuario = resultado;
        cargando = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cargar el perfil.'),
        ),
      );
    }
  }

  Future<void> editarDatos() async {
    if (usuario == null) return;

    final nombreController = TextEditingController(
      text: usuario!.nombre,
    );

    final correoController = TextEditingController(
      text: usuario!.correo,
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool guardando = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar perfil'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreController,
                      enabled: !guardando,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: correoController,
                      enabled: !guardando,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: guardando
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          final nombre =
                              nombreController.text.trim();
                          final correo =
                              correoController.text.trim();

                          if (nombre.isEmpty || correo.isEmpty) {
                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Complete el nombre y el correo.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (!correo.contains('@')) {
                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingrese un correo válido.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            guardando = true;
                          });

                          try {
                            final usuarioActualizado = UserModel(
                              id: usuario!.id,
                              nombre: nombre,
                              correo: correo,
                              password: usuario!.password,
                            );

                            await DatabaseHelper.instance.updateUser(
                              usuarioActualizado,
                            );

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            await Future<void>.delayed(
                              const Duration(milliseconds: 250),
                            );

                            await cargarUsuario();

                            if (!mounted) return;

                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Perfil actualizado correctamente.',
                                ),
                              ),
                            );
                          } on DatabaseException catch (error) {
                            if (!mounted) return;

                            setDialogState(() {
                              guardando = false;
                            });

                            final mensaje =
                                error.isUniqueConstraintError()
                                    ? 'Ese correo ya está registrado.'
                                    : 'No se pudo actualizar el perfil.';

                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(mensaje),
                              ),
                            );
                          } catch (error) {
                            if (!mounted) return;

                            setDialogState(() {
                              guardando = false;
                            });

                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No se pudo actualizar el perfil.',
                                ),
                              ),
                            );
                          }
                        },
                  child: guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 300),
    );

    nombreController.dispose();
    correoController.dispose();
  }

  Future<void> cambiarPassword() async {
    if (usuario == null) return;

    final actualController = TextEditingController();
    final nuevaController = TextEditingController();
    final confirmarController = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool guardando = false;
        bool ocultarActual = true;
        bool ocultarNueva = true;
        bool ocultarConfirmacion = true;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Cambiar contraseña'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: actualController,
                      enabled: !guardando,
                      obscureText: ocultarActual,
                      decoration: InputDecoration(
                        labelText: 'Contraseña actual',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              ocultarActual = !ocultarActual;
                            });
                          },
                          icon: Icon(
                            ocultarActual
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nuevaController,
                      enabled: !guardando,
                      obscureText: ocultarNueva,
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              ocultarNueva = !ocultarNueva;
                            });
                          },
                          icon: Icon(
                            ocultarNueva
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmarController,
                      enabled: !guardando,
                      obscureText: ocultarConfirmacion,
                      decoration: InputDecoration(
                        labelText: 'Confirmar nueva contraseña',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.verified_user),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              ocultarConfirmacion =
                                  !ocultarConfirmacion;
                            });
                          },
                          icon: Icon(
                            ocultarConfirmacion
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: guardando
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          final actual = actualController.text;
                          final nueva = nuevaController.text;
                          final confirmacion =
                              confirmarController.text;

                          if (actual.isEmpty ||
                              nueva.isEmpty ||
                              confirmacion.isEmpty) {
                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Complete todos los campos.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (actual != usuario!.password) {
                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'La contraseña actual es incorrecta.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (nueva.length < 6) {
                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'La nueva contraseña debe tener mínimo 6 caracteres.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (nueva != confirmacion) {
                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Las contraseñas no coinciden.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            guardando = true;
                          });

                          try {
                            await DatabaseHelper.instance
                                .updateUserPassword(
                              widget.usuarioId,
                              nueva,
                            );

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            await Future<void>.delayed(
                              const Duration(milliseconds: 250),
                            );

                            await cargarUsuario();

                            if (!mounted) return;

                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Contraseña actualizada correctamente.',
                                ),
                              ),
                            );
                          } catch (error) {
                            if (!mounted) return;

                            setDialogState(() {
                              guardando = false;
                            });

                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No se pudo cambiar la contraseña.',
                                ),
                              ),
                            );
                          }
                        },
                  child: guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Actualizar'),
                ),
              ],
            );
          },
        );
      },
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 300),
    );

    actualController.dispose();
    nuevaController.dispose();
    confirmarController.dispose();
  }

  Future<void> eliminarCuenta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar cuenta'),
          content: const Text(
            'Esta acción eliminará tu cuenta, tus rutinas y tus registros de peso. No se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Eliminar cuenta'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await DatabaseHelper.instance.deleteUser(
        widget.usuarioId,
      );

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta eliminada correctamente.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar la cuenta.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : usuario == null
              ? const Center(
                  child: Text(
                    'No se encontró la información del usuario.',
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const SizedBox(height: 10),
                    const CircleAvatar(
                      radius: 55,
                      child: Icon(
                        Icons.person,
                        size: 70,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      usuario!.nombre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      usuario!.correo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 30),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Editar datos'),
                        subtitle: const Text(
                          'Cambiar nombre o correo',
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                        ),
                        onTap: editarDatos,
                      ),
                    ),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.lock_reset),
                        title: const Text('Cambiar contraseña'),
                        subtitle: const Text(
                          'Actualizar la contraseña de acceso',
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                        ),
                        onTap: cambiarPassword,
                      ),
                    ),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Cerrar sesión'),
                        trailing: const Icon(
                          Icons.chevron_right,
                        ),
                        onTap: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/',
                            (route) => false,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: eliminarCuenta,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Eliminar mi cuenta'),
                    ),
                  ],
                ),
    );
  }
}