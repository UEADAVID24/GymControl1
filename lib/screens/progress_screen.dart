import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/training_model.dart';
import '../models/weight_model.dart';

class ProgressScreen extends StatefulWidget {
  final int usuarioId;

  const ProgressScreen({
    super.key,
    required this.usuarioId,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<WeightModel> registrosPeso = [];
  List<TrainingModel> entrenamientos = [];

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarProgreso();
  }

  Future<void> cargarProgreso() async {
    try {
      final resultadoPesos =
          await DatabaseHelper.instance.getWeightsByUser(
        widget.usuarioId,
      );

      final resultadoEntrenamientos =
          await DatabaseHelper.instance.getTrainingsByUser(
        widget.usuarioId,
      );

      resultadoPesos.sort(
        (a, b) => a.fecha.compareTo(b.fecha),
      );

      resultadoEntrenamientos.sort(
        (a, b) {
          final comparacionFecha =
              b.fecha.compareTo(a.fecha);

          if (comparacionFecha != 0) {
            return comparacionFecha;
          }

          return (b.id ?? 0).compareTo(a.id ?? 0);
        },
      );

      if (!mounted) return;

      setState(() {
        registrosPeso = resultadoPesos;
        entrenamientos = resultadoEntrenamientos;
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
            'No se pudo cargar el progreso.',
          ),
        ),
      );
    }
  }

  String fechaCorta(String fecha) {
    final partes = fecha.split('-');

    if (partes.length != 3) {
      return fecha;
    }

    return '${partes[2]}/${partes[1]}';
  }

  String fechaCompleta(String fecha) {
    final partes = fecha.split('-');

    if (partes.length != 3) {
      return fecha;
    }

    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  double obtenerPesoMinimo() {
    if (registrosPeso.isEmpty) return 0;

    final minimo = registrosPeso
        .map((registro) => registro.peso)
        .reduce((a, b) => a < b ? a : b);

    return minimo - 5;
  }

  double obtenerPesoMaximo() {
    if (registrosPeso.isEmpty) return 100;

    final maximo = registrosPeso
        .map((registro) => registro.peso)
        .reduce((a, b) => a > b ? a : b);

    return maximo + 5;
  }

  double diferenciaPeso() {
    if (registrosPeso.length < 2) {
      return 0;
    }

    return registrosPeso.last.peso -
        registrosPeso.first.peso;
  }

  List<FlSpot> obtenerPuntos() {
    return List.generate(
      registrosPeso.length,
      (index) {
        return FlSpot(
          index.toDouble(),
          registrosPeso[index].peso,
        );
      },
    );
  }

  int obtenerTiempoTotal() {
    return entrenamientos.fold(
      0,
      (total, entrenamiento) =>
          total + entrenamiento.duracionMinutos,
    );
  }

  double obtenerPromedioDuracion() {
    if (entrenamientos.isEmpty) {
      return 0;
    }

    return obtenerTiempoTotal() /
        entrenamientos.length;
  }

  String obtenerRutinaMasRealizada() {
    if (entrenamientos.isEmpty) {
      return 'Sin datos';
    }

    final conteo = <String, int>{};

    for (final entrenamiento in entrenamientos) {
      conteo[entrenamiento.nombreRutina] =
          (conteo[entrenamiento.nombreRutina] ?? 0) + 1;
    }

    String rutinaMasRealizada = conteo.keys.first;
    int mayorCantidad =
        conteo[rutinaMasRealizada] ?? 0;

    conteo.forEach((rutina, cantidad) {
      if (cantidad > mayorCantidad) {
        rutinaMasRealizada = rutina;
        mayorCantidad = cantidad;
      }
    });

    return rutinaMasRealizada;
  }

  int obtenerDiasEntrenados() {
    return entrenamientos
        .map((entrenamiento) => entrenamiento.fecha)
        .toSet()
        .length;
  }

  int obtenerRachaActual() {
    if (entrenamientos.isEmpty) {
      return 0;
    }

    final fechas = entrenamientos
        .map(
          (entrenamiento) =>
              DateTime.tryParse(entrenamiento.fecha),
        )
        .whereType<DateTime>()
        .map(
          (fecha) => DateTime(
            fecha.year,
            fecha.month,
            fecha.day,
          ),
        )
        .toSet()
        .toList();

    fechas.sort(
      (a, b) => b.compareTo(a),
    );

    if (fechas.isEmpty) {
      return 0;
    }

    final ahora = DateTime.now();

    final hoy = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
    );

    final diferenciaInicial =
        hoy.difference(fechas.first).inDays;

    if (diferenciaInicial > 1) {
      return 0;
    }

    int racha = 1;

    for (int index = 0;
        index < fechas.length - 1;
        index++) {
      final diferencia = fechas[index]
          .difference(fechas[index + 1])
          .inDays;

      if (diferencia == 1) {
        racha++;
      } else if (diferencia > 1) {
        break;
      }
    }

    return racha;
  }

  @override
  Widget build(BuildContext context) {
    final diferencia = diferenciaPeso();

    final totalMinutos = obtenerTiempoTotal();
    final horas = totalMinutos ~/ 60;
    final minutosRestantes = totalMinutos % 60;

    final textoTiempoTotal = horas > 0
        ? '$horas h $minutosRestantes min'
        : '$minutosRestantes min';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi progreso'),
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: cargarProgreso,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Resumen de actividad',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Estas estadísticas se calculan con tus entrenamientos y registros de peso.',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _ResumenCard(
                          titulo: 'Entrenamientos',
                          valor:
                              '${entrenamientos.length}',
                          icono:
                              Icons.fitness_center,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ResumenCard(
                          titulo: 'Días entrenados',
                          valor:
                              '${obtenerDiasEntrenados()}',
                          icono:
                              Icons.calendar_month,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _ResumenCard(
                          titulo: 'Tiempo total',
                          valor: textoTiempoTotal,
                          icono: Icons.timer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ResumenCard(
                          titulo: 'Promedio',
                          valor:
                              '${obtenerPromedioDuracion().toStringAsFixed(0)} min',
                          icono: Icons.av_timer,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _ResumenCard(
                          titulo:
                              'Rutina frecuente',
                          valor:
                              obtenerRutinaMasRealizada(),
                          icono:
                              Icons.emoji_events,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ResumenCard(
                          titulo: 'Racha actual',
                          valor:
                              '${obtenerRachaActual()} días',
                          icono: Icons
                              .local_fire_department,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  if (entrenamientos.isNotEmpty) ...[
                    const Text(
                      'Último entrenamiento',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading:
                            const CircleAvatar(
                          child: Icon(
                            Icons.fitness_center,
                          ),
                        ),
                        title: Text(
                          entrenamientos
                              .first.nombreRutina,
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${fechaCompleta(entrenamientos.first.fecha)}'
                          ' • ${entrenamientos.first.duracionMinutos} min'
                          '${entrenamientos.first.observaciones.isEmpty ? '' : '\n${entrenamientos.first.observaciones}'}',
                        ),
                        isThreeLine:
                            entrenamientos
                                .first
                                .observaciones
                                .isNotEmpty,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  const Text(
                    'Evolución de tu peso',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'La gráfica muestra los cambios registrados a lo largo del tiempo.',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 24),

                  if (registrosPeso.isEmpty)
                    const Card(
                      child: Padding(
                        padding:
                            EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons
                                  .monitor_weight_outlined,
                              size: 65,
                              color:
                                  Colors.deepPurple,
                            ),
                            SizedBox(height: 14),
                            Text(
                              'Todavía no tienes registros de peso.',
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                fontSize: 17,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Registra tu peso para mostrar la gráfica.',
                              textAlign:
                                  TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _ResumenCard(
                            titulo: 'Peso inicial',
                            valor:
                                '${registrosPeso.first.peso.toStringAsFixed(1)} kg',
                            icono: Icons.flag,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ResumenCard(
                            titulo: 'Peso actual',
                            valor:
                                '${registrosPeso.last.peso.toStringAsFixed(1)} kg',
                            icono: Icons
                                .monitor_weight,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _ResumenCard(
                      titulo: 'Cambio total',
                      valor: diferencia == 0
                          ? 'Sin cambios'
                          : '${diferencia > 0 ? '+' : ''}'
                              '${diferencia.toStringAsFixed(1)} kg',
                      icono: diferencia <= 0
                          ? Icons.trending_down
                          : Icons.trending_up,
                    ),

                    const SizedBox(height: 28),

                    Card(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          24,
                          20,
                          16,
                        ),
                        child: SizedBox(
                          height: 300,
                          child: LineChart(
                            LineChartData(
                              minY:
                                  obtenerPesoMinimo(),
                              maxY:
                                  obtenerPesoMaximo(),
                              gridData:
                                  const FlGridData(
                                show: true,
                                drawVerticalLine:
                                    false,
                              ),
                              borderData:
                                  FlBorderData(
                                show: true,
                                border: Border.all(
                                  color: Colors
                                      .grey.shade300,
                                ),
                              ),
                              titlesData:
                                  FlTitlesData(
                                topTitles:
                                    const AxisTitles(
                                  sideTitles:
                                      SideTitles(
                                    showTitles:
                                        false,
                                  ),
                                ),
                                rightTitles:
                                    const AxisTitles(
                                  sideTitles:
                                      SideTitles(
                                    showTitles:
                                        false,
                                  ),
                                ),
                                leftTitles:
                                    AxisTitles(
                                  axisNameWidget:
                                      const Text(
                                    'kg',
                                  ),
                                  sideTitles:
                                      SideTitles(
                                    showTitles: true,
                                    reservedSize:
                                        42,
                                    interval: 5,
                                    getTitlesWidget:
                                        (
                                      value,
                                      meta,
                                    ) {
                                      return Text(
                                        value
                                            .toStringAsFixed(
                                          0,
                                        ),
                                        style:
                                            const TextStyle(
                                          fontSize:
                                              11,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles:
                                    AxisTitles(
                                  sideTitles:
                                      SideTitles(
                                    showTitles: true,
                                    reservedSize:
                                        38,
                                    interval: 1,
                                    getTitlesWidget:
                                        (
                                      value,
                                      meta,
                                    ) {
                                      final index =
                                          value.toInt();

                                      if (index < 0 ||
                                          index >=
                                              registrosPeso
                                                  .length) {
                                        return const SizedBox
                                            .shrink();
                                      }

                                      return Padding(
                                        padding:
                                            const EdgeInsets
                                                .only(
                                          top: 8,
                                        ),
                                        child: Text(
                                          fechaCorta(
                                            registrosPeso[
                                                    index]
                                                .fecha,
                                          ),
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                10,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              lineTouchData:
                                  LineTouchData(
                                touchTooltipData:
                                    LineTouchTooltipData(
                                  getTooltipItems:
                                      (
                                    touchedSpots,
                                  ) {
                                    return touchedSpots
                                        .map(
                                      (spot) {
                                        final index =
                                            spot.x
                                                .toInt();

                                        final registro =
                                            registrosPeso[
                                                index];

                                        return LineTooltipItem(
                                          '${registro.peso.toStringAsFixed(1)} kg\n'
                                          '${fechaCompleta(registro.fecha)}',
                                          const TextStyle(
                                            color:
                                                Colors.white,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ).toList();
                                  },
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots:
                                      obtenerPuntos(),
                                  isCurved: true,
                                  barWidth: 4,
                                  dotData:
                                      const FlDotData(
                                    show: true,
                                  ),
                                  belowBarData:
                                      BarAreaData(
                                    show: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Historial de peso',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...registrosPeso.reversed.map(
                      (registro) {
                        return Card(
                          child: ListTile(
                            leading:
                                const CircleAvatar(
                              child: Icon(
                                Icons
                                    .monitor_weight,
                              ),
                            ),
                            title: Text(
                              '${registro.peso.toStringAsFixed(1)} kg',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              fechaCompleta(
                                registro.fecha,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 28),

                  const Text(
                    'Historial de entrenamientos',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (entrenamientos.isEmpty)
                    const Card(
                      child: Padding(
                        padding:
                            EdgeInsets.all(24),
                        child: Text(
                          'Todavía no tienes entrenamientos registrados.',
                          textAlign:
                              TextAlign.center,
                          style:
                              TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  else
                    ...entrenamientos.map(
                      (entrenamiento) {
                        return Card(
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
                              '${fechaCompleta(entrenamiento.fecha)}'
                              ' • ${entrenamiento.duracionMinutos} min'
                              '${entrenamiento.observaciones.isEmpty ? '' : '\n${entrenamiento.observaciones}'}',
                            ),
                            isThreeLine:
                                entrenamiento
                                    .observaciones
                                    .isNotEmpty,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;

  const _ResumenCard({
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              size: 34,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 10),
            Text(
              titulo,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              valor,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}