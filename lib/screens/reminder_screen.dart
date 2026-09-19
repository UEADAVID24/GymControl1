import 'package:flutter/material.dart';

import '../models/reminder_model.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class ReminderScreen extends StatefulWidget {
  final int usuarioId;

  const ReminderScreen({
    super.key,
    required this.usuarioId,
  });

  @override
  State<ReminderScreen> createState() =>
      _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
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
      final recordatorios =
          await ApiService.instance.getReminders();

      if (!mounted) return;

      setState(() {
        _recordatorios = recordatorios;
        _cargando = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
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

  String _obtenerNombreDia(int diaSemana) {
    if (diaSemana < 1 || diaSemana > 7) {
      return 'Día no válido';
    }

    return _diasSemana[diaSemana - 1];
  }

  String _formatearHora(int hora, int minuto) {
    return TimeOfDay(
      hour: hora,
      minute: minuto,
    ).format(context);
  }
Future<bool> _solicitarPermisoNotificaciones() async {
  PermissionStatus estado = await Permission.notification.status;

  if (estado.isGranted) {
    return true;
  }

  if (estado.isPermanentlyDenied || estado.isRestricted) {
    if (!mounted) return false;

    await _mostrarAjustesNotificaciones();
    return false;
  }

  if (!mounted) return false;

  final continuar = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Permiso de notificaciones'),
        content: const Text(
          'GymControl necesita permiso para enviarte recordatorios '
          'de tus rutinas y entrenamientos. Puedes guardar y consultar '
          'tus recordatorios aunque no concedas este permiso.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Continuar'),
          ),
        ],
      );
    },
  );

  if (continuar != true) {
    if (!mounted) return false;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No se activaron las notificaciones. '
          'Puedes continuar usando tus recordatorios normalmente.',
        ),
      ),
    );

    return false;
  }

  estado = await Permission.notification.request();

  if (estado.isGranted) {
    return true;
  }

  if (estado.isPermanentlyDenied || estado.isRestricted) {
    if (!mounted) return false;

    await _mostrarAjustesNotificaciones();
    return false;
  }

  if (!mounted) return false;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Permiso de notificaciones denegado. '
        'El recordatorio puede guardarse, pero no generará una notificación.',
      ),
    ),
  );

  return false;
}

Future<void> _mostrarAjustesNotificaciones() async {
  if (!mounted) return;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Notificaciones bloqueadas'),
        content: const Text(
          'Las notificaciones están desactivadas para GymControl. '
          'Para recibir avisos debes habilitarlas desde los ajustes '
          'del dispositivo. Tus recordatorios seguirán disponibles '
          'aunque no habilites este permiso.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await openAppSettings();
            },
            icon: const Icon(Icons.settings),
            label: const Text('Abrir ajustes'),
          ),
        ],
      );
    },
  );
}
Future<void> _programarNotificacion(
  ReminderModel recordatorio,
) async {
  if (recordatorio.id == null || !recordatorio.activo) {
    return;
  }

  final permisoConcedido =
      await _solicitarPermisoNotificaciones();

  if (!permisoConcedido) {
    return;
  }

  await _notificationService.scheduleWeeklyNotification(
    id: recordatorio.id!,
    title: recordatorio.titulo,
    body: recordatorio.mensaje.isEmpty
        ? 'Es momento de realizar tu entrenamiento.'
        : recordatorio.mensaje,
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

    final esEdicion = recordatorio != null;

    final guardado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool guardando = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                esEdicion
                    ? 'Editar recordatorio'
                    : 'Nuevo recordatorio',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tituloController,
                      enabled: !guardando,
                      maxLength: 100,
                      textCapitalization:
                          TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: mensajeController,
                      enabled: !guardando,
                      maxLines: 3,
                      maxLength: 300,
                      textCapitalization:
                          TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Mensaje',
                        prefixIcon: Icon(
                          Icons.message_outlined,
                        ),
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: diaSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Día de la semana',
                        prefixIcon: Icon(
                          Icons.calendar_today,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(
                        _diasSemana.length,
                        (index) {
                          return DropdownMenuItem<int>(
                            value: index + 1,
                            child: Text(
                              _diasSemana[index],
                            ),
                          );
                        },
                      ),
                      onChanged: guardando
                          ? null
                          : (value) {
                              if (value == null) return;

                              setDialogState(() {
                                diaSeleccionado = value;
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.access_time,
                      ),
                      title: const Text('Hora'),
                      subtitle: Text(
                        horaSeleccionada.format(
                          dialogContext,
                        ),
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: guardando
                          ? null
                          : () async {
                              final nuevaHora =
                                  await showTimePicker(
                                context: dialogContext,
                                initialTime:
                                    horaSeleccionada,
                              );

                              if (nuevaHora == null) return;

                              setDialogState(() {
                                horaSeleccionada =
                                    nuevaHora;
                              });
                            },
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
                          final titulo =
                              tituloController.text.trim();

                          final mensaje =
                              mensajeController.text.trim();

                          if (titulo.isEmpty) {
                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingrese un título para el recordatorio.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            guardando = true;
                          });

                          try {
                            ReminderModel recordatorioGuardado;

                            if (esEdicion) {
                              if (recordatorio.id == null) {
                                throw const ApiException(
                                  'El recordatorio no tiene identificador.',
                                );
                              }

                              recordatorioGuardado =
                                  await ApiService.instance
                                      .updateReminder(
                                recordatorioId:
                                    recordatorio.id!,
                                titulo: titulo,
                                mensaje: mensaje,
                                diaSemana:
                                    diaSeleccionado,
                                hora:
                                    horaSeleccionada.hour,
                                minuto:
                                    horaSeleccionada.minute,
                                activo:
                                    recordatorio.activo,
                              );
                            } else {
                              recordatorioGuardado =
                                  await ApiService.instance
                                      .createReminder(
                                titulo: titulo,
                                mensaje: mensaje,
                                diaSemana:
                                    diaSeleccionado,
                                hora:
                                    horaSeleccionada.hour,
                                minuto:
                                    horaSeleccionada.minute,
                                activo: true,
                              );
                            }

                            if (recordatorioGuardado.activo) {
                              await _programarNotificacion(
                                recordatorioGuardado,
                              );
                            } else if (recordatorioGuardado.id !=
                                null) {
                              await _notificationService
                                  .cancelNotification(
                                recordatorioGuardado.id!,
                              );
                            }

                            if (!dialogContext.mounted) return;

                            Navigator.pop(
                              dialogContext,
                              true,
                            );
                          } on ApiException catch (error) {
                            setDialogState(() {
                              guardando = false;
                            });

                            if (!dialogContext.mounted) return;

                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(
                              SnackBar(
                                content: Text(error.message),
                              ),
                            );
                          } catch (error) {
                            setDialogState(() {
                              guardando = false;
                            });

                            if (!dialogContext.mounted) return;

                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'No se pudo guardar o programar el recordatorio: $error',
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

    tituloController.dispose();
    mensajeController.dispose();

    if (guardado != true) return;

    await _cargarRecordatorios();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          esEdicion
              ? 'Recordatorio actualizado correctamente.'
              : 'Recordatorio guardado y programado.',
        ),
      ),
    );
  }

  Future<void> _cambiarEstado(
    ReminderModel recordatorio,
    bool nuevoEstado,
  ) async {
    if (recordatorio.id == null) return;

    try {
      final actualizado =
          await ApiService.instance.updateReminderStatus(
        recordatorioId: recordatorio.id!,
        activo: nuevoEstado,
      );

      if (actualizado.activo) {
        await _programarNotificacion(actualizado);
      } else {
        await _notificationService.cancelNotification(
          actualizado.id!,
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
          title: const Text(
            'Eliminar recordatorio',
          ),
          content: Text(
            '¿Deseas eliminar el recordatorio '
            '"${recordatorio.titulo}"?',
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

    if (confirmar != true) return;

    try {
      await _notificationService.cancelNotification(
        recordatorio.id!,
      );

      await ApiService.instance.deleteReminder(
        recordatorioId: recordatorio.id!,
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

  Widget _construirTarjeta(
    ReminderModel recordatorio,
  ) {
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
          crossAxisAlignment:
              CrossAxisAlignment.start,
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
              style:
                  Theme.of(context).textTheme.bodySmall,
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
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargarRecordatorios,
            icon: const Icon(Icons.refresh),
          ),
          if (_recordatorios.isNotEmpty)
            IconButton(
              tooltip: 'Probar notificación',
              onPressed: () {
                _probarNotificacion(
                  _recordatorios.first,
                );
              },
              icon: const Icon(
                Icons.notification_add,
              ),
            ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
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
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 120),
                        Icon(
                          Icons.notifications_none,
                          size: 80,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No tienes recordatorios.',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Presiona el botón Agregar para crear uno.',
                          textAlign:
                              TextAlign.center,
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.all(16),
                      itemCount:
                          _recordatorios.length,
                      itemBuilder:
                          (context, index) {
                        return _construirTarjeta(
                          _recordatorios[index],
                        );
                      },
                    ),
            ),
    );
  }
}