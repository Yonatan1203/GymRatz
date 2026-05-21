import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models/progression_history.dart';
import '../domain/progression_suggestion.dart';

/// Persists per-exercise progression history and next-session suggestions.
///
/// Firestore structure:
///   users/{uid}/progression/{exerciseKey}/
///     - history: ProgressionHistory (e1RM list, scores, etc.)
///     - suggestion: ProgressionSuggestion (next-session prefill)
///
/// exerciseKey is the exercise name lowercased with spaces replaced by underscores.
class ProgressionRepository {
  final FirebaseFirestore _firestore;

  ProgressionRepository(this._firestore);

  DocumentReference<Map<String, dynamic>> _doc(String uid, String exerciseKey) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('progression')
          .doc(exerciseKey);

  static String exerciseKey(String exerciseName) =>
      exerciseName.toLowerCase().replaceAll(' ', '_');

  /// Load progression history for an exercise.
  Future<ProgressionHistory> getHistory(String uid, String exerciseName) async {
    final snap = await _doc(uid, exerciseKey(exerciseName)).get();
    if (!snap.exists) return const ProgressionHistory();
    final data = snap.data();
    if (data == null || data['history'] == null) return const ProgressionHistory();
    return ProgressionHistory.fromJson(data['history'] as Map<String, dynamic>);
  }

  /// Load the saved next-session suggestion for an exercise.
  Future<ProgressionSuggestion?> getSuggestion(
      String uid, String exerciseName) async {
    final snap = await _doc(uid, exerciseKey(exerciseName)).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null || data['suggestion'] == null) return null;
    return ProgressionSuggestion.fromJson(
        data['suggestion'] as Map<String, dynamic>);
  }

  /// Load suggestions for multiple exercises in one batch.
  Future<Map<String, ProgressionSuggestion>> getSuggestionsForExercises(
      String uid, List<String> exerciseNames) async {
    final result = <String, ProgressionSuggestion>{};
    // Firestore in queries are limited to 30 items.
    final keys = exerciseNames.map(exerciseKey).toList();
    final batches = <List<String>>[];
    for (int i = 0; i < keys.length; i += 30) {
      batches.add(keys.sublist(i, i + 30 > keys.length ? keys.length : i + 30));
    }

    for (final batch in batches) {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('progression')
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['suggestion'] != null) {
          final suggestion = ProgressionSuggestion.fromJson(
              data['suggestion'] as Map<String, dynamic>);
          // Map back to exercise name from the suggestion or doc ID.
          final name = suggestion.exerciseName ?? doc.id;
          result[name] = suggestion;
        }
      }
    }
    return result;
  }

  /// Save both history and suggestion after workout completion.
  Future<void> saveProgressionData({
    required String uid,
    required String exerciseName,
    required ProgressionHistory history,
    required ProgressionSuggestion suggestion,
  }) async {
    await _doc(uid, exerciseKey(exerciseName)).set({
      'history': history.toJson(),
      'suggestion': suggestion.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Save weekly hard sets data (for hypertrophy volume tracking).
  Future<void> saveWeeklyHardSets({
    required String uid,
    required String exerciseName,
    required List<int> weeklyHardSets,
  }) async {
    await _doc(uid, exerciseKey(exerciseName)).set({
      'history': {'weeklyHardSets': weeklyHardSets},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
