import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';

class ReminderScreen extends StatefulWidget {
  final int usuarioId;

  const ReminderScreen({
    super.key,
    required this.usuarioId,
  });

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final NotificationService _notificationService =
      NotificationService.instance;

  List<ReminderModel> _recordatorios = [];
  bool _cargando = true;

  final List<String> _diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _cargarRecordatorios();
  }

  Future<void> _cargarRecordatorios() async {
    try {
      final recordatorios = await _databaseHelper.getRemindersByUser(
        widget.usuarioId,
      );

      if (!mounted) return;

      setState(() {
        _recordatorios = recordatorios;
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
            'No se pudieron cargar los recordatorios: $error',
          ),
        ),
      );
    }
  }

  String _obtenerNombreDia(int diaSemana) {
    if (diaSemana < 1 || diaSemana > 7) {
      return 'Día no válido';
    }

    return _diasSemana[diaSemana - 1];
  }

  String _formatearHora(int hora, int minuto) {
    final timeOfDay = TimeOfDay(
      hour: hora,
      minute: minuto,
    );

    return timeOfDay.format(context);
  }

  Future<void> _programarNotificacion(
    ReminderModel recordatorio,
  ) async {
    if (recordatorio.id == null || !recordatorio.activo) {
      return;
    }

    await _notificationService.scheduleWeeklyNotification(
      id: recordatorio.id!,
      title: recordatorio.titulo,
      body: recordatorio.mensaje,
      dayOfWeek: recordatorio.diaSemana,
      hour: recordatorio.hora,
      minute: recordatorio.minuto,
    );
  }

  Future<void> _mostrarFormulario({
    ReminderModel? recordatorio,
  }) async {
    final tituloController = TextEditingController(
      text: recordatorio?.titulo ?? '',
    );

    final mensajeController = TextEditingController(
      text: recordatorio?.mensaje ?? '',
    );

    int diaSeleccionado = recordatorio?.diaSemana ?? 1;

    TimeOfDay horaSeleccionada = TimeOfDay(
      hour: recordatorio?.hora ?? 8,
      minute: recordatorio?.minuto ?? 0,
    );

    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                recordatorio == null
                    ? 'Nuevo recordatorio'
                    : 'Editar recordatorio',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tituloController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: mensajeController,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Mensaje',
                        prefixIcon: Icon(Icons.message_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: diaSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Día de la semana',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      items: List.generate(
                        _diasSemana.length,
                        (index) {
                          return DropdownMenuItem<int>(
                            value: index + 1,
                            child: Text(_diasSemana[index]),
                          );
                        },
                      ),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          diaSeleccionado = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: const Text('Hora'),
                      subtitle: Text(
                        horaSeleccionada.format(context),
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final nuevaHora = await showTimePicker(
                          context: context,
                          initialTime: horaSeleccionada,
                        );

                        if (nuevaHora == null) return;

                        setDialogState(() {
                          horaSeleccionada = nuevaHora;
                        });
                      },
                    ),
                  ],
                ),
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
                    final titulo = tituloController.text.trim();

                    if (titulo.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ingrese un título para el recordatorio.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (resultado != true) {
      tituloController.dispose();
      mensajeController.dispose();
      return;
    }

    final recordatorioPreparado = ReminderModel(
      id: recordatorio?.id,
      usuarioId: widget.usuarioId,
      titulo: tituloController.text.trim(),
      mensaje: mensajeController.text.trim(),
      diaSemana: diaSeleccionado,
      hora: horaSeleccionada.hour,
      minuto: horaSeleccionada.minute,
      activo: recordatorio?.activo ?? true,
    );

    try {
      ReminderModel recordatorioGuardado;

      if (recordatorio == null) {
        final nuevoId = await _databaseHelper.insertReminder(
          recordatorioPreparado,
        );

        recordatorioGuardado = ReminderModel(
          id: nuevoId,
          usuarioId: recordatorioPreparado.usuarioId,
          titulo: recordatorioPreparado.titulo,
          mensaje: recordatorioPreparado.mensaje,
          diaSemana: recordatorioPreparado.diaSemana,
          hora: recordatorioPreparado.hora,
          minuto: recordatorioPreparado.minuto,
          activo: recordatorioPreparado.activo,
        );
      } else {
        await _databaseHelper.updateReminder(
          recordatorioPreparado,
        );

        recordatorioGuardado = recordatorioPreparado;
      }

      if (recordatorioGuardado.activo) {
        await _programarNotificacion(recordatorioGuardado);
      } else if (recordatorioGuardado.id != null) {
        await _notificationService.cancelNotification(
          recordatorioGuardado.id!,
        );
      }

      await _cargarRecordatorios();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            recordatorio == null
                ? 'Recordatorio guardado y programado.'
                : 'Recordatorio actualizado correctamente.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar o programar el recordatorio: $error',
          ),
        ),
      );
    } finally {
      tituloController.dispose();
      mensajeController.dispose();
    }
  }

  Future<void> _cambiarEstado(
    ReminderModel recordatorio,
    bool nuevoEstado,
  ) async {
    if (recordatorio.id == null) return;

    try {
      await _databaseHelper.updateReminderStatus(
        recordatorio.id!,
        widget.usuarioId,
        nuevoEstado,
      );

      if (nuevoEstado) {
        final recordatorioActivo = ReminderModel(
          id: recordatorio.id,
          usuarioId: recordatorio.usuarioId,
          titulo: recordatorio.titulo,
          mensaje: recordatorio.mensaje,
          diaSemana: recordatorio.diaSemana,
          hora: recordatorio.hora,
          minuto: recordatorio.minuto,
          activo: true,
        );

        await _programarNotificacion(recordatorioActivo);
      } else {
        await _notificationService.cancelNotification(
          recordatorio.id!,
        );
      }

      await _cargarRecordatorios();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nuevoEstado
                ? 'Recordatorio activado.'
                : 'Recordatorio desactivado.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo cambiar el estado: $error',
          ),
        ),
      );
    }
  }

  Future<void> _eliminarRecordatorio(
    ReminderModel recordatorio,
  ) async {
    if (recordatorio.id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar recordatorio'),
          content: Text(
            '¿Deseas eliminar el recordatorio "${recordatorio.titulo}"?',
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
      await _notificationService.cancelNotification(
        recordatorio.id!,
      );

      await _databaseHelper.deleteReminder(
        recordatorio.id!,
        widget.usuarioId,
      );

      await _cargarRecordatorios();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Recordatorio y notificación eliminados.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar el recordatorio: $error',
          ),
        ),
      );
    }
  }

  Future<void> _probarNotificacion(
    ReminderModel recordatorio,
  ) async {
    if (recordatorio.id == null) return;

    try {
      await _notificationService.showInstantNotification(
        id: recordatorio.id! + 100000,
        title: recordatorio.titulo,
        body: recordatorio.mensaje.isEmpty
            ? 'Es momento de realizar tu entrenamiento.'
            : recordatorio.mensaje,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo mostrar la notificación de prueba: $error',
          ),
        ),
      );
    }
  }

  Widget _construirTarjeta(ReminderModel recordatorio) {
    final mensaje = recordatorio.mensaje.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          child: Icon(
            recordatorio.activo
                ? Icons.notifications_active
                : Icons.notifications_off,
          ),
        ),
        title: Text(
          recordatorio.titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              '${_obtenerNombreDia(recordatorio.diaSemana)} · '
              '${_formatearHora(recordatorio.hora, recordatorio.minuto)}',
            ),
            if (mensaje.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(mensaje),
            ],
            const SizedBox(height: 8),
            Text(
              'Toca para editar · Mantén presionado para eliminar',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Switch(
          value: recordatorio.activo,
          onChanged: (value) {
            _cambiarEstado(
              recordatorio,
              value,
            );
          },
        ),
        onTap: () {
          _mostrarFormulario(
            recordatorio: recordatorio,
          );
        },
        onLongPress: () {
          _eliminarRecordatorio(recordatorio);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorios'),
        actions: [
          if (_recordatorios.isNotEmpty)
            IconButton(
              tooltip: 'Probar notificación',
              onPressed: () {
                _probarNotificacion(_recordatorios.first);
              },
              icon: const Icon(Icons.notification_add),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _mostrarFormulario();
        },
        icon: const Icon(Icons.add_alert),
        label: const Text('Agregar'),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _cargarRecordatorios,
              child: _recordatorios.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 120),
                        Icon(
                          Icons.notifications_none,
                          size: 80,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No tienes recordatorios.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Presiona el botón Agregar para crear uno.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _recordatorios.length,
                      itemBuilder: (context, index) {
                        return _construirTarjeta(
                          _recordatorios[index],
                        );
                      },
                    ),
            ),
    );
  }
}