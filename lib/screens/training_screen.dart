import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database_helper.dart';
import '../models/routine_model.dart';
import '../models/training_model.dart';

class TrainingScreen extends StatefulWidget {
  final int usuarioId;

  const TrainingScreen({
    super.key,
    required this.usuarioId,
  });

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  List<TrainingModel> entrenamientos = [];
  List<RoutineModel> rutinas = [];

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    try {
      final resultadoEntrenamientos =
          await DatabaseHelper.instance.getTrainingsByUser(
        widget.usuarioId,
      );

      final resultadoRutinas =
          await DatabaseHelper.instance.getRoutinesByUser(
        widget.usuarioId,
      );

      if (!mounted) return;

      setState(() {
        entrenamientos = resultadoEntrenamientos;
        rutinas = resultadoRutinas;
        cargando = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron cargar los entrenamientos.',
          ),
        ),
      );
    }
  }

  String fechaParaBaseDeDatos(DateTime fecha) {
    final year = fecha.year.toString().padLeft(4, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final day = fecha.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String fechaParaMostrar(String fecha) {
    final partes = fecha.split('-');

    if (partes.length != 3) {
      return fecha;
    }

    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  Future<void> mostrarFormulario({
    TrainingModel? entrenamiento,
  }) async {
    final duracionController = TextEditingController(
      text: entrenamiento?.duracionMinutos.toString() ?? '',
    );

    final observacionesController = TextEditingController(
      text: entrenamiento?.observaciones ?? '',
    );

    DateTime fechaSeleccionada = entrenamiento == null
        ? DateTime.now()
        : DateTime.tryParse(entrenamiento.fecha) ?? DateTime.now();

    RoutineModel? rutinaSeleccionada;

    if (entrenamiento?.rutinaId != null) {
      for (final rutina in rutinas) {
        if (rutina.id == entrenamiento!.rutinaId) {
          rutinaSeleccionada = rutina;
          break;
        }
      }
    }

    final esEdicion = entrenamiento != null;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool guardando = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> seleccionarFecha() async {
              final nuevaFecha = await showDatePicker(
                context: dialogContext,
                initialDate: fechaSeleccionada,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );

              if (nuevaFecha != null) {
                setDialogState(() {
                  fechaSeleccionada = nuevaFecha;
                });
              }
            }

            return AlertDialog(
              title: Text(
                esEdicion
                    ? 'Editar entrenamiento'
                    : 'Registrar entrenamiento',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<RoutineModel>(
                      value: rutinaSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Rutina realizada',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.fitness_center),
                      ),
                      items: rutinas.map((rutina) {
                        return DropdownMenuItem<RoutineModel>(
                          value: rutina,
                          child: Text(rutina.nombre),
                        );
                      }).toList(),
                      onChanged: guardando
                          ? null
                          : (valor) {
                              setDialogState(() {
                                rutinaSeleccionada = valor;
                              });
                            },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: duracionController,
                      enabled: !guardando,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Duración',
                        hintText: 'Ejemplo: 60',
                        suffixText: 'min',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month),
                      title: const Text('Fecha'),
                      subtitle: Text(
                        fechaParaMostrar(
                          fechaParaBaseDeDatos(fechaSeleccionada),
                        ),
                      ),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: guardando ? null : seleccionarFecha,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: observacionesController,
                      enabled: !guardando,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones',
                        hintText: 'Ejemplo: Buen rendimiento',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notes),
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
                          final duracion = int.tryParse(
                            duracionController.text.trim(),
                          );

                          if (rutinaSeleccionada == null) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Seleccione una rutina.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (duracion == null || duracion <= 0) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingrese una duración válida.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (duracion > 600) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'La duración no puede superar 600 minutos.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            guardando = true;
                          });

                          try {
                            final fecha = fechaParaBaseDeDatos(
                              fechaSeleccionada,
                            );

                            if (esEdicion) {
                              final actualizado =
                                  entrenamiento.copyWith(
                                rutinaId: rutinaSeleccionada!.id,
                                nombreRutina:
                                    rutinaSeleccionada!.nombre,
                                fecha: fecha,
                                duracionMinutos: duracion,
                                observaciones:
                                    observacionesController.text.trim(),
                              );

                              await DatabaseHelper.instance
                                  .updateTraining(actualizado);
                            } else {
                              final nuevo = TrainingModel(
                                usuarioId: widget.usuarioId,
                                rutinaId: rutinaSeleccionada!.id,
                                nombreRutina:
                                    rutinaSeleccionada!.nombre,
                                fecha: fecha,
                                duracionMinutos: duracion,
                                observaciones:
                                    observacionesController.text.trim(),
                              );

                              await DatabaseHelper.instance
                                  .insertTraining(nuevo);
                            }

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            await Future<void>.delayed(
                              const Duration(milliseconds: 250),
                            );

                            if (!mounted) return;

                            await cargarDatos();

                            if (!mounted) return;

                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  esEdicion
                                      ? 'Entrenamiento actualizado correctamente.'
                                      : 'Entrenamiento registrado correctamente.',
                                ),
                              ),
                            );
                          } catch (error) {
                            if (!mounted) return;

                            setDialogState(() {
                              guardando = false;
                            });

                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No se pudo guardar el entrenamiento.',
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

    duracionController.dispose();
    observacionesController.dispose();
  }

  Future<void> confirmarEliminacion(
    TrainingModel entrenamiento,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar entrenamiento'),
          content: Text(
            '¿Deseas eliminar el entrenamiento '
            '"${entrenamiento.nombreRutina}"?',
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

    if (confirmar != true || entrenamiento.id == null) {
      return;
    }

    try {
      await DatabaseHelper.instance.deleteTraining(
        entrenamiento.id!,
        widget.usuarioId,
      );

      await cargarDatos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Entrenamiento eliminado correctamente.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo eliminar el entrenamiento.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis entrenamientos'),
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : rutinas.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 80,
                          color: Colors.deepPurple,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Primero debes crear una rutina.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 17),
                        ),
                      ],
                    ),
                  ),
                )
              : entrenamientos.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 80,
                              color: Colors.deepPurple,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Todavía no tienes entrenamientos registrados.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 17),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: cargarDatos,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: entrenamientos.length,
                        itemBuilder: (context, index) {
                          final entrenamiento =
                              entrenamientos[index];

                          return Card(
                            margin:
                                const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(
                                  Icons.fitness_center,
                                ),
                              ),
                              title: Text(
                                entrenamiento.nombreRutina,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${fechaParaMostrar(entrenamiento.fecha)}'
                                ' • ${entrenamiento.duracionMinutos} min'
                                '${entrenamiento.observaciones.isEmpty ? '' : '\n${entrenamiento.observaciones}'}',
                              ),
                              isThreeLine:
                                  entrenamiento.observaciones.isNotEmpty,
                              onTap: () {
                                mostrarFormulario(
                                  entrenamiento: entrenamiento,
                                );
                              },
                              trailing:
                                  PopupMenuButton<String>(
                                onSelected: (opcion) {
                                  if (opcion == 'editar') {
                                    mostrarFormulario(
                                      entrenamiento:
                                          entrenamiento,
                                    );
                                  } else if (opcion ==
                                      'eliminar') {
                                    confirmarEliminacion(
                                      entrenamiento,
                                    );
                                  }
                                },
                                itemBuilder: (context) {
                                  return const [
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
      floatingActionButton: rutinas.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                mostrarFormulario();
              },
              icon: const Icon(Icons.add),
              label: const Text('Registrar entrenamiento'),
            ),
    );
  }
}