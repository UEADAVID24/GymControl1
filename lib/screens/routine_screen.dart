import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/routine_model.dart';
import 'exercise_screen.dart';

class RoutineScreen extends StatefulWidget {
  final int usuarioId;

  const RoutineScreen({
    super.key,
    required this.usuarioId,
  });

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
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
          await DatabaseHelper.instance.getRoutinesByUser(
        widget.usuarioId,
      );

      if (!mounted) return;

      setState(() {
        rutinas = resultado;
        cargando = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron cargar las rutinas.'),
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

    final descripcionController = TextEditingController(
      text: rutina?.descripcion ?? '',
    );

    final esEdicion = rutina != null;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool guardando = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                esEdicion ? 'Editar rutina' : 'Nueva rutina',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreController,
                      enabled: !guardando,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la rutina',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descripcionController,
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
                          final descripcion =
                              descripcionController.text.trim();

                          if (nombre.isEmpty) {
                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingrese el nombre de la rutina.',
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
                              final rutinaActualizada =
                                  rutina.copyWith(
                                nombre: nombre,
                                descripcion: descripcion,
                              );

                              await DatabaseHelper.instance
                                  .updateRoutine(
                                rutinaActualizada,
                              );
                            } else {
                              final nuevaRutina = RoutineModel(
                                usuarioId: widget.usuarioId,
                                nombre: nombre,
                                descripcion: descripcion,
                              );

                              await DatabaseHelper.instance
                                  .insertRoutine(
                                nuevaRutina,
                              );
                            }

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            await Future<void>.delayed(
                              const Duration(milliseconds: 250),
                            );

                            if (!mounted) return;

                            await cargarRutinas();

                            if (!mounted) return;

                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  esEdicion
                                      ? 'Rutina actualizada correctamente.'
                                      : 'Rutina creada correctamente.',
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
                                  'No se pudo guardar la rutina.',
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
                      : Text(
                          esEdicion ? 'Actualizar' : 'Guardar',
                        ),
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
    descripcionController.dispose();
  }

  Future<void> confirmarEliminacion(
    RoutineModel rutina,
  ) async {
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
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || rutina.id == null) {
      return;
    }

    try {
      await DatabaseHelper.instance.deleteRoutine(
        rutina.id!,
        widget.usuarioId,
      );

      await cargarRutinas();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rutina eliminada correctamente.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar la rutina.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis rutinas'),
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : rutinas.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Todavía no tienes rutinas registradas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: cargarRutinas,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rutinas.length,
                    itemBuilder: (context, index) {
                      final rutina = rutinas[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.fitness_center),
                          ),
                          title: Text(
                            rutina.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            rutina.descripcion.isEmpty
                                ? 'Sin descripción'
                                : rutina.descripcion,
                          ),
                          onTap: () {
                            if (rutina.id == null) {
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExerciseScreen(
                                  rutinaId: rutina.id!,
                                  nombreRutina: rutina.nombre,
                                ),
                              ),
                            );
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (opcion) {
                              if (opcion == 'ejercicios') {
                                if (rutina.id == null) {
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ExerciseScreen(
                                      rutinaId: rutina.id!,
                                      nombreRutina: rutina.nombre,
                                    ),
                                  ),
                                );
                              } else if (opcion == 'editar') {
                                mostrarFormulario(
                                  rutina: rutina,
                                );
                              } else if (opcion == 'eliminar') {
                                confirmarEliminacion(rutina);
                              }
                            },
                            itemBuilder: (context) {
                              return const [
                                PopupMenuItem(
                                  value: 'ejercicios',
                                  child: Row(
                                    children: [
                                      Icon(Icons.fitness_center),
                                      SizedBox(width: 10),
                                      Text('Ver ejercicios'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'editar',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 10),
                                      Text('Editar'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'eliminar',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete),
                                      SizedBox(width: 10),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          mostrarFormulario();
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar rutina'),
      ),
    );
  }
}