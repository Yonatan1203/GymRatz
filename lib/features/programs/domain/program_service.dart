import 'package:uuid/uuid.dart';

import '../../../shared/models/program.dart';
import '../../../shared/models/workout_day.dart';
import '../data/program_repository.dart';

class ProgramService {
  final ProgramRepository _repo;
  static const _uuid = Uuid();

  ProgramService(this._repo);

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
    return program;
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
