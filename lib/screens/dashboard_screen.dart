import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/weight_model.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'reminder_screen.dart';
import 'routine_screen.dart';
import 'training_screen.dart';
import 'weight_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int usuarioId;
  final String nombreUsuario;

  const DashboardScreen({
    super.key,
    required this.usuarioId,
    required this.nombreUsuario,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  int _totalRutinas = 0;
  int _totalEjercicios = 0;
  int _totalEntrenamientos = 0;
  double? _pesoActual;

  bool _cargandoResumen = true;

  @override
  void initState() {
    super.initState();
    _cargarResumen();
  }

  Future<void> _cargarResumen() async {
    try {
      final rutinas = await _databaseHelper.getRoutinesByUser(
        widget.usuarioId,
      );

      int totalEjercicios = 0;

      for (final rutina in rutinas) {
        if (rutina.id != null) {
          totalEjercicios +=
              await _databaseHelper.countExercisesByRoutine(
            rutina.id!,
          );
        }
      }

      final totalEntrenamientos =
          await _databaseHelper.countTrainingsByUser(
        widget.usuarioId,
      );

      final pesos = await _databaseHelper.getWeightsByUser(
        widget.usuarioId,
      );

      double? pesoActual;

      if (pesos.isNotEmpty) {
        pesoActual = _obtenerPesoMasReciente(pesos);
      }

      if (!mounted) return;

      setState(() {
        _totalRutinas = rutinas.length;
        _totalEjercicios = totalEjercicios;
        _totalEntrenamientos = totalEntrenamientos;
        _pesoActual = pesoActual;
        _cargandoResumen = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _cargandoResumen = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo cargar el resumen: $error',
          ),
        ),
      );
    }
  }

  double _obtenerPesoMasReciente(
    List<WeightModel> pesos,
  ) {
    final listaOrdenada = List<WeightModel>.from(pesos);

    listaOrdenada.sort(
      (a, b) {
        final fechaA = DateTime.tryParse(a.fecha);
        final fechaB = DateTime.tryParse(b.fecha);

        if (fechaA == null || fechaB == null) {
          return 0;
        }

        return fechaB.compareTo(fechaA);
      },
    );

    return listaOrdenada.first.peso;
  }

  String _formatearPeso() {
    if (_pesoActual == null) {
      return '--';
    }

    if (_pesoActual! % 1 == 0) {
      return '${_pesoActual!.toInt()} kg';
    }

    return '${_pesoActual!.toStringAsFixed(1)} kg';
  }

  Future<void> _abrirPantalla(
    Widget pantalla,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => pantalla,
      ),
    );

    await _cargarResumen();
  }

  void _cerrarSesion() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }

  Widget _construirResumen() {
    if (_cargandoResumen) {
      return const SizedBox(
        height: 110,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SizedBox(
      height: 125,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          SummaryCard(
            icon: Icons.fitness_center,
            value: _totalRutinas.toString(),
            label: 'Rutinas',
          ),
          const SizedBox(width: 12),
          SummaryCard(
            icon: Icons.sports_gymnastics,
            value: _totalEjercicios.toString(),
            label: 'Ejercicios',
          ),
          const SizedBox(width: 12),
          SummaryCard(
            icon: Icons.calendar_month,
            value: _totalEntrenamientos.toString(),
            label: 'Entrenamientos',
          ),
          const SizedBox(width: 12),
          SummaryCard(
            icon: Icons.monitor_weight,
            value: _formatearPeso(),
            label: 'Peso actual',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GymControl'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Actualizar resumen',
            onPressed: _cargarResumen,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarResumen,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '¡Bienvenido, ${widget.nombreUsuario}!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Este es el resumen de tu actividad en GymControl.',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 22),

              _construirResumen(),

              const SizedBox(height: 26),

              const Text(
                'Módulos',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.05,
                children: [
                  DashboardOption(
                    icon: Icons.fitness_center,
                    title: 'Rutinas',
                    onTap: () {
                      _abrirPantalla(
                        RoutineScreen(
                          usuarioId: widget.usuarioId,
                        ),
                      );
                    },
                  ),
                  DashboardOption(
                    icon: Icons.calendar_month,
                    title: 'Entrenamientos',
                    onTap: () {
                      _abrirPantalla(
                        TrainingScreen(
                          usuarioId: widget.usuarioId,
                        ),
                      );
                    },
                  ),
                  DashboardOption(
                    icon: Icons.event,
                    title: 'Calendario',
                    onTap: () {
                      _abrirPantalla(
                        CalendarScreen(
                          usuarioId: widget.usuarioId,
                        ),
                      );
                    },
                  ),
                  DashboardOption(
                    icon: Icons.notifications_active,
                    title: 'Recordatorios',
                    onTap: () {
                      _abrirPantalla(
                        ReminderScreen(
                          usuarioId: widget.usuarioId,
                        ),
                      );
                    },
                  ),
                  DashboardOption(
                    icon: Icons.show_chart,
                    title: 'Progreso',
                    onTap: () {
                      _abrirPantalla(
                        ProgressScreen(
                          usuarioId: widget.usuarioId,
                        ),
                      );
                    },
                  ),
                  DashboardOption(
                    icon: Icons.monitor_weight,
                    title: 'Peso',
                    onTap: () {
                      _abrirPantalla(
                        WeightScreen(
                          usuarioId: widget.usuarioId,
                        ),
                      );
                    },
                  ),
                  DashboardOption(
                    icon: Icons.person,
                    title: 'Perfil',
                    onTap: () {
                      _abrirPantalla(
                        ProfileScreen(
                          usuarioId: widget.usuarioId,
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cerrarSesion,
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const SummaryCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28,
            color: Theme.of(context)
                .colorScheme
                .onPrimaryContainer,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const DashboardOption({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 50,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}