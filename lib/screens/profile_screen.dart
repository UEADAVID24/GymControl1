import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final int usuarioId;

  const ProfileScreen({
    super.key,
    required this.usuarioId,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  final ImagePicker _imagePicker =
      ImagePicker();

  UserModel? usuario;
  File? fotoPerfil;

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarDatosIniciales();
  }

  String get _claveFotoPerfil =>
      'foto_perfil_usuario_${widget.usuarioId}';

  Future<void> cargarDatosIniciales() async {
    await Future.wait([
      cargarUsuario(),
      cargarFotoPerfil(),
    ]);
  }

  // =========================
  // CARGAR PERFIL
  // =========================

  Future<void> cargarUsuario() async {
    try {
      final respuesta =
          await ApiService.instance.getProfile();

      final dynamic datos =
          respuesta['usuario'];

      if (datos is! Map) {
        throw const ApiException(
          'El servidor no devolvió la información del usuario.',
        );
      }

      final mapa =
          Map<String, dynamic>.from(datos);

      final dynamic idValor =
          mapa['id'] ?? mapa['usuario_id'];

      int usuarioId = widget.usuarioId;

      if (idValor is int) {
        usuarioId = idValor;
      } else {
        usuarioId = int.tryParse(
              idValor?.toString() ?? '',
            ) ??
            widget.usuarioId;
      }

      final nombre =
          mapa['nombre']?.toString().trim() ??
              '';

      final correo =
          mapa['correo']?.toString().trim() ??
              '';

      if (nombre.isEmpty || correo.isEmpty) {
        throw const ApiException(
          'La información del usuario está incompleta.',
        );
      }

      final preferences =
          await SharedPreferences.getInstance();

      await preferences.setInt(
        'usuario_id',
        usuarioId,
      );

      await preferences.setString(
        'usuario_nombre',
        nombre,
      );

      await preferences.setString(
        'usuario_correo',
        correo,
      );

      if (!mounted) return;

      setState(() {
        usuario = UserModel(
          id: usuarioId,
          nombre: nombre,
          correo: correo,
          password: '',
        );

        cargando = false;
      });
    } on ApiException catch (error) {
      await cargarDatosGuardados(
        error.message,
      );
    } catch (_) {
      await cargarDatosGuardados(
        'No se pudo conectar con el servidor.',
      );
    }
  }

  Future<void> cargarDatosGuardados(
    String mensaje,
  ) async {
    final preferences =
        await SharedPreferences.getInstance();

    final id =
        preferences.getInt('usuario_id') ??
            widget.usuarioId;

    final nombre =
        preferences.getString(
      'usuario_nombre',
    );

    final correo =
        preferences.getString(
      'usuario_correo',
    );

    if (!mounted) return;

    if (nombre != null &&
        nombre.isNotEmpty &&
        correo != null &&
        correo.isNotEmpty) {
      setState(() {
        usuario = UserModel(
          id: id,
          nombre: nombre,
          correo: correo,
          password: '',
        );

        cargando = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '$mensaje Se mostraron los datos guardados.',
          ),
        ),
      );

      return;
    }

    setState(() {
      usuario = null;
      cargando = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  // =========================
  // FOTO DE PERFIL
  // =========================

  Future<void> cargarFotoPerfil() async {
    final preferences =
        await SharedPreferences.getInstance();

    final ruta =
        preferences.getString(
      _claveFotoPerfil,
    );

    if (ruta == null || ruta.isEmpty) {
      return;
    }

    final archivo = File(ruta);

    if (!await archivo.exists()) {
      await preferences.remove(
        _claveFotoPerfil,
      );

      return;
    }

    if (!mounted) return;

    setState(() {
      fotoPerfil = archivo;
    });
  }

  Future<void> seleccionarFoto(
    ImageSource origen,
  ) async {
    try {
      final imagen =
          await _imagePicker.pickImage(
        source: origen,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
        requestFullMetadata: false,
      );

      if (imagen == null) return;

      final directorio =
          await getApplicationDocumentsDirectory();

      final carpeta = Directory(
        p.join(
          directorio.path,
          'profile_photos',
        ),
      );

      if (!await carpeta.exists()) {
        await carpeta.create(
          recursive: true,
        );
      }

      final extension =
          p.extension(imagen.path).isEmpty
              ? '.jpg'
              : p.extension(imagen.path);

      final rutaDestino = p.join(
        carpeta.path,
        'usuario_${widget.usuarioId}$extension',
      );

      if (fotoPerfil != null &&
          await fotoPerfil!.exists() &&
          fotoPerfil!.path != rutaDestino) {
        await fotoPerfil!.delete();
      }

      final archivo =
          await File(imagen.path).copy(
        rutaDestino,
      );

      final preferences =
          await SharedPreferences.getInstance();

      await preferences.setString(
        _claveFotoPerfil,
        archivo.path,
      );

      if (!mounted) return;

      setState(() {
        fotoPerfil = archivo;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Foto de perfil actualizada.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo seleccionar la foto: $error',
          ),
        ),
      );
    }
  }

  Future<void> eliminarFotoPerfil() async {
    try {
      if (fotoPerfil != null &&
          await fotoPerfil!.exists()) {
        await fotoPerfil!.delete();
      }

      final preferences =
          await SharedPreferences.getInstance();

      await preferences.remove(
        _claveFotoPerfil,
      );

      if (!mounted) return;

      setState(() {
        fotoPerfil = null;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Foto de perfil eliminada.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo eliminar la foto.',
          ),
        ),
      );
    }
  }

  Future<void> mostrarOpcionesFoto() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Foto de perfil',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                ),
                title: const Text(
                  'Elegir de la galería',
                ),
                onTap: () {
                  Navigator.pop(
                    sheetContext,
                  );

                  seleccionarFoto(
                    ImageSource.gallery,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                ),
                title: const Text(
                  'Tomar una foto',
                ),
                onTap: () {
                  Navigator.pop(
                    sheetContext,
                  );

                  seleccionarFoto(
                    ImageSource.camera,
                  );
                },
              ),
              if (fotoPerfil != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                  ),
                  title: const Text(
                    'Eliminar foto',
                  ),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );

                    eliminarFotoPerfil();
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // =========================
  // EDITAR NOMBRE Y CORREO
  // =========================

  Future<void> editarDatos() async {
    if (usuario == null) return;

    final nombreController =
        TextEditingController(
      text: usuario!.nombre,
    );

    final correoController =
        TextEditingController(
      text: usuario!.correo,
    );

    final actualizado =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool guardando = false;

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Editar perfil',
              ),
              content:
                  SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    TextField(
                      controller:
                          nombreController,
                      enabled: !guardando,
                      textCapitalization:
                          TextCapitalization
                              .words,
                      decoration:
                          const InputDecoration(
                        labelText: 'Nombre',
                        border:
                            OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.person,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    TextField(
                      controller:
                          correoController,
                      enabled: !guardando,
                      keyboardType:
                          TextInputType
                              .emailAddress,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Correo electrónico',
                        border:
                            OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.email,
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
                          Navigator.pop(
                            dialogContext,
                            false,
                          );
                        },
                  child: const Text(
                    'Cancelar',
                  ),
                ),
                FilledButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          final nombre =
                              nombreController
                                  .text
                                  .trim();

                          final correo =
                              correoController
                                  .text
                                  .trim()
                                  .toLowerCase();

                          if (nombre.length < 3) {
                            ScaffoldMessenger
                                    .of(
                              dialogContext,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'El nombre debe tener al menos 3 caracteres.',
                                ),
                              ),
                            );

                            return;
                          }

                          if (!correo
                                  .contains('@') ||
                              !correo
                                  .contains('.')) {
                            ScaffoldMessenger
                                    .of(
                              dialogContext,
                            ).showSnackBar(
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
                            await ApiService
                                .instance
                                .updateProfile(
                              nombre: nombre,
                              correo: correo,
                            );

                            if (!dialogContext
                                .mounted) {
                              return;
                            }

                            Navigator.pop(
                              dialogContext,
                              true,
                            );
                          } on ApiException catch (
                            error
                          ) {
                            setDialogState(() {
                              guardando = false;
                            });

                            if (!dialogContext
                                .mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error.message,
                                ),
                              ),
                            );
                          } catch (_) {
                            setDialogState(() {
                              guardando = false;
                            });

                            if (!dialogContext
                                .mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No se pudo conectar con el servidor.',
                                ),
                              ),
                            );
                          }
                        },
                  child: guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Guardar',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    nombreController.dispose();
    correoController.dispose();

    if (actualizado != true) {
      return;
    }

    setState(() {
      cargando = true;
    });

    await cargarUsuario();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Perfil actualizado correctamente.',
        ),
      ),
    );
  }

  // =========================
  // CAMBIAR CONTRASEÑA
  // =========================

  Future<void> cambiarPassword() async {
    final actualController =
        TextEditingController();

    final nuevaController =
        TextEditingController();

    final confirmarController =
        TextEditingController();

    final cambiado =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool guardando = false;
        bool ocultarActual = true;
        bool ocultarNueva = true;
        bool ocultarConfirmacion = true;

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Cambiar contraseña',
              ),
              content:
                  SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    TextField(
                      controller:
                          actualController,
                      enabled: !guardando,
                      obscureText:
                          ocultarActual,
                      decoration:
                          InputDecoration(
                        labelText:
                            'Contraseña actual',
                        border:
                            const OutlineInputBorder(),
                        prefixIcon:
                            const Icon(
                          Icons.lock,
                        ),
                        suffixIcon:
                            IconButton(
                          onPressed: () {
                            setDialogState(
                              () {
                                ocultarActual =
                                    !ocultarActual;
                              },
                            );
                          },
                          icon: Icon(
                            ocultarActual
                                ? Icons
                                    .visibility
                                : Icons
                                    .visibility_off,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    TextField(
                      controller:
                          nuevaController,
                      enabled: !guardando,
                      obscureText:
                          ocultarNueva,
                      decoration:
                          InputDecoration(
                        labelText:
                            'Nueva contraseña',
                        border:
                            const OutlineInputBorder(),
                        prefixIcon:
                            const Icon(
                          Icons.lock_reset,
                        ),
                        suffixIcon:
                            IconButton(
                          onPressed: () {
                            setDialogState(
                              () {
                                ocultarNueva =
                                    !ocultarNueva;
                              },
                            );
                          },
                          icon: Icon(
                            ocultarNueva
                                ? Icons
                                    .visibility
                                : Icons
                                    .visibility_off,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    TextField(
                      controller:
                          confirmarController,
                      enabled: !guardando,
                      obscureText:
                          ocultarConfirmacion,
                      decoration:
                          InputDecoration(
                        labelText:
                            'Confirmar nueva contraseña',
                        border:
                            const OutlineInputBorder(),
                        prefixIcon:
                            const Icon(
                          Icons
                              .verified_user,
                        ),
                        suffixIcon:
                            IconButton(
                          onPressed: () {
                            setDialogState(
                              () {
                                ocultarConfirmacion =
                                    !ocultarConfirmacion;
                              },
                            );
                          },
                          icon: Icon(
                            ocultarConfirmacion
                                ? Icons
                                    .visibility
                                : Icons
                                    .visibility_off,
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
                          Navigator.pop(
                            dialogContext,
                            false,
                          );
                        },
                  child: const Text(
                    'Cancelar',
                  ),
                ),
                FilledButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          final actual =
                              actualController
                                  .text;

                          final nueva =
                              nuevaController
                                  .text;

                          final confirmar =
                              confirmarController
                                  .text;

                          if (actual.isEmpty ||
                              nueva.isEmpty ||
                              confirmar
                                  .isEmpty) {
                            ScaffoldMessenger
                                    .of(
                              dialogContext,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Complete todos los campos.',
                                ),
                              ),
                            );

                            return;
                          }

                          if (nueva.length < 6) {
                            ScaffoldMessenger
                                    .of(
                              dialogContext,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'La nueva contraseña debe tener al menos 6 caracteres.',
                                ),
                              ),
                            );

                            return;
                          }

                          if (nueva !=
                              confirmar) {
                            ScaffoldMessenger
                                    .of(
                              dialogContext,
                            ).showSnackBar(
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
                            await ApiService
                                .instance
                                .changePassword(
                              passwordActual:
                                  actual,
                              passwordNueva:
                                  nueva,
                            );

                            if (!dialogContext
                                .mounted) {
                              return;
                            }

                            Navigator.pop(
                              dialogContext,
                              true,
                            );
                          } on ApiException catch (
                            error
                          ) {
                            setDialogState(() {
                              guardando = false;
                            });

                            if (!dialogContext
                                .mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error.message,
                                ),
                              ),
                            );
                          } catch (_) {
                            setDialogState(() {
                              guardando = false;
                            });

                            if (!dialogContext
                                .mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No se pudo conectar con el servidor.',
                                ),
                              ),
                            );
                          }
                        },
                  child: guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Actualizar',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    actualController.dispose();
    nuevaController.dispose();
    confirmarController.dispose();

    if (cambiado != true ||
        !mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Contraseña actualizada correctamente.',
        ),
      ),
    );
  }

  // =========================
  // CERRAR SESIÓN
  // =========================

  Future<void> cerrarSesion() async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Cerrar sesión',
          ),
          content: const Text(
            '¿Deseas cerrar tu sesión en GymControl?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Cerrar sesión',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await ApiService.instance.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }

  // =========================
  // ELIMINAR CUENTA
  // =========================

  Future<void> eliminarCuenta() async {
    final passwordController =
        TextEditingController();

    final confirmada =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool eliminando = false;
        bool ocultarPassword = true;

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Eliminar cuenta',
              ),
              content:
                  SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Text(
                      'Esta acción eliminará tu cuenta, rutinas, pesos, entrenamientos y recordatorios. No se puede deshacer.',
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    TextField(
                      controller:
                          passwordController,
                      enabled: !eliminando,
                      obscureText:
                          ocultarPassword,
                      decoration:
                          InputDecoration(
                        labelText:
                            'Contraseña actual',
                        border:
                            const OutlineInputBorder(),
                        prefixIcon:
                            const Icon(
                          Icons.lock,
                        ),
                        suffixIcon:
                            IconButton(
                          onPressed: () {
                            setDialogState(
                              () {
                                ocultarPassword =
                                    !ocultarPassword;
                              },
                            );
                          },
                          icon: Icon(
                            ocultarPassword
                                ? Icons
                                    .visibility
                                : Icons
                                    .visibility_off,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: eliminando
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                            false,
                          );
                        },
                  child: const Text(
                    'Cancelar',
                  ),
                ),
                FilledButton(
                  onPressed: eliminando
                      ? null
                      : () async {
                          final password =
                              passwordController
                                  .text;

                          if (password.isEmpty) {
                            ScaffoldMessenger
                                    .of(
                              dialogContext,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingrese su contraseña.',
                                ),
                              ),
                            );

                            return;
                          }

                          setDialogState(() {
                            eliminando = true;
                          });

                          try {
                            await ApiService
                                .instance
                                .deleteAccount(
                              password:
                                  password,
                            );

                            if (!dialogContext
                                .mounted) {
                              return;
                            }

                            Navigator.pop(
                              dialogContext,
                              true,
                            );
                          } on ApiException catch (
                            error
                          ) {
                            setDialogState(() {
                              eliminando = false;
                            });

                            if (!dialogContext
                                .mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error.message,
                                ),
                              ),
                            );
                          } catch (_) {
                            setDialogState(() {
                              eliminando = false;
                            });

                            if (!dialogContext
                                .mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No se pudo conectar con el servidor.',
                                ),
                              ),
                            );
                          }
                        },
                  child: eliminando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Eliminar definitivamente',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();

    if (confirmada != true ||
        !mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }

  Future<void> actualizarPerfil() async {
    setState(() {
      cargando = true;
    });

    await cargarUsuario();
  }

  // =========================
  // INTERFAZ
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi perfil',
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar perfil',
            onPressed: cargando
                ? null
                : actualizarPerfil,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: cargando
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : usuario == null
              ? _buildUsuarioNoEncontrado()
              : _buildPerfil(),
    );
  }

  Widget _buildUsuarioNoEncontrado() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_off_outlined,
              size: 80,
            ),
            const SizedBox(height: 18),
            const Text(
              'No se encontró la información del usuario.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: actualizarPerfil,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Intentar nuevamente',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerfil() {
    return RefreshIndicator(
      onRefresh: cargarUsuario,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 10),
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                InkWell(
                  onTap:
                      mostrarOpcionesFoto,
                  borderRadius:
                      BorderRadius.circular(
                    60,
                  ),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundImage:
                        fotoPerfil != null
                            ? FileImage(
                                fotoPerfil!,
                              )
                            : null,
                    child: fotoPerfil == null
                        ? const Icon(
                            Icons.person,
                            size: 70,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Material(
                    color:
                        Theme.of(context)
                            .colorScheme
                            .primary,
                    shape:
                        const CircleBorder(),
                    child: InkWell(
                      onTap:
                          mostrarOpcionesFoto,
                      customBorder:
                          const CircleBorder(),
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .all(10),
                        child: Icon(
                          Icons.camera_alt,
                          size: 20,
                          color:
                              Theme.of(context)
                                  .colorScheme
                                  .onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            usuario!.nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            usuario!.correo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 30),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.person_outline,
              ),
              title:
                  const Text('Nombre'),
              subtitle: Text(
                usuario!.nombre,
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.email_outlined,
              ),
              title: const Text(
                'Correo electrónico',
              ),
              subtitle: Text(
                usuario!.correo,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.edit,
              ),
              title: const Text(
                'Editar datos',
              ),
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
              leading: const Icon(
                Icons.lock_reset,
              ),
              title: const Text(
                'Cambiar contraseña',
              ),
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
              leading: const Icon(
                Icons.logout,
              ),
              title: const Text(
                'Cerrar sesión',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: cerrarSesion,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: eliminarCuenta,
            icon: const Icon(
              Icons.delete_forever,
            ),
            label: const Text(
              'Eliminar mi cuenta',
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}