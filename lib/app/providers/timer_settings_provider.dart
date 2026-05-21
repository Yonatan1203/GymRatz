import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerSettings {
  final bool soundEnabled;
  final bool autoStartOnSetComplete;

  const TimerSettings({
    this.soundEnabled = true,
    this.autoStartOnSetComplete = true,
  });

  TimerSettings copyWith({
    bool? soundEnabled,
    bool? autoStartOnSetComplete,
  }) {
    return TimerSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      autoStartOnSetComplete: autoStartOnSetComplete ?? this.autoStartOnSetComplete,
    );
  }
}

class TimerSettingsNotifier extends StateNotifier<TimerSettings> {
  static const _keySound = 'timer_sound_enabled';
  static const _keyAutoStart = 'timer_auto_start';

  TimerSettingsNotifier() : super(const TimerSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = TimerSettings(
      soundEnabled: prefs.getBool(_keySound) ?? true,
      autoStartOnSetComplete: prefs.getBool(_keyAutoStart) ?? true,
    );
  }

  Future<void> setSoundEnabled(bool value) async {
    state = state.copyWith(soundEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySound, value);
  }

  Future<void> setAutoStartOnSetComplete(bool value) async {
    state = state.copyWith(autoStartOnSetComplete: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoStart, value);
  }
}

final timerSettingsProvider =
    StateNotifierProvider<TimerSettingsNotifier, TimerSettings>((ref) {
  return TimerSettingsNotifier();
});
