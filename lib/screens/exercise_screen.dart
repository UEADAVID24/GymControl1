import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/exercise_model.dart';

class ExerciseScreen extends StatefulWidget {
  final int rutinaId;
  final String nombreRutina;

  const ExerciseScreen({
    super.key,
    required this.rutinaId,
    required this.nombreRutina,
  });

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<ExerciseModel> _ejercicios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarEjercicios();
  }

  Future<void> _cargarEjercicios() async {
    try {
      final resultado =
          await _databaseHelper.getExercisesByRoutine(widget.rutinaId);

      if (!mounted) return;

      setState(() {
        _ejercicios = resultado;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron cargar los ejercicios: $error',
          ),
        ),
      );
    }
  }

  Future<void> _mostrarFormulario({
    ExerciseModel? ejercicio,
  }) async {
    final nombreController = TextEditingController(
      text: ejercicio?.nombre ?? '',
    );

    final seriesController = TextEditingController(
      text: ejercicio?.series.toString() ?? '',
    );

    final repeticionesController = TextEditingController(
      text: ejercicio?.repeticiones.toString() ?? '',
    );

    final pesoController = TextEditingController(
      text: ejercicio == null
          ? ''
          : ejercicio.peso.toStringAsFixed(
              ejercicio.peso % 1 == 0 ? 0 : 1,
            ),
    );

    final esEdicion = ejercicio != null;

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool guardando = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                esEdicion
                    ? 'Editar ejercicio'
                    : 'Nuevo ejercicio',
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
                        labelText: 'Nombre del ejercicio',
                        prefixIcon: Icon(Icons.fitness_center),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: seriesController,
                      enabled: !guardando,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Series',
                        prefixIcon: Icon(Icons.repeat),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: repeticionesController,
                      enabled: !guardando,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Repeticiones',
                        prefixIcon: Icon(Icons.numbers),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: pesoController,
                      enabled: !guardando,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Peso en kg',
                        hintText: 'Ejemplo: 20',
                        prefixIcon: Icon(Icons.monitor_weight),
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
                          Navigator.pop(dialogContext, false);
                        },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          final nombre =
                              nombreController.text.trim();

                          final series = int.tryParse(
                            seriesController.text.trim(),
                          );

                          final repeticiones = int.tryParse(
                            repeticionesController.text.trim(),
                          );

                          final textoPeso = pesoController.text
                              .trim()
                              .replaceAll(',', '.');

                          final peso = textoPeso.isEmpty
                              ? 0.0
                              : double.tryParse(textoPeso);

                          if (nombre.isEmpty) {
                            ScaffoldMessenger.of(dialogContext)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingrese el nombre del ejercicio.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (series == null || series <= 0) {
                            ScaffoldMessenger.of(dialogContext)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingrese una cantidad válida de series.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (repeticiones == null ||
                              repeticiones <= 0) {
                            ScaffoldMessenger.of(dialogContext)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingrese una cantidad válida de repeticiones.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (peso == null || peso < 0) {
                            ScaffoldMessenger.of(dialogContext)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingrese un peso válido.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            guardando = true;
                          });

                          try {
                            final ejercicioGuardado =
                                ExerciseModel(
                              id: ejercicio?.id,
                              rutinaId: widget.rutinaId,
                              nombre: nombre,
                              series: series,
                              repeticiones: repeticiones,
                              peso: peso,
                            );

                            if (esEdicion) {
                              await _databaseHelper.updateExercise(
                                ejercicioGuardado,
                              );
                            } else {
                              await _databaseHelper.insertExercise(
                                ejercicioGuardado,
                              );
                            }

                            if (!mounted) return;

                            Navigator.pop(dialogContext, true);
                          } catch (error) {
                            setDialogState(() {
                              guardando = false;
                            });

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'No se pudo guardar el ejercicio: $error',
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

    nombreController.dispose();
    seriesController.dispose();
    repeticionesController.dispose();
    pesoController.dispose();

    if (resultado != true) return;

    await _cargarEjercicios();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          esEdicion
              ? 'Ejercicio actualizado correctamente.'
              : 'Ejercicio agregado correctamente.',
        ),
      ),
    );
  }

  Future<void> _confirmarEliminacion(
    ExerciseModel ejercicio,
  ) async {
    if (ejercicio.id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar ejercicio'),
          content: Text(
            '¿Deseas eliminar el ejercicio "${ejercicio.nombre}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _databaseHelper.deleteExercise(
        ejercicio.id!,
        widget.rutinaId,
      );

      await _cargarEjercicios();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ejercicio eliminado correctamente.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar el ejercicio: $error',
          ),
        ),
      );
    }
  }

  String _formatearPeso(double peso) {
    if (peso == 0) {
      return 'Sin peso';
    }

    if (peso % 1 == 0) {
      return '${peso.toInt()} kg';
    }

    return '${peso.toStringAsFixed(1)} kg';
  }

  Widget _construirTarjeta(
    ExerciseModel ejercicio,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: const CircleAvatar(
          child: Icon(Icons.fitness_center),
        ),
        title: Text(
          ejercicio.nombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${ejercicio.series} series × '
            '${ejercicio.repeticiones} repeticiones\n'
            'Peso: ${_formatearPeso(ejercicio.peso)}',
          ),
        ),
        isThreeLine: true,
        onTap: () {
          _mostrarFormulario(
            ejercicio: ejercicio,
          );
        },
        trailing: PopupMenuButton<String>(
          onSelected: (opcion) {
            if (opcion == 'editar') {
              _mostrarFormulario(
                ejercicio: ejercicio,
              );
            } else if (opcion == 'eliminar') {
              _confirmarEliminacion(ejercicio);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombreRutina),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _mostrarFormulario();
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar ejercicio'),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _cargarEjercicios,
              child: _ejercicios.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 120),
                        Icon(
                          Icons.fitness_center,
                          size: 80,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Esta rutina todavía no tiene ejercicios.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Presiona “Agregar ejercicio” para registrar uno.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _ejercicios.length,
                      itemBuilder: (context, index) {
                        return _construirTarjeta(
                          _ejercicios[index],
                        );
                      },
                    ),
            ),
    );
  }
}