import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/weight_model.dart';
import '../services/api_service.dart';

class WeightScreen extends StatefulWidget {
  final int usuarioId;

  const WeightScreen({
    super.key,
    required this.usuarioId,
  });

  @override
  State<WeightScreen> createState() =>
      _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  List<WeightModel> registros = [];

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarPesos();
  }

  // =========================
  // CARGAR PESOS DESDE RENDER
  // =========================

  Future<void> cargarPesos() async {
    try {
      final resultado =
          await ApiService.instance.getWeights();

      resultado.sort(
        (a, b) {
          final comparacionFecha =
              b.fecha.compareTo(a.fecha);

          if (comparacionFecha != 0) {
            return comparacionFecha;
          }

          return (b.id ?? 0).compareTo(
            a.id ?? 0,
          );
        },
      );

      if (!mounted) return;

      setState(() {
        registros = resultado;
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
    } catch (error) {
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

  // =========================
  // FORMATO DE FECHAS
  // =========================

  String fechaParaBaseDeDatos(
    DateTime fecha,
  ) {
    final year =
        fecha.year.toString().padLeft(4, '0');

    final month =
        fecha.month.toString().padLeft(2, '0');

    final day =
        fecha.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String fechaParaMostrar(
    String fecha,
  ) {
    final partes = fecha.split('-');

    if (partes.length != 3) {
      return fecha;
    }

    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  // =========================
  // CREAR O EDITAR PESO
  // =========================

  Future<void> mostrarFormulario({
    WeightModel? registro,
  }) async {
    final pesoController =
        TextEditingController(
      text: registro?.peso.toStringAsFixed(1) ??
          '',
    );

    DateTime fechaSeleccionada =
        registro == null
            ? DateTime.now()
            : DateTime.tryParse(
                  registro.fecha,
                ) ??
                DateTime.now();

    final esEdicion = registro != null;

    final guardado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool guardando = false;

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            Future<void> seleccionarFecha()
                async {
              final nuevaFecha =
                  await showDatePicker(
                context: dialogContext,
                initialDate:
                    fechaSeleccionada,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );

              if (nuevaFecha != null) {
                setDialogState(() {
                  fechaSeleccionada =
                      nuevaFecha;
                });
              }
            }

            return AlertDialog(
              title: Text(
                esEdicion
                    ? 'Editar registro de peso'
                    : 'Registrar peso',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    TextField(
                      controller:
                          pesoController,
                      enabled: !guardando,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .allow(
                          RegExp(
                            r'^\d{0,3}([.,]\d{0,2})?$',
                          ),
                        ),
                      ],
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Peso corporal',
                        hintText:
                            'Ejemplo: 72.5',
                        suffixText: 'kg',
                        border:
                            OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.monitor_weight,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_month,
                      ),
                      title:
                          const Text('Fecha'),
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
                          final textoPeso =
                              pesoController
                                  .text
                                  .trim()
                                  .replaceAll(
                                    ',',
                                    '.',
                                  );

                          final peso =
                              double.tryParse(
                            textoPeso,
                          );

                          if (peso == null ||
                              peso <= 0 ||
                              peso > 500) {
                            ScaffoldMessenger
                                    .of(
                              dialogContext,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingrese un peso válido entre 1 y 500 kg.',
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
                              if (registro.id ==
                                  null) {
                                throw const ApiException(
                                  'El registro no tiene identificador.',
                                );
                              }

                              await ApiService
                                  .instance
                                  .updateWeight(
                                pesoId:
                                    registro.id!,
                                peso: peso,
                                fecha: fecha,
                              );
                            } else {
                              await ApiService
                                  .instance
                                  .createWeight(
                                peso: peso,
                                fecha: fecha,
                              );
                            }

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
                          } catch (error) {
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
                                  'No se pudo conectar con el servidor: $error',
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

    pesoController.dispose();

    if (guardado != true) {
      return;
    }

    setState(() {
      cargando = true;
    });

    await cargarPesos();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          esEdicion
              ? 'Peso actualizado correctamente.'
              : 'Peso registrado correctamente.',
        ),
      ),
    );
  }

  // =========================
  // ELIMINAR PESO
  // =========================

  Future<void> confirmarEliminacion(
    WeightModel registro,
  ) async {
    if (registro.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El registro no tiene identificador.',
          ),
        ),
      );

      return;
    }

    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Eliminar registro',
          ),
          content: Text(
            '¿Deseas eliminar el registro de '
            '${registro.peso.toStringAsFixed(1)} kg?',
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
                'Eliminar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      await ApiService.instance.deleteWeight(
        pesoId: registro.id!,
      );

      setState(() {
        cargando = true;
      });

      await cargarPesos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registro eliminado correctamente.',
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
    } catch (error) {
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

  Future<void> actualizarPantalla() async {
    setState(() {
      cargando = true;
    });

    await cargarPesos();
  }

  // =========================
  // INTERFAZ
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi peso',
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed:
                cargando ? null : actualizarPantalla,
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
          : registros.isEmpty
              ? RefreshIndicator(
                  onRefresh: cargarPesos,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 140),
                      Padding(
                        padding:
                            EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons
                                  .monitor_weight_outlined,
                              size: 80,
                              color:
                                  Colors.deepPurple,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Todavía no tienes registros de peso.',
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                fontSize: 17,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Presiona Registrar peso para guardar tu primer registro.',
                              textAlign:
                                  TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: cargarPesos,
                  child: ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    itemCount:
                        registros.length,
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final registro =
                          registros[index];

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: ListTile(
                          leading:
                              const CircleAvatar(
                            child: Icon(
                              Icons.monitor_weight,
                            ),
                          ),
                          title: Text(
                            '${registro.peso.toStringAsFixed(1)} kg',
                            style:
                                const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            fechaParaMostrar(
                              registro.fecha,
                            ),
                          ),
                          onTap: () {
                            mostrarFormulario(
                              registro: registro,
                            );
                          },
                          trailing:
                              PopupMenuButton<
                                  String>(
                            onSelected:
                                (opcion) {
                              if (opcion ==
                                  'editar') {
                                mostrarFormulario(
                                  registro:
                                      registro,
                                );
                              } else if (opcion ==
                                  'eliminar') {
                                confirmarEliminacion(
                                  registro,
                                );
                              }
                            },
                            itemBuilder:
                                (context) {
                              return const [
                                PopupMenuItem(
                                  value:
                                      'editar',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit,
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        'Editar',
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value:
                                      'eliminar',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        'Eliminar',
                                      ),
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
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Registrar peso',
        ),
      ),
    );
  }
}