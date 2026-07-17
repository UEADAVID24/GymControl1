import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/exercise_model.dart';
import '../models/reminder_model.dart';
import '../models/routine_model.dart';
import '../models/training_model.dart';
import '../models/user_model.dart';
import '../models/weight_model.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initializeDatabase();
    return _database!;
  }

  Future<Database> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'gymcontrol.db');

    return openDatabase(
      path,
      version: 6,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(
    Database database,
    int version,
  ) async {
    await database.execute('''
      CREATE TABLE usuarios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        correo TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    await _createRoutineTable(database);
    await _createWeightTable(database);
    await _createTrainingTable(database);
    await _createReminderTable(database);
    await _createExerciseTable(database);
  }

  Future<void> _upgradeDatabase(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createRoutineTable(database);
    }

    if (oldVersion < 3) {
      await _createWeightTable(database);
    }

    if (oldVersion < 4) {
      await _createTrainingTable(database);
    }

    if (oldVersion < 5) {
      await _createReminderTable(database);
    }

    if (oldVersion < 6) {
      await _createExerciseTable(database);
    }
  }

  Future<void> _createRoutineTable(Database database) async {
    await database.execute('''
      CREATE TABLE rutinas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        descripcion TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (usuario_id)
          REFERENCES usuarios(id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createWeightTable(Database database) async {
    await database.execute('''
      CREATE TABLE pesos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        peso REAL NOT NULL,
        fecha TEXT NOT NULL,
        FOREIGN KEY (usuario_id)
          REFERENCES usuarios(id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createTrainingTable(Database database) async {
    await database.execute('''
      CREATE TABLE entrenamientos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        rutina_id INTEGER,
        nombre_rutina TEXT NOT NULL,
        fecha TEXT NOT NULL,
        duracion_minutos INTEGER NOT NULL,
        observaciones TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (usuario_id)
          REFERENCES usuarios(id)
          ON DELETE CASCADE,
        FOREIGN KEY (rutina_id)
          REFERENCES rutinas(id)
          ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _createReminderTable(Database database) async {
    await database.execute('''
      CREATE TABLE recordatorios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        titulo TEXT NOT NULL,
        mensaje TEXT NOT NULL DEFAULT '',
        dia_semana INTEGER NOT NULL,
        hora INTEGER NOT NULL,
        minuto INTEGER NOT NULL,
        activo INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (usuario_id)
          REFERENCES usuarios(id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createExerciseTable(Database database) async {
    await database.execute('''
      CREATE TABLE ejercicios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rutina_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        series INTEGER NOT NULL,
        repeticiones INTEGER NOT NULL,
        peso REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (rutina_id)
          REFERENCES rutinas(id)
          ON DELETE CASCADE
      )
    ''');
  }

  // =========================
  // OPERACIONES DE USUARIOS
  // =========================

  Future<int> insertUser(UserModel user) async {
    final db = await database;

    return db.insert(
      'usuarios',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<UserModel?> getUserByEmail(String correo) async {
    final db = await database;

    final result = await db.query(
      'usuarios',
      where: 'correo = ?',
      whereArgs: [correo],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return UserModel.fromMap(result.first);
  }

  Future<UserModel?> getUserById(int usuarioId) async {
    final db = await database;

    final result = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [usuarioId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return UserModel.fromMap(result.first);
  }

  Future<List<UserModel>> getUsers() async {
    final db = await database;

    final result = await db.query(
      'usuarios',
      orderBy: 'nombre ASC',
    );

    return result.map(UserModel.fromMap).toList();
  }

  Future<int> updateUser(UserModel user) async {
    final db = await database;

    if (user.id == null) {
      throw ArgumentError(
        'El usuario debe tener un id para poder actualizarse.',
      );
    }

    return db.update(
      'usuarios',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> updateUserPassword(
    int usuarioId,
    String nuevaPassword,
  ) async {
    final db = await database;

    return db.update(
      'usuarios',
      {
        'password': nuevaPassword,
      },
      where: 'id = ?',
      whereArgs: [usuarioId],
    );
  }

  Future<int> deleteUser(int usuarioId) async {
    final db = await database;

    return db.delete(
      'usuarios',
      where: 'id = ?',
      whereArgs: [usuarioId],
    );
  }

  // =========================
  // OPERACIONES DE RUTINAS
  // =========================

  Future<int> insertRoutine(RoutineModel routine) async {
    final db = await database;

    return db.insert(
      'rutinas',
      routine.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<RoutineModel>> getRoutinesByUser(
    int usuarioId,
  ) async {
    final db = await database;

    final result = await db.query(
      'rutinas',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'id DESC',
    );

    return result.map(RoutineModel.fromMap).toList();
  }

  Future<int> updateRoutine(RoutineModel routine) async {
    final db = await database;

    if (routine.id == null) {
      throw ArgumentError(
        'La rutina debe tener un id para poder actualizarse.',
      );
    }

    return db.update(
      'rutinas',
      routine.toMap(),
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [
        routine.id,
        routine.usuarioId,
      ],
    );
  }

  Future<int> deleteRoutine(
    int routineId,
    int usuarioId,
  ) async {
    final db = await database;

    return db.delete(
      'rutinas',
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [
        routineId,
        usuarioId,
      ],
    );
  }


  // =========================
  // OPERACIONES DE EJERCICIOS
  // =========================

  Future<int> insertExercise(
    ExerciseModel exercise,
  ) async {
    final db = await database;

    return db.insert(
      'ejercicios',
      exercise.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<ExerciseModel>> getExercisesByRoutine(
    int rutinaId,
  ) async {
    final db = await database;

    final result = await db.query(
      'ejercicios',
      where: 'rutina_id = ?',
      whereArgs: [rutinaId],
      orderBy: 'id DESC',
    );

    return result.map(ExerciseModel.fromMap).toList();
  }

  Future<int> updateExercise(
    ExerciseModel exercise,
  ) async {
    final db = await database;

    if (exercise.id == null) {
      throw ArgumentError(
        'El ejercicio debe tener un id para actualizarse.',
      );
    }

    return db.update(
      'ejercicios',
      exercise.toMap(),
      where: 'id = ? AND rutina_id = ?',
      whereArgs: [
        exercise.id,
        exercise.rutinaId,
      ],
    );
  }

  Future<int> deleteExercise(
    int exerciseId,
    int rutinaId,
  ) async {
    final db = await database;

    return db.delete(
      'ejercicios',
      where: 'id = ? AND rutina_id = ?',
      whereArgs: [
        exerciseId,
        rutinaId,
      ],
    );
  }

  Future<int> countExercisesByRoutine(
    int rutinaId,
  ) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM ejercicios
      WHERE rutina_id = ?
      ''',
      [rutinaId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // =========================
  // OPERACIONES DE PESOS
  // =========================

  Future<int> insertWeight(WeightModel weight) async {
    final db = await database;

    return db.insert(
      'pesos',
      weight.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<WeightModel>> getWeightsByUser(
    int usuarioId,
  ) async {
    final db = await database;

    final result = await db.query(
      'pesos',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'fecha DESC, id DESC',
    );

    return result.map(WeightModel.fromMap).toList();
  }

  Future<int> updateWeight(WeightModel weight) async {
    final db = await database;

    if (weight.id == null) {
      throw ArgumentError(
        'El registro de peso debe tener un id para actualizarse.',
      );
    }

    return db.update(
      'pesos',
      weight.toMap(),
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [
        weight.id,
        weight.usuarioId,
      ],
    );
  }

  Future<int> deleteWeight(
    int weightId,
    int usuarioId,
  ) async {
    final db = await database;

    return db.delete(
      'pesos',
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [
        weightId,
        usuarioId,
      ],
    );
  }

  // =========================
  // OPERACIONES DE ENTRENAMIENTOS
  // =========================

  Future<int> insertTraining(
    TrainingModel training,
  ) async {
    final db = await database;

    return db.insert(
      'entrenamientos',
      training.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<TrainingModel>> getTrainingsByUser(
    int usuarioId,
  ) async {
    final db = await database;

    final result = await db.query(
      'entrenamientos',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'fecha DESC, id DESC',
    );

    return result.map(TrainingModel.fromMap).toList();
  }

  Future<List<TrainingModel>> getTrainingsByDate(
    int usuarioId,
    String fecha,
  ) async {
    final db = await database;

    final result = await db.query(
      'entrenamientos',
      where: 'usuario_id = ? AND fecha = ?',
      whereArgs: [
        usuarioId,
        fecha,
      ],
      orderBy: 'id DESC',
    );

    return result.map(TrainingModel.fromMap).toList();
  }

  Future<int> updateTraining(
    TrainingModel training,
  ) async {
    final db = await database;

    if (training.id == null) {
      throw ArgumentError(
        'El entrenamiento debe tener un id para actualizarse.',
      );
    }

    return db.update(
      'entrenamientos',
      training.toMap(),
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [
        training.id,
        training.usuarioId,
      ],
    );
  }

  Future<int> deleteTraining(
    int trainingId,
    int usuarioId,
  ) async {
    final db = await database;

    return db.delete(
      'entrenamientos',
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [
        trainingId,
        usuarioId,
      ],
    );
  }

  Future<int> countTrainingsByUser(
    int usuarioId,
  ) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM entrenamientos
      WHERE usuario_id = ?
      ''',
      [usuarioId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // =========================
  // OPERACIONES DE RECORDATORIOS
  // =========================

  Future<int> insertReminder(
    ReminderModel reminder,
  ) async {
    final db = await database;

    return db.insert(
      'recordatorios',
      reminder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<ReminderModel>> getRemindersByUser(
    int usuarioId,
  ) async {
    final db = await database;

    final result = await db.query(
      'recordatorios',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'dia_semana ASC, hora ASC, minuto ASC',
    );

    return result.map(ReminderModel.fromMap).toList();
  }

  Future<int> updateReminder(
    ReminderModel reminder,
  ) async {
    final db = await database;

    if (reminder.id == null) {
      throw ArgumentError(
        'El recordatorio debe tener un id para actualizarse.',
      );
    }

    return db.update(
      'recordatorios',
      reminder.toMap(),
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [
        reminder.id,
        reminder.usuarioId,
      ],
    );
  }

  Future<int> updateReminderStatus(
    int reminderId,
    int usuarioId,
    bool activo,
  ) async {
    final db = await database;

    return db.update(
      'recordatorios',
      {
        'activo': activo ? 1 : 0,
      },
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [
        reminderId,
        usuarioId,
      ],
    );
  }

  Future<int> deleteReminder(
    int reminderId,
    int usuarioId,
  ) async {
    final db = await database;

    return db.delete(
      'recordatorios',
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [
        reminderId,
        usuarioId,
      ],
    );
  }
}