import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise_model.dart';
import '../models/reminder_model.dart';
import '../models/routine_model.dart';
import '../models/training_model.dart';
import '../models/weight_model.dart';

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  static const String apiRootUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:5000',
);

static const String baseUrl = '$apiRootUrl/api/v1';

Future<Map<String, dynamic>> verificarConexionApi() async {
  final response = await http.get(
    Uri.parse('$baseUrl/health'),
  );

  final data = _decodeResponse(response);

  if (response.statusCode != 200) {
    throw ApiException(
      data['message']?.toString() ??
          'No se pudo conectar con la API.',
      statusCode: response.statusCode,
    );
  }

  return {
    ...data,
    'message':
        '${data['service'] ?? 'GymControl Backend'} - estado: ${data['status'] ?? 'ok'}',
  };
}

  // =========================
  // AUTENTICACIÓN
  // =========================

  Future<Map<String, dynamic>> register({
    required String nombre,
    required String correo,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'password': password,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 201) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo registrar el usuario.',
        statusCode: response.statusCode,
      );
    }

    return data;
  }

  Future<Map<String, dynamic>> login({
    required String correo,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'correo': correo,
        'password': password,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo iniciar sesión.',
        statusCode: response.statusCode,
      );
    }

    final accessToken =
        data['access_token']?.toString();

    final refreshToken =
        data['refresh_token']?.toString();

    final usuario = data['usuario'];

    if (accessToken == null ||
        usuario is! Map<String, dynamic>) {
      throw const ApiException(
        'La respuesta del servidor no es válida.',
      );
    }

    final preferences =
        await SharedPreferences.getInstance();

    await preferences.setString(
      'access_token',
      accessToken,
    );

    if (refreshToken != null) {
      await preferences.setString(
        'refresh_token',
        refreshToken,
      );
    }

    final usuarioId = usuario['id'];

    if (usuarioId is! int) {
      throw const ApiException(
        'El identificador del usuario no es válido.',
      );
    }

    await preferences.setInt(
      'usuario_id',
      usuarioId,
    );

    await preferences.setString(
      'usuario_nombre',
      usuario['nombre'].toString(),
    );

    await preferences.setString(
      'usuario_correo',
      usuario['correo'].toString(),
    );

    return data;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _authenticatedGet(
      '$baseUrl/auth/me',
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo obtener el perfil.',
        statusCode: response.statusCode,
      );
    }

    return data;
  }


  Future<Map<String, dynamic>> updateProfile({
    required String nombre,
    required String correo,
  }) async {
    final response = await _authenticatedRequest(
      url: '$baseUrl/auth/me',
      method: 'PUT',
      body: {
        'nombre': nombre,
        'correo': correo,
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo actualizar el perfil.',
        statusCode: response.statusCode,
      );
    }

    final usuario = data['usuario'];

    if (usuario is! Map<String, dynamic>) {
      throw const ApiException(
        'El servidor no devolvió el usuario actualizado.',
      );
    }

    final preferences =
        await SharedPreferences.getInstance();

    final usuarioId = usuario['id'];

    if (usuarioId is int) {
      await preferences.setInt(
        'usuario_id',
        usuarioId,
      );
    }

    await preferences.setString(
      'usuario_nombre',
      usuario['nombre']?.toString() ?? '',
    );

    await preferences.setString(
      'usuario_correo',
      usuario['correo']?.toString() ?? '',
    );

    return data;
  }

  Future<void> changePassword({
    required String passwordActual,
    required String passwordNueva,
  }) async {
    final response = await _authenticatedRequest(
      url: '$baseUrl/auth/password',
      method: 'PUT',
      body: {
        'password_actual': passwordActual,
        'password_nueva': passwordNueva,
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo cambiar la contraseña.',
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> deleteAccount({
    required String password,
  }) async {
    final response = await _authenticatedRequest(
      url: '$baseUrl/auth/me',
      method: 'DELETE',
      body: {
        'password': password,
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo eliminar la cuenta.',
        statusCode: response.statusCode,
      );
    }

    await logout();
  }

  // =========================
  // RUTINAS
  // =========================

  Future<List<RoutineModel>> getRoutines() async {
    final response = await _authenticatedGet(
      '$baseUrl/rutinas/',
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudieron cargar las rutinas.',
        statusCode: response.statusCode,
      );
    }

    final lista = data['rutinas'];

    if (lista is! List) {
      return [];
    }

    return lista
        .whereType<Map<String, dynamic>>()
        .map(RoutineModel.fromMap)
        .toList();
  }

  Future<RoutineModel> createRoutine({
    required String nombre,
    required String descripcion,
  }) async {
    final response = await _authenticatedRequest(
      url: '$baseUrl/rutinas/',
      method: 'POST',
      body: {
        'nombre': nombre,
        'descripcion': descripcion,
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 201) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo crear la rutina.',
        statusCode: response.statusCode,
      );
    }

    final rutina = data['rutina'];

    if (rutina is! Map<String, dynamic>) {
      throw const ApiException(
        'El servidor no devolvió la rutina creada.',
      );
    }

    return RoutineModel.fromMap(rutina);
  }

  Future<RoutineModel> updateRoutine({
    required int rutinaId,
    required String nombre,
    required String descripcion,
  }) async {
    final response = await _authenticatedRequest(
      url: '$baseUrl/rutinas/$rutinaId',
      method: 'PUT',
      body: {
        'nombre': nombre,
        'descripcion': descripcion,
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo actualizar la rutina.',
        statusCode: response.statusCode,
      );
    }

    final rutina = data['rutina'];

    if (rutina is! Map<String, dynamic>) {
      throw const ApiException(
        'El servidor no devolvió la rutina actualizada.',
      );
    }

    return RoutineModel.fromMap(rutina);
  }

  Future<void> deleteRoutine({
    required int rutinaId,
  }) async {
    final response = await _authenticatedRequest(
      url: '$baseUrl/rutinas/$rutinaId',
      method: 'DELETE',
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo eliminar la rutina.',
        statusCode: response.statusCode,
      );
    }
  }

  // =========================
  // EJERCICIOS
  // =========================

  Future<List<ExerciseModel>> getExercises({
    required int rutinaId,
  }) async {
    final response = await _authenticatedGet(
      '$baseUrl/rutinas/$rutinaId/ejercicios',
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudieron cargar los ejercicios.',
        statusCode: response.statusCode,
      );
    }

    final lista = data['ejercicios'];

    if (lista is! List) {
      return [];
    }

    return lista
        .whereType<Map<String, dynamic>>()
        .map(ExerciseModel.fromMap)
        .toList();
  }

  Future<ExerciseModel> createExercise({
    required int rutinaId,
    required String nombre,
    required int series,
    required int repeticiones,
    required double peso,
  }) async {
    final response = await _authenticatedRequest(
      url: '$baseUrl/rutinas/$rutinaId/ejercicios',
      method: 'POST',
      body: {
        'nombre': nombre,
        'series': series,
        'repeticiones': repeticiones,
        'peso': peso,
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 201) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo crear el ejercicio.',
        statusCode: response.statusCode,
      );
    }

    final ejercicio = data['ejercicio'];

    if (ejercicio is! Map<String, dynamic>) {
      throw const ApiException(
        'El servidor no devolvió el ejercicio creado.',
      );
    }

    return ExerciseModel.fromMap(ejercicio);
  }

  Future<ExerciseModel> updateExercise({
    required int ejercicioId,
    required String nombre,
    required int series,
    required int repeticiones,
    required double peso,
  }) async {
    final response = await _authenticatedRequest(
      url: '$baseUrl/ejercicios/$ejercicioId',
      method: 'PUT',
      body: {
        'nombre': nombre,
        'series': series,
        'repeticiones': repeticiones,
        'peso': peso,
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo actualizar el ejercicio.',
        statusCode: response.statusCode,
      );
    }

    final ejercicio = data['ejercicio'];

    if (ejercicio is! Map<String, dynamic>) {
      throw const ApiException(
        'El servidor no devolvió el ejercicio actualizado.',
      );
    }

    return ExerciseModel.fromMap(ejercicio);
  }

  Future<void> deleteExercise({
    required int ejercicioId,
  }) async {
    final response = await _authenticatedRequest(
      url: '$baseUrl/ejercicios/$ejercicioId',
      method: 'DELETE',
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo eliminar el ejercicio.',
        statusCode: response.statusCode,
      );
    }
  }

  // =========================
  // ENTRENAMIENTOS
  // =========================

  Future<List<TrainingModel>> getTrainings() async {
    final response = await _authenticatedGet(
      '$baseUrl/entrenamientos/',
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudieron cargar los entrenamientos.',
        statusCode: response.statusCode,
      );
    }

    final lista = data['entrenamientos'];

    if (lista is! List) {
      return [];
    }

    return lista
        .whereType<Map<String, dynamic>>()
        .map(TrainingModel.fromMap)
        .toList();
  }

  Future<TrainingModel> createTraining({
    required int rutinaId,
    required String fecha,
    required int duracionMinutos,
    required String observaciones,
  }) async {
    final response = await _authenticatedRequest(
      url: '$baseUrl/entrenamientos/',
      method: 'POST',
      body: {
        'rutina_id': rutinaId,
        'fecha': fecha,
        'duracion_minutos': duracionMinutos,
        'observaciones': observaciones,
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 201) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo registrar el entrenamiento.',
        statusCode: response.statusCode,
      );
    }

    final entrenamiento = data['entrenamiento'];

    if (entrenamiento is! Map<String, dynamic>) {
      throw const ApiException(
        'El servidor no devolvió el entrenamiento creado.',
      );
    }

    return TrainingModel.fromMap(
      entrenamiento,
    );
  }

  Future<TrainingModel> updateTraining({
    required int entrenamientoId,
    required int rutinaId,
    required String fecha,
    required int duracionMinutos,
    required String observaciones,
  }) async {
    final response = await _authenticatedRequest(
      url:
          '$baseUrl/entrenamientos/$entrenamientoId',
      method: 'PUT',
      body: {
        'rutina_id': rutinaId,
        'fecha': fecha,
        'duracion_minutos': duracionMinutos,
        'observaciones': observaciones,
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo actualizar el entrenamiento.',
        statusCode: response.statusCode,
      );
    }

    final entrenamiento = data['entrenamiento'];

    if (entrenamiento is! Map<String, dynamic>) {
      throw const ApiException(
        'El servidor no devolvió el entrenamiento actualizado.',
      );
    }

    return TrainingModel.fromMap(
      entrenamiento,
    );
  }

  Future<void> deleteTraining({
    required int entrenamientoId,
  }) async {
    final response = await _authenticatedRequest(
      url:
          '$baseUrl/entrenamientos/$entrenamientoId',
      method: 'DELETE',
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo eliminar el entrenamiento.',
        statusCode: response.statusCode,
      );
    }
  }


  // =========================
  // PESOS
  // =========================

  Future<List<WeightModel>> getWeights() async {
    final response = await _authenticatedGet(
      '$baseUrl/pesos/',
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudieron cargar los registros de peso.',
        statusCode: response.statusCode,
      );
    }

    final lista = data['pesos'];

    if (lista is! List) {
      return [];
    }

    return lista
        .whereType<Map<String, dynamic>>()
        .map(WeightModel.fromMap)
        .toList();
  }

  Future<WeightModel> createWeight({
    required double peso,
    required String fecha,
  }) async {
    final response = await _authenticatedRequest(
      url: '$baseUrl/pesos/',
      method: 'POST',
      body: {
        'peso': peso,
        'fecha': fecha,
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 201) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo registrar el peso.',
        statusCode: response.statusCode,
      );
    }

    final registroPeso = data['peso'];

    if (registroPeso is! Map<String, dynamic>) {
      throw const ApiException(
        'El servidor no devolvió el registro de peso creado.',
      );
    }

    return WeightModel.fromMap(registroPeso);
  }

  Future<WeightModel> updateWeight({
    required int pesoId,
    required double peso,
    required String fecha,
  }) async {
    final response = await _authenticatedRequest(
      url: '$baseUrl/pesos/$pesoId',
      method: 'PUT',
      body: {
        'peso': peso,
        'fecha': fecha,
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo actualizar el peso.',
        statusCode: response.statusCode,
      );
    }

    final registroPeso = data['peso'];

    if (registroPeso is! Map<String, dynamic>) {
      throw const ApiException(
        'El servidor no devolvió el registro de peso actualizado.',
      );
    }

    return WeightModel.fromMap(registroPeso);
  }

  Future<void> deleteWeight({
    required int pesoId,
  }) async {
    final response = await _authenticatedRequest(
      url: '$baseUrl/pesos/$pesoId',
      method: 'DELETE',
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo eliminar el peso.',
        statusCode: response.statusCode,
      );
    }
  }

  // =========================
  // RECORDATORIOS
  // =========================

  Future<List<ReminderModel>> getReminders() async {
    final response = await _authenticatedGet(
      '$baseUrl/recordatorios/',
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudieron cargar los recordatorios.',
        statusCode: response.statusCode,
      );
    }

    final lista = data['recordatorios'];

    if (lista is! List) {
      return [];
    }

    return lista
        .whereType<Map<String, dynamic>>()
        .map(ReminderModel.fromMap)
        .toList();
  }

  Future<ReminderModel> createReminder({
    required String titulo,
    required String mensaje,
    required int diaSemana,
    required int hora,
    required int minuto,
    required bool activo,
  }) async {
    final response = await _authenticatedRequest(
      url: '$baseUrl/recordatorios/',
      method: 'POST',
      body: {
        'titulo': titulo,
        'mensaje': mensaje,
        'dia_semana': diaSemana,
        'hora': hora,
        'minuto': minuto,
        'activo': activo,
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 201) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo crear el recordatorio.',
        statusCode: response.statusCode,
      );
    }

    final recordatorio = data['recordatorio'];

    if (recordatorio is! Map<String, dynamic>) {
      throw const ApiException(
        'El servidor no devolvió el recordatorio creado.',
      );
    }

    return ReminderModel.fromMap(recordatorio);
  }

  Future<ReminderModel> updateReminder({
    required int recordatorioId,
    required String titulo,
    required String mensaje,
    required int diaSemana,
    required int hora,
    required int minuto,
    required bool activo,
  }) async {
    final response = await _authenticatedRequest(
      url: '$baseUrl/recordatorios/$recordatorioId',
      method: 'PUT',
      body: {
        'titulo': titulo,
        'mensaje': mensaje,
        'dia_semana': diaSemana,
        'hora': hora,
        'minuto': minuto,
        'activo': activo,
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo actualizar el recordatorio.',
        statusCode: response.statusCode,
      );
    }

    final recordatorio = data['recordatorio'];

    if (recordatorio is! Map<String, dynamic>) {
      throw const ApiException(
        'El servidor no devolvió el recordatorio actualizado.',
      );
    }

    return ReminderModel.fromMap(recordatorio);
  }

  Future<ReminderModel> updateReminderStatus({
    required int recordatorioId,
    required bool activo,
  }) async {
    final response = await _authenticatedRequest(
      url: '$baseUrl/recordatorios/$recordatorioId/estado',
      method: 'PATCH',
      body: {
        'activo': activo,
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo cambiar el estado del recordatorio.',
        statusCode: response.statusCode,
      );
    }

    final recordatorio = data['recordatorio'];

    if (recordatorio is! Map<String, dynamic>) {
      throw const ApiException(
        'El servidor no devolvió el recordatorio actualizado.',
      );
    }

    return ReminderModel.fromMap(recordatorio);
  }

  Future<void> deleteReminder({
    required int recordatorioId,
  }) async {
    final response = await _authenticatedRequest(
      url: '$baseUrl/recordatorios/$recordatorioId',
      method: 'DELETE',
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            'No se pudo eliminar el recordatorio.',
        statusCode: response.statusCode,
      );
    }
  }


  // =========================
  // OPTIMIZACIÓN SEMANA 8
  // =========================

  Future<Map<String, dynamic>> runN1Diagnostic() async {
    final response = await _authenticatedGet(
      '$baseUrl/optimizacion/diagnostico-n1',
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            data['msg']?.toString() ??
            'No se pudo ejecutar el diagnóstico N+1.',
        statusCode: response.statusCode,
      );
    }

    return data;
  }

  Future<Map<String, dynamic>> createOptimizationTask() async {
    final response = await _authenticatedRequest(
      url: '$baseUrl/optimizacion/tareas/resumen',
      method: 'POST',
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 202) {
      throw ApiException(
        data['message']?.toString() ??
            data['msg']?.toString() ??
            'No se pudo enviar la tarea al worker.',
        statusCode: response.statusCode,
      );
    }

    return data;
  }

  Future<Map<String, dynamic>> getOptimizationTask({
    required String taskId,
  }) async {
    final response = await _authenticatedGet(
      '$baseUrl/optimizacion/tareas/$taskId',
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message']?.toString() ??
            data['msg']?.toString() ??
            'No se pudo consultar la tarea.',
        statusCode: response.statusCode,
      );
    }

    return data;
  }

  // =========================
  // PETICIONES AUTENTICADAS
  // =========================

  Future<http.Response> _authenticatedGet(
    String url,
  ) async {
    final token = await _requireAccessToken();

    return http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  Future<http.Response> _authenticatedRequest({
    required String url,
    required String method,
    Map<String, dynamic>? body,
  }) async {
    final token = await _requireAccessToken();

    final request = http.Request(
      method,
      Uri.parse(url),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Content-Type':
          'application/json; charset=utf-8',
    });

    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamedResponse =
        await request.send();

    return http.Response.fromStream(
      streamedResponse,
    );
  }

  Future<String> _requireAccessToken() async {
    final token = await getAccessToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'No existe una sesión iniciada.',
        statusCode: 401,
      );
    }

    return token;
  }

  Future<String?> getAccessToken() async {
    final preferences =
        await SharedPreferences.getInstance();

    return preferences.getString(
      'access_token',
    );
  }

  Future<void> logout() async {
    final preferences =
        await SharedPreferences.getInstance();

    await preferences.remove('access_token');
    await preferences.remove('refresh_token');
    await preferences.remove('usuario_id');
    await preferences.remove('usuario_nombre');
    await preferences.remove('usuario_correo');
  }

  Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    if (response.body.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        'message':
            'Respuesta inesperada del servidor.',
      };
    } catch (_) {
      return {
        'message':
            'El servidor devolvió una respuesta inválida.',
      };
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() => message;
}