import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database_helper.dart';
import '../models/weight_model.dart';

class WeightScreen extends StatefulWidget {
  final int usuarioId;

  const WeightScreen({
    super.key,
    required this.usuarioId,
  });

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  List<WeightModel> registros = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarPesos();
  }

  Future<void> cargarPesos() async {
    try {
      final resultado =
          await DatabaseHelper.instance.getWeightsByUser(
        widget.usuarioId,
      );

      if (!mounted) return;

      setState(() {
        registros = resultado;
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
            'No se pudieron cargar los registros de peso.',
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
    WeightModel? registro,
  }) async {
    final pesoController = TextEditingController(
      text: registro?.peso.toStringAsFixed(1) ?? '',
    );

    DateTime fechaSeleccionada = registro == null
        ? DateTime.now()
        : DateTime.tryParse(registro.fecha) ?? DateTime.now();

    final esEdicion = registro != null;

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
                firstDate: DateTime(2000),
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
                    ? 'Editar registro de peso'
                    : 'Registrar peso',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: pesoController,
                      enabled: !guardando,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d{0,3}([.,]\d{0,2})?$'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Peso corporal',
                        hintText: 'Ejemplo: 72.5',
                        suffixText: 'kg',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.monitor_weight),
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
                          final textoPeso = pesoController.text
                              .trim()
                              .replaceAll(',', '.');

                          final peso = double.tryParse(textoPeso);

                          if (peso == null) {
                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingrese un peso válido.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (peso < 20 || peso > 400) {
                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingrese un peso entre 20 y 400 kg.',
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
                              final registroActualizado =
                                  registro.copyWith(
                                peso: peso,
                                fecha: fecha,
                              );

                              await DatabaseHelper.instance
                                  .updateWeight(
                                registroActualizado,
                              );
                            } else {
                              final nuevoRegistro = WeightModel(
                                usuarioId: widget.usuarioId,
                                peso: peso,
                                fecha: fecha,
                              );

                              await DatabaseHelper.instance
                                  .insertWeight(
                                nuevoRegistro,
                              );
                            }

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            await Future<void>.delayed(
                              const Duration(milliseconds: 250),
                            );

                            if (!mounted) return;

                            await cargarPesos();

                            if (!mounted) return;

                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  esEdicion
                                      ? 'Peso actualizado correctamente.'
                                      : 'Peso registrado correctamente.',
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
                                  'No se pudo guardar el peso.',
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

    pesoController.dispose();
  }

  Future<void> confirmarEliminacion(
    WeightModel registro,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar registro'),
          content: Text(
            '¿Deseas eliminar el registro de '
            '${registro.peso.toStringAsFixed(1)} kg?',
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

    if (confirmar != true || registro.id == null) {
      return;
    }

    try {
      await DatabaseHelper.instance.deleteWeight(
        registro.id!,
        widget.usuarioId,
      );

      await cargarPesos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro eliminado correctamente.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar el registro.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi peso'),
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : registros.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.monitor_weight_outlined,
                          size: 80,
                          color: Colors.deepPurple,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Todavía no tienes registros de peso.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 17),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: cargarPesos,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: registros.length,
                    itemBuilder: (context, index) {
                      final registro = registros[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.monitor_weight),
                          ),
                          title: Text(
                            '${registro.peso.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            fechaParaMostrar(registro.fecha),
                          ),
                          onTap: () {
                            mostrarFormulario(registro: registro);
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (opcion) {
                              if (opcion == 'editar') {
                                mostrarFormulario(
                                  registro: registro,
                                );
                              } else if (opcion == 'eliminar') {
                                confirmarEliminacion(registro);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          mostrarFormulario();
        },
        icon: const Icon(Icons.add),
        label: const Text('Registrar peso'),
      ),
    );
  }
}