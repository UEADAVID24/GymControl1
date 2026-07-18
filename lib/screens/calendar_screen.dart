import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/training_model.dart';
import '../services/api_service.dart';

class CalendarScreen extends StatefulWidget {
  final int usuarioId;

  const CalendarScreen({
    super.key,
    required this.usuarioId,
  });

  @override
  State<CalendarScreen> createState() =>
      _CalendarScreenState();
}

class _CalendarScreenState
    extends State<CalendarScreen> {
  List<TrainingModel> entrenamientos = [];

  DateTime diaSeleccionado = DateTime.now();
  DateTime diaEnfocado = DateTime.now();

  CalendarFormat formatoCalendario =
      CalendarFormat.month;

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarEntrenamientos();
  }

  Future<void> cargarEntrenamientos() async {
    try {
      final resultado =
          await ApiService.instance.getTrainings();

      resultado.sort(
        (a, b) {
          final comparacionFecha =
              a.fecha.compareTo(b.fecha);

          if (comparacionFecha != 0) {
            return comparacionFecha;
          }

          return (a.id ?? 0).compareTo(
            b.id ?? 0,
          );
        },
      );

      if (!mounted) return;

      setState(() {
        entrenamientos = resultado;
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

  DateTime normalizarFecha(DateTime fecha) {
    return DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
    );
  }

  List<TrainingModel> entrenamientosDelDia(
    DateTime fecha,
  ) {
    final fechaNormalizada =
        normalizarFecha(fecha);

    final resultado =
        entrenamientos.where((entrenamiento) {
      final fechaEntrenamiento =
          DateTime.tryParse(entrenamiento.fecha);

      if (fechaEntrenamiento == null) {
        return false;
      }

      return isSameDay(
        fechaNormalizada,
        normalizarFecha(fechaEntrenamiento),
      );
    }).toList();

    resultado.sort(
      (a, b) =>
          (b.id ?? 0).compareTo(a.id ?? 0),
    );

    return resultado;
  }

  String fechaParaMostrar(DateTime fecha) {
    final dia =
        fecha.day.toString().padLeft(2, '0');

    final mes =
        fecha.month.toString().padLeft(2, '0');

    final anio = fecha.year.toString();

    return '$dia/$mes/$anio';
  }

  String nombreMes(int mes) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    if (mes < 1 || mes > 12) {
      return '';
    }

    return meses[mes - 1];
  }

  @override
  Widget build(BuildContext context) {
    final entrenamientosSeleccionados =
        entrenamientosDelDia(diaSeleccionado);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: cargarEntrenamientos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: cargarEntrenamientos,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(12),
                      child:
                          TableCalendar<TrainingModel>(
                        firstDay:
                            DateTime(2020, 1, 1),
                        lastDay:
                            DateTime(2035, 12, 31),
                        focusedDay: diaEnfocado,
                        calendarFormat:
                            formatoCalendario,

                        selectedDayPredicate: (dia) {
                          return isSameDay(
                            diaSeleccionado,
                            dia,
                          );
                        },

                        eventLoader:
                            entrenamientosDelDia,

                        onDaySelected: (
                          diaSeleccionadoNuevo,
                          diaEnfocadoNuevo,
                        ) {
                          setState(() {
                            diaSeleccionado =
                                diaSeleccionadoNuevo;

                            diaEnfocado =
                                diaEnfocadoNuevo;
                          });
                        },

                        onPageChanged: (dia) {
                          diaEnfocado = dia;
                        },

                        onFormatChanged: (formato) {
                          setState(() {
                            formatoCalendario =
                                formato;
                          });
                        },

                        headerStyle: HeaderStyle(
                          titleCentered: true,
                          formatButtonVisible: false,
                          formatButtonShowsNext:
                              false,
                          formatButtonDecoration:
                              BoxDecoration(
                            border: Border.all(
                              color:
                                  Colors.deepPurple,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                          formatButtonTextStyle:
                              const TextStyle(
                            color:
                                Colors.deepPurple,
                          ),
                          titleTextFormatter:
                              (fecha, locale) {
                            return '${nombreMes(fecha.month)} '
                                '${fecha.year}';
                          },
                        ),

                        daysOfWeekStyle:
                            const DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                          weekendStyle: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Colors.deepPurple,
                          ),
                        ),

                        calendarStyle:
                            CalendarStyle(
                          outsideDaysVisible: false,

                          todayDecoration:
                              BoxDecoration(
                            color: Colors
                                .deepPurple.shade100,
                            shape: BoxShape.circle,
                          ),

                          todayTextStyle:
                              const TextStyle(
                            color:
                                Colors.deepPurple,
                            fontWeight:
                                FontWeight.bold,
                          ),

                          selectedDecoration:
                              const BoxDecoration(
                            color: Colors.deepPurple,
                            shape: BoxShape.circle,
                          ),

                          selectedTextStyle:
                              const TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.bold,
                          ),

                          markerDecoration:
                              const BoxDecoration(
                            color: Colors.deepPurple,
                            shape: BoxShape.circle,
                          ),

                          markersMaxCount: 3,
                        ),

                        calendarBuilders:
                            CalendarBuilders(
                          dowBuilder:
                              (context, dia) {
                            const nombres = [
                              'L',
                              'M',
                              'M',
                              'J',
                              'V',
                              'S',
                              'D',
                            ];

                            final indice =
                                dia.weekday - 1;

                            return Center(
                              child: Text(
                                nombres[indice],
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  color:
                                      dia.weekday >=
                                              6
                                          ? Colors
                                              .deepPurple
                                          : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Text(
                    fechaParaMostrar(
                      diaSeleccionado,
                    ),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    entrenamientosSeleccionados
                            .isEmpty
                        ? 'No hay entrenamientos este día.'
                        : '${entrenamientosSeleccionados.length} '
                            '${entrenamientosSeleccionados.length == 1 ? 'entrenamiento' : 'entrenamientos'}',
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (entrenamientosSeleccionados
                      .isEmpty)
                    const Card(
                      child: Padding(
                        padding:
                            EdgeInsets.all(28),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 65,
                              color:
                                  Colors.deepPurple,
                            ),
                            SizedBox(height: 14),
                            Text(
                              'No registraste entrenamientos en esta fecha.',
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...entrenamientosSeleccionados
                        .map(
                      (entrenamiento) {
                        return Card(
                          margin:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: ListTile(
                            leading:
                                const CircleAvatar(
                              child: Icon(
                                Icons
                                    .fitness_center,
                              ),
                            ),
                            title: Text(
                              entrenamiento
                                  .nombreRutina,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${entrenamiento.duracionMinutos} min'
                              '${entrenamiento.observaciones.isEmpty ? '' : '\n${entrenamiento.observaciones}'}',
                            ),
                            isThreeLine:
                                entrenamiento
                                    .observaciones
                                    .isNotEmpty,
                            trailing:
                                const Icon(
                              Icons.check_circle,
                              color:
                                  Colors.deepPurple,
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }
}