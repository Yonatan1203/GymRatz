import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/domain/auth_service.dart';
import '../../../app/providers/auth_providers.dart';

class OnboardingState {
  final String? selectedGoal;
  final String? selectedExperience;
  final String? selectedStyle;
  final Set<String> selectedInjuries;
  final String? selectedUnits; // 'metric' or 'imperial'
  final double height; // in cm
  final double weight; // in kg
  final String email;
  final String password;
  final bool notificationsEnabled;
  final bool healthEnabled;
  final String? discovery;
  final bool isSubmitting;
  final String? error;

  const OnboardingState({
    this.selectedGoal,
    this.selectedExperience,
    this.selectedStyle,
    this.selectedInjuries = const {},
    this.selectedUnits,
    this.height = 175,
    this.weight = 75,
    this.email = '',
    this.password = '',
    this.notificationsEnabled = true,
    this.healthEnabled = false,
    this.discovery,
    this.isSubmitting = false,
    this.error,
  });

  OnboardingState copyWith({
    String? selectedGoal,
    String? selectedExperience,
    String? selectedStyle,
    Set<String>? selectedInjuries,
    String? selectedUnits,
    double? height,
    double? weight,
    String? email,
    String? password,
    bool? notificationsEnabled,
    bool? healthEnabled,
    String? discovery,
    bool? isSubmitting,
    String? error,
  }) {
    return OnboardingState(
      selectedGoal: selectedGoal ?? this.selectedGoal,
      selectedExperience: selectedExperience ?? this.selectedExperience,
      selectedStyle: selectedStyle ?? this.selectedStyle,
      selectedInjuries: selectedInjuries ?? this.selectedInjuries,
      selectedUnits: selectedUnits ?? this.selectedUnits,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      email: email ?? this.email,
      password: password ?? this.password,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      healthEnabled: healthEnabled ?? this.healthEnabled,
      discovery: discovery ?? this.discovery,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final AuthService _authService;

  OnboardingNotifier(this._authService) : super(const OnboardingState());

  static const _cacheKey = 'onboarding_state_cache';

  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'goal': state.selectedGoal,
      'experience': state.selectedExperience,
      'style': state.selectedStyle,
      'injuries': state.selectedInjuries.toList(),
      'units': state.selectedUnits,
      'height': state.height,
      'weight': state.weight,
    };
    await prefs.setString(_cacheKey, json.encode(data));
  }

  Future<void> restoreFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached == null) return;

    final data = json.decode(cached) as Map<String, dynamic>;
    state = state.copyWith(
      selectedGoal: data['goal'] as String?,
      selectedExperience: data['experience'] as String?,
      selectedStyle: data['style'] as String?,
      selectedInjuries: Set<String>.from(data['injuries'] ?? []),
      selectedUnits: data['units'] as String?,
      height: (data['height'] as num?)?.toDouble(),
      weight: (data['weight'] as num?)?.toDouble(),
    );
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }

  void setGoal(String goal) {
    state = state.copyWith(selectedGoal: goal);
    _saveToCache();
  }

  void setExperience(String experience) {
    state = state.copyWith(selectedExperience: experience);
    _saveToCache();
  }

  void setStyle(String style) {
    state = state.copyWith(selectedStyle: style);
    _saveToCache();
  }

  void toggleInjury(String injury) {
    final injuries = Set<String>.from(state.selectedInjuries);
    if (injury == 'None') {
      state = state.copyWith(selectedInjuries: {'None'});
      _saveToCache();
      return;
    }
    injuries.remove('None');
    if (injuries.contains(injury)) {
      injuries.remove(injury);
    } else {
      injuries.add(injury);
    }
    state = state.copyWith(selectedInjuries: injuries);
    _saveToCache();
  }

  void setUnits(String units) {
    state = state.copyWith(selectedUnits: units);
    _saveToCache();
  }

  void setHeight(double height) {
    state = state.copyWith(height: height);
    _saveToCache();
  }

  void setWeight(double weight) {
    state = state.copyWith(weight: weight);
    _saveToCache();
  }

  void setEmail(String email) {
    state = state.copyWith(email: email);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password);
  }

  void setNotificationsEnabled(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
  }

  void setHealthEnabled(bool enabled) {
    state = state.copyWith(healthEnabled: enabled);
  }

  void setDiscovery(String discovery) {
    state = state.copyWith(discovery: discovery);
  }

  /// Create Firebase account + Firestore profile from collected onboarding data.
  Future<bool> completeOnboarding() async {
    state = state.copyWith(isSubmitting: true, error: null);

    try {
      debugPrint('ONBOARDING: Starting signup with ${state.email}');
      final isMetric = state.selectedUnits == 'metric';
      final heightStr = isMetric
          ? '${state.height.round()} cm'
          : _cmToFeetInches(state.height);
      final weightKg = isMetric ? state.weight : state.weight * 0.453592;
      final unit = isMetric ? 'kg' : 'lbs';

      await _authService.signUp(
        email: state.email,
        password: state.password,
        onboardingData: {
          'name': state.email.split('@').first,
          'height': heightStr,
          'weight': isMetric ? weightKg : state.weight,
          'unit': unit,
          'experienceLevel': state.selectedExperience ?? 'Intermediate',
          'primaryGoal': state.selectedGoal ?? 'Build Muscle',
          'injuries': state.selectedInjuries,
          'style': state.selectedStyle,
          'notificationsEnabled': state.notificationsEnabled,
          'healthEnabled': state.healthEnabled,
          'discovery': state.discovery,
        },
      );

      debugPrint('ONBOARDING: Signup SUCCESS');
      await clearCache();
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e, st) {
      debugPrint('ONBOARDING: Signup FAILED: $e');
      debugPrint('ONBOARDING: Stack: $st');
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  String _cmToFeetInches(double cm) {
    final totalInches = cm / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches % 12).round();
    return '$feet\'$inches"';
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return OnboardingNotifier(authService);
});
