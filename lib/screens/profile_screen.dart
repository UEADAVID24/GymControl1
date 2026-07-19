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
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  UserModel? usuario;
  File? fotoPerfil;

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarDatosIniciales();
  }

  Future<void> cargarDatosIniciales() async {
    await Future.wait([
      cargarUsuario(),
      cargarFotoPerfil(),
    ]);
  }

  String get _claveFotoPerfil =>
      'foto_perfil_usuario_${widget.usuarioId}';

  // =========================
  // CARGAR PERFIL DESDE API
  // =========================

  Future<void> cargarUsuario() async {
    try {
      final respuesta =
          await ApiService.instance.getProfile();

      final dynamic datosUsuario =
          respuesta['usuario'] ?? respuesta;

      if (datosUsuario is! Map) {
        throw const ApiException(
          'El servidor no devolvió la información del usuario.',
        );
      }

      final mapa = Map<String, dynamic>.from(
        datosUsuario,
      );

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
          mapa['nombre']?.toString().trim() ?? '';

      final correo =
          mapa['correo']?.toString().trim() ?? '';

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
      await cargarUsuarioGuardado(
        mensajeError: error.message,
      );
    } catch (error) {
      await cargarUsuarioGuardado(
        mensajeError:
            'No se pudo cargar el perfil desde el servidor.',
      );
    }
  }

  Future<void> cargarUsuarioGuardado({
    required String mensajeError,
  }) async {
    final preferences =
        await SharedPreferences.getInstance();

    final usuarioId =
        preferences.getInt('usuario_id') ??
            widget.usuarioId;

    final nombre =
        preferences.getString('usuario_nombre');

    final correo =
        preferences.getString('usuario_correo');

    if (!mounted) return;

    if (nombre != null &&
        nombre.trim().isNotEmpty &&
        correo != null &&
        correo.trim().isNotEmpty) {
      setState(() {
        usuario = UserModel(
          id: usuarioId,
          nombre: nombre,
          correo: correo,
          password: '',
        );

        cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$mensajeError Se mostraron los datos guardados.',
          ),
        ),
      );

      return;
    }

    setState(() {
      usuario = null;
      cargando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensajeError),
      ),
    );
  }

  // =========================
  // FOTO DE PERFIL LOCAL
  // =========================

  Future<void> cargarFotoPerfil() async {
    final preferences =
        await SharedPreferences.getInstance();

    final rutaGuardada =
        preferences.getString(_claveFotoPerfil);

    if (rutaGuardada == null ||
        rutaGuardada.isEmpty) {
      return;
    }

    final archivo = File(rutaGuardada);

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

      if (imagen == null) {
        return;
      }

      final directorio =
          await getApplicationDocumentsDirectory();

      final carpetaFotos = Directory(
        p.join(
          directorio.path,
          'profile_photos',
        ),
      );

      if (!await carpetaFotos.exists()) {
        await carpetaFotos.create(
          recursive: true,
        );
      }

      final extension =
          p.extension(imagen.path).isEmpty
              ? '.jpg'
              : p.extension(imagen.path);

      final rutaDestino = p.join(
        carpetaFotos.path,
        'usuario_${widget.usuarioId}$extension',
      );

      if (fotoPerfil != null &&
          await fotoPerfil!.exists() &&
          fotoPerfil!.path != rutaDestino) {
        await fotoPerfil!.delete();
      }

      final archivoCopiado =
          await File(imagen.path).copy(
        rutaDestino,
      );

      final preferences =
          await SharedPreferences.getInstance();

      await preferences.setString(
        _claveFotoPerfil,
        archivoCopiado.path,
      );

      if (!mounted) return;

      setState(() {
        fotoPerfil = archivoCopiado;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Foto de perfil actualizada.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Foto de perfil eliminada.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
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
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text(
                    'Foto de perfil',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
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
                    Navigator.pop(sheetContext);

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
                    Navigator.pop(sheetContext);

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
                      Navigator.pop(sheetContext);

                      eliminarFotoPerfil();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================
  // OPCIONES DEL PERFIL
  // =========================

  void mostrarFuncionPendiente(
    String funcion,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$funcion estará disponible cuando se conecte esta opción con el servidor.',
        ),
      ),
    );
  }

  Future<void> cerrarSesion() async {
    final confirmar = await showDialog<bool>(
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
            ElevatedButton(
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

    if (confirmar != true) {
      return;
    }

    await ApiService.instance.logout();

    if (!mounted) return;

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
            onPressed:
                cargando ? null : actualizarPerfil,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : usuario == null
              ? _buildUsuarioNoEncontrado()
              : _buildPerfil(),
    );
  }

  Widget _buildUsuarioNoEncontrado() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
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
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 10),

          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                InkWell(
                  onTap: mostrarOpcionesFoto,
                  borderRadius:
                      BorderRadius.circular(60),
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
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: mostrarOpcionesFoto,
                      customBorder:
                          const CircleBorder(),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          10,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Theme.of(context)
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
              fontWeight: FontWeight.bold,
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
              title: const Text(
                'Nombre',
              ),
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
              onTap: () {
                mostrarFuncionPendiente(
                  'La edición del perfil',
                );
              },
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
              onTap: () {
                mostrarFuncionPendiente(
                  'El cambio de contraseña',
                );
              },
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
            onPressed: () {
              mostrarFuncionPendiente(
                'La eliminación de la cuenta',
              );
            },
            icon: const Icon(
              Icons.delete_forever,
            ),
            label: const Text(
              'Eliminar mi cuenta',
            ),
          ),
        ],
      ),
    );
  }
}