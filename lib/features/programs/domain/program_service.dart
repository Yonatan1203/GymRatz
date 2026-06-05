import 'package:uuid/uuid.dart';

import '../../../core/analytics_service.dart';
import '../../../shared/models/program.dart';
import '../../../shared/models/workout_day.dart';
import '../data/program_repository.dart';

class ProgramService {
  final ProgramRepository _repo;
  final AnalyticsService _analyticsService;
  static const _uuid = Uuid();

  ProgramService(this._repo, this._analyticsService);

  Future<Program> createProgram(
    String uid, {
    required String name,
    required List<WorkoutDay> days,
    int weeks = 8,
    String? description,
    String? difficulty,
  }) async {
    final program = Program(
      id: _uuid.v4(),
      name: name,
      workouts: days.length,
      weeks: weeks,
      days: days,
      description: description,
      difficulty: difficulty,
      createdAt: DateTime.now(),
    );

    await _repo.createProgram(uid, program);
    _analyticsService.logProgramCreated(name).ignore();
    return program;
  }

  /// Partial update of an existing program — only the supplied keys are
  /// written, so server-managed fields (isActive, progress, createdAt,
  /// activatedAt, prefillWeights, coach fields) are left untouched.
  /// Null description/difficulty are omitted rather than written, so they do
  /// not overwrite an existing stored value.
  Future<void> editProgram(
    String uid,
    String programId, {
    required String name,
    required List<WorkoutDay> days,
    int weeks = 8,
    String? description,
    String? difficulty,
  }) async {
    final fields = <String, dynamic>{
      'name': name,
      'days': days.map((d) => d.toJson()).toList(),
      'workouts': days.length,
      'weeks': weeks,
      if (description != null) 'description': description,
      if (difficulty != null) 'difficulty': difficulty,
    };
    await _repo.updateProgram(uid, programId, fields);
  }

  Future<void> activateProgram(String uid, String programId) async {
    await _repo.setActiveProgram(uid, programId);
  }

  /// Get today's workout day from the active program.
  WorkoutDay? getTodaysWorkout(Program program) {
    if (program.days.isEmpty) return null;
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final todayName = dayNames[DateTime.now().weekday - 1];
    return program.days.where((d) => d.dayOfWeek == todayName).firstOrNull;
  }

  Future<void> updateProgramProgress(
      String uid, String programId, int progress) async {
    await _repo.updateProgram(uid, programId, {'progress': progress});
  }
}
