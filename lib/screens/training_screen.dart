import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/routine_model.dart';
import '../models/training_model.dart';
import '../services/api_service.dart';

class TrainingScreen extends StatefulWidget {
  final int usuarioId;

  const TrainingScreen({
    super.key,
    required this.usuarioId,
  });

  @override
  State<TrainingScreen> createState() =>
      _TrainingScreenState();
}

class _TrainingScreenState
    extends State<TrainingScreen> {
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
      final resultados = await Future.wait([
        ApiService.instance.getTrainings(),
        ApiService.instance.getRoutines(),
      ]);

      final resultadoEntrenamientos =
          resultados[0] as List<TrainingModel>;

      final resultadoRutinas =
          resultados[1] as List<RoutineModel>;

      if (!mounted) return;

      setState(() {
        entrenamientos = resultadoEntrenamientos;
        rutinas = resultadoRutinas;
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
      text:
          entrenamiento?.duracionMinutos.toString() ?? '',
    );

    final observacionesController =
        TextEditingController(
      text: entrenamiento?.observaciones ?? '',
    );

    DateTime fechaSeleccionada =
        entrenamiento == null
            ? DateTime.now()
            : DateTime.tryParse(
                  entrenamiento.fecha,
                ) ??
                DateTime.now();

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

    final guardado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool guardando = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> seleccionarFecha() async {
              final nuevaFecha =
                  await showDatePicker(
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
                    DropdownButtonFormField<
                        RoutineModel>(
                      value: rutinaSeleccionada,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Rutina realizada',
                        border:
                            OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.fitness_center,
                        ),
                      ),
                      items: rutinas.map((rutina) {
                        return DropdownMenuItem<
                            RoutineModel>(
                          value: rutina,
                          child: Text(
                            rutina.nombre,
                          ),
                        );
                      }).toList(),
                      onChanged: guardando
                          ? null
                          : (valor) {
                              setDialogState(() {
                                rutinaSeleccionada =
                                    valor;
                              });
                            },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller:
                          duracionController,
                      enabled: !guardando,
                      keyboardType:
                          TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly,
                      ],
                      decoration:
                          const InputDecoration(
                        labelText: 'Duración',
                        hintText: 'Ejemplo: 60',
                        suffixText: 'min',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(Icons.timer),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_month,
                      ),
                      title: const Text('Fecha'),
                      subtitle: Text(
                        fechaParaMostrar(
                          fechaParaBaseDeDatos(
                            fechaSeleccionada,
                          ),
                        ),
                      ),
                      trailing: const Icon(
                        Icons.edit_calendar,
                      ),
                      onTap: guardando
                          ? null
                          : seleccionarFecha,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller:
                          observacionesController,
                      enabled: !guardando,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Observaciones',
                        hintText:
                            'Ejemplo: Buen rendimiento',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(Icons.notes),
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
                          final duracion =
                              int.tryParse(
                            duracionController.text
                                .trim(),
                          );

                          if (rutinaSeleccionada ==
                                  null ||
                              rutinaSeleccionada!.id ==
                                  null) {
                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Seleccione una rutina.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (duracion == null ||
                              duracion <= 0) {
                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingrese una duración válida.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (duracion > 600) {
                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(
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
                            final fecha =
                                fechaParaBaseDeDatos(
                              fechaSeleccionada,
                            );

                            if (esEdicion) {
                              if (entrenamiento.id ==
                                  null) {
                                throw const ApiException(
                                  'El entrenamiento no tiene identificador.',
                                );
                              }

                              await ApiService.instance
                                  .updateTraining(
                                entrenamientoId:
                                    entrenamiento.id!,
                                rutinaId:
                                    rutinaSeleccionada!
                                        .id!,
                                fecha: fecha,
                                duracionMinutos:
                                    duracion,
                                observaciones:
                                    observacionesController
                                        .text
                                        .trim(),
                              );
                            } else {
                              await ApiService.instance
                                  .createTraining(
                                rutinaId:
                                    rutinaSeleccionada!
                                        .id!,
                                fecha: fecha,
                                duracionMinutos:
                                    duracion,
                                observaciones:
                                    observacionesController
                                        .text
                                        .trim(),
                              );
                            }

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.pop(
                              dialogContext,
                              true,
                            );
                          } on ApiException catch (
                              error) {
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

    duracionController.dispose();
    observacionesController.dispose();

    if (guardado != true) {
      return;
    }

    await cargarDatos();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          esEdicion
              ? 'Entrenamiento actualizado correctamente.'
              : 'Entrenamiento registrado correctamente.',
        ),
      ),
    );
  }

  Future<void> confirmarEliminacion(
    TrainingModel entrenamiento,
  ) async {
    if (entrenamiento.id == null) {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Eliminar entrenamiento'),
          content: Text(
            '¿Deseas eliminar el entrenamiento '
            '"${entrenamiento.nombreRutina}"?',
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

    if (confirmar != true) {
      return;
    }

    try {
      await ApiService.instance.deleteTraining(
        entrenamientoId: entrenamiento.id!,
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

  Widget construirContenido() {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (rutinas.isEmpty) {
      return RefreshIndicator(
        onRefresh: cargarDatos,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 140),
            Icon(
              Icons.fitness_center,
              size: 80,
              color: Colors.deepPurple,
            ),
            SizedBox(height: 20),
            Text(
              'Primero debes crear una rutina.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (entrenamientos.isEmpty) {
      return RefreshIndicator(
        onRefresh: cargarDatos,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 140),
            Icon(
              Icons.calendar_month,
              size: 80,
              color: Colors.deepPurple,
            ),
            SizedBox(height: 20),
            Text(
              'Todavía no tienes entrenamientos registrados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
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
                child:
                    Icon(Icons.fitness_center),
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
                  entrenamiento.observaciones
                      .isNotEmpty,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Mis entrenamientos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: cargarDatos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: construirContenido(),
      floatingActionButton: rutinas.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                mostrarFormulario();
              },
              icon: const Icon(Icons.add),
              label: const Text(
                'Registrar entrenamiento',
              ),
            ),
    );
  }
}