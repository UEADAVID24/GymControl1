import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class OptimizationScreen extends StatefulWidget {
  const OptimizationScreen({
    super.key,
  });

  @override
  State<OptimizationScreen> createState() =>
      _OptimizationScreenState();
}

class _OptimizationScreenState
    extends State<OptimizationScreen> {
  Map<String, dynamic>? _diagnostico;
  Map<String, dynamic>? _tarea;

  bool _ejecutandoDiagnostico = false;
  bool _creandoTarea = false;
  bool _consultandoTarea = false;

  Timer? _temporizador;
  String? _taskId;

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  Future<void> _ejecutarDiagnostico() async {
    setState(() {
      _ejecutandoDiagnostico = true;
      _diagnostico = null;
    });

    try {
      final resultado =
          await ApiService.instance.runN1Diagnostic();

      if (!mounted) return;

      setState(() {
        _diagnostico = resultado;
        _ejecutandoDiagnostico = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _ejecutandoDiagnostico = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _ejecutandoDiagnostico = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo analizar el rendimiento: $error',
          ),
        ),
      );
    }
  }

  Future<void> _crearTarea() async {
    _temporizador?.cancel();

    setState(() {
      _creandoTarea = true;
      _tarea = null;
      _taskId = null;
    });

    try {
      final respuesta =
          await ApiService.instance.createOptimizationTask();

      final taskId = respuesta['task_id']?.toString();

      if (taskId == null || taskId.isEmpty) {
        throw const ApiException(
          'El servidor no devolvió el identificador del proceso.',
        );
      }

      if (!mounted) return;

      setState(() {
        _taskId = taskId;
        _creandoTarea = false;
        _tarea = {
          'estado': respuesta['estado'] ?? 'pendiente',
          'id': taskId,
          'tiempo_respuesta_ms':
              respuesta['tiempo_respuesta_ms'],
        };
      });

      await _consultarTarea();

      _temporizador = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _consultarTarea(),
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _creandoTarea = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _creandoTarea = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo procesar el resumen: $error',
          ),
        ),
      );
    }
  }

  Future<void> _consultarTarea() async {
    final taskId = _taskId;

    if (taskId == null || _consultandoTarea) {
      return;
    }

    _consultandoTarea = true;

    try {
      final respuesta =
          await ApiService.instance.getOptimizationTask(
        taskId: taskId,
      );

      final tarea = respuesta['tarea'];

      if (tarea is! Map<String, dynamic>) {
        throw const ApiException(
          'La respuesta del proceso no es válida.',
        );
      }

      if (!mounted) return;

      setState(() {
        _tarea = tarea;
      });

      final estado = tarea['estado']?.toString();

      if (estado == 'completada' ||
          estado == 'fallida') {
        _temporizador?.cancel();
      }
    } on ApiException catch (error) {
      _temporizador?.cancel();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } finally {
      _consultandoTarea = false;
    }
  }

  int _entero(
    Map<String, dynamic>? mapa,
    String clave,
  ) {
    final valor = mapa?[clave];

    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    return int.tryParse(
          valor?.toString() ?? '',
        ) ??
        0;
  }

  double _decimal(
    Map<String, dynamic>? mapa,
    String clave,
  ) {
    final valor = mapa?[clave];

    if (valor is num) {
      return valor.toDouble();
    }

    return double.tryParse(
          valor?.toString() ?? '',
        ) ??
        0;
  }

  Widget _tarjeta({
    required String titulo,
    required String valor,
    required IconData icono,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              size: 34,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              valor,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _diagnosticoWidget() {
    final diagnostico = _diagnostico;

    if (diagnostico == null) {
      return const Text(
        'Presiona el botón para analizar el rendimiento de las consultas.',
      );
    }

    final antes =
        diagnostico['antes'] is Map<String, dynamic>
            ? diagnostico['antes']
                as Map<String, dynamic>
            : <String, dynamic>{};

    final despues =
        diagnostico['despues']
                is Map<String, dynamic>
            ? diagnostico['despues']
                as Map<String, dynamic>
            : <String, dynamic>{};

    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.05,
          children: [
            _tarjeta(
              titulo: 'Consultas antes',
              valor:
                  '${_entero(antes, 'consultas_sql')}',
              icono: Icons.warning_amber,
            ),
            _tarjeta(
              titulo: 'Consultas después',
              valor:
                  '${_entero(despues, 'consultas_sql')}',
              icono: Icons.check_circle_outline,
            ),
            _tarjeta(
              titulo: 'Tiempo antes',
              valor:
                  '${_decimal(antes, 'tiempo_ms').toStringAsFixed(3)} ms',
              icono: Icons.timer_outlined,
            ),
            _tarjeta(
              titulo: 'Tiempo después',
              valor:
                  '${_decimal(despues, 'tiempo_ms').toStringAsFixed(3)} ms',
              icono: Icons.speed,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            title: const Text(
              'Consultas ahorradas',
            ),
            trailing: Text(
              '${diagnostico['consultas_ahorradas'] ?? 0}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text(
              'Mejora porcentual',
            ),
            trailing: Text(
              '${diagnostico['mejora_porcentual_consultas'] ?? 0} %',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tareaWidget() {
    final tarea = _tarea;

    if (tarea == null) {
      return const Text(
        'Presiona el botón para generar el resumen del sistema.',
      );
    }

    final estado =
        tarea['estado']?.toString() ?? 'desconocido';

    final resultado =
        tarea['resultado'] is Map<String, dynamic>
            ? tarea['resultado']
                as Map<String, dynamic>
            : <String, dynamic>{};

    return Column(
      children: [
        Card(
          child: ListTile(
            leading: Icon(
              estado == 'completada'
                  ? Icons.task_alt
                  : estado == 'fallida'
                      ? Icons.error_outline
                      : Icons.hourglass_top,
            ),
            title: const Text(
              'Estado del proceso',
            ),
            subtitle: Text(
              _taskId ?? '',
            ),
            trailing: Text(
              estado.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (estado == 'pendiente' ||
            estado == 'procesando')
          const LinearProgressIndicator(),
        if (estado == 'completada') ...[
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              _tarjeta(
                titulo: 'Rutinas',
                valor:
                    '${resultado['total_rutinas'] ?? 0}',
                icono: Icons.fitness_center,
              ),
              _tarjeta(
                titulo: 'Ejercicios',
                valor:
                    '${resultado['total_ejercicios'] ?? 0}',
                icono: Icons.sports_gymnastics,
              ),
              _tarjeta(
                titulo: 'Entrenamientos',
                valor:
                    '${resultado['total_entrenamientos'] ?? 0}',
                icono: Icons.calendar_month,
              ),
              _tarjeta(
                titulo: 'Peso actual',
                valor:
                    '${resultado['peso_actual'] ?? '--'} kg',
                icono: Icons.monitor_weight,
              ),
            ],
          ),
        ],
        if (estado == 'fallida')
          Padding(
            padding:
                const EdgeInsets.only(top: 12),
            child: Text(
              tarea['error']?.toString() ??
                  'El proceso falló.',
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Optimización',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Diagnóstico de rendimiento',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Analiza el rendimiento de las consultas optimizadas de la aplicación.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _ejecutandoDiagnostico
                ? null
                : _ejecutarDiagnostico,
            icon: _ejecutandoDiagnostico
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.analytics),
            label: Text(
              _ejecutandoDiagnostico
                  ? 'Analizando...'
                  : 'Analizar rendimiento',
            ),
          ),
          const SizedBox(height: 18),
          _diagnosticoWidget(),
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 20),
          const Text(
            'Procesamiento en segundo plano',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'El sistema procesa la información en segundo plano para mejorar el rendimiento.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed:
                _creandoTarea ? null : _crearTarea,
            icon: _creandoTarea
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(
              _creandoTarea
                  ? 'Procesando...'
                  : 'Procesar resumen',
            ),
          ),
          const SizedBox(height: 18),
          _tareaWidget(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}