import 'package:flutter/material.dart';

import '../models/routine_model.dart';
import '../services/api_service.dart';
import 'exercise_screen.dart';

class RoutineScreen extends StatefulWidget {
  final int usuarioId;

  const RoutineScreen({
    super.key,
    required this.usuarioId,
  });

  @override
  State<RoutineScreen> createState() =>
      _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  List<RoutineModel> rutinas = [];

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarRutinas();
  }

  Future<void> cargarRutinas() async {
    try {
      final resultado =
          await ApiService.instance.getRoutines();

      if (!mounted) return;

      setState(() {
        rutinas = resultado;
        cargando = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo conectar con el servidor.',
          ),
        ),
      );
    }
  }

  Future<void> mostrarFormulario({
    RoutineModel? rutina,
  }) async {
    final nombreController = TextEditingController(
      text: rutina?.nombre ?? '',
    );

    final descripcionController =
        TextEditingController(
      text: rutina?.descripcion ?? '',
    );

    final esEdicion = rutina != null;

    final guardado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool guardando = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                esEdicion
                    ? 'Editar rutina'
                    : 'Nueva rutina',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreController,
                      enabled: !guardando,
                      textCapitalization:
                          TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText:
                            'Nombre de la rutina',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller:
                          descripcionController,
                      enabled: !guardando,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
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
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          final nombre =
                              nombreController.text.trim();

                          final descripcion =
                              descripcionController.text
                                  .trim();

                          if (nombre.length < 3) {
                            ScaffoldMessenger.of(
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

                          setDialogState(() {
                            guardando = true;
                          });

                          try {
                            if (esEdicion) {
                              if (rutina.id == null) {
                                throw const ApiException(
                                  'La rutina no tiene identificador.',
                                );
                              }

                              await ApiService.instance
                                  .updateRoutine(
                                rutinaId: rutina.id!,
                                nombre: nombre,
                                descripcion: descripcion,
                              );
                            } else {
                              await ApiService.instance
                                  .createRoutine(
                                nombre: nombre,
                                descripcion: descripcion,
                              );
                            }

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.pop(
                              dialogContext,
                              true,
                            );
                          } on ApiException catch (error) {
                            setDialogState(() {
                              guardando = false;
                            });

                            if (!dialogContext.mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(
                              SnackBar(
                                content:
                                    Text(error.message),
                              ),
                            );
                          } catch (_) {
                            setDialogState(() {
                              guardando = false;
                            });

                            if (!dialogContext.mounted) {
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
                      : Text(
                          esEdicion
                              ? 'Actualizar'
                              : 'Guardar',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    nombreController.dispose();
    descripcionController.dispose();

    if (guardado != true) return;

    await cargarRutinas();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          esEdicion
              ? 'Rutina actualizada correctamente.'
              : 'Rutina creada correctamente.',
        ),
      ),
    );
  }

  Future<void> confirmarEliminacion(
    RoutineModel rutina,
  ) async {
    if (rutina.id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar rutina'),
          content: Text(
            '¿Deseas eliminar la rutina "${rutina.nombre}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await ApiService.instance.deleteRoutine(
        rutinaId: rutina.id!,
      );

      await cargarRutinas();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Rutina eliminada correctamente.',
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
    }
  }

  Future<void> abrirEjercicios(
    RoutineModel rutina,
  ) async {
    if (rutina.id == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseScreen(
          rutinaId: rutina.id!,
          nombreRutina: rutina.nombre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis rutinas'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: cargarRutinas,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: cargarRutinas,
              child: rutinas.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 150),
                        Icon(
                          Icons.fitness_center,
                          size: 80,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Todavía no tienes rutinas registradas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.all(16),
                      itemCount: rutinas.length,
                      itemBuilder: (context, index) {
                        final rutina =
                            rutinas[index];

                        return Card(
                          margin:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: ListTile(
                            leading:
                                const CircleAvatar(
                              child: Icon(
                                Icons.fitness_center,
                              ),
                            ),
                            title: Text(
                              rutina.nombre,
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              rutina.descripcion.isEmpty
                                  ? 'Sin descripción'
                                  : rutina.descripcion,
                            ),
                            onTap: () {
                              abrirEjercicios(rutina);
                            },
                            trailing:
                                PopupMenuButton<String>(
                              onSelected: (opcion) {
                                if (opcion ==
                                    'ejercicios') {
                                  abrirEjercicios(
                                    rutina,
                                  );
                                } else if (opcion ==
                                    'editar') {
                                  mostrarFormulario(
                                    rutina: rutina,
                                  );
                                } else if (opcion ==
                                    'eliminar') {
                                  confirmarEliminacion(
                                    rutina,
                                  );
                                }
                              },
                              itemBuilder: (context) {
                                return const [
                                  PopupMenuItem(
                                    value:
                                        'ejercicios',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons
                                              .fitness_center,
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          'Ver ejercicios',
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'editar',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'eliminar',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Text('Eliminar'),
                                      ],
                                    ),
                                  ),
                                ];
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          mostrarFormulario();
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar rutina'),
      ),
    );
  }
}