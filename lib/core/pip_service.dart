import 'dart:io';
import 'package:flutter/services.dart';

class PipService {
  static final PipService _instance = PipService._();
  factory PipService() => _instance;
  PipService._();

  static const _channel = MethodChannel('com.gymratz.gymratz/pip');

  bool _isInPip = false;
  bool get isInPip => _isInPip;

  void Function(bool)? onPipChanged;

  Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPipChanged') {
        _isInPip = call.arguments as bool;
        onPipChanged?.call(_isInPip);
      }
    });
  }

  Future<bool> get isSupported async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isPipSupported') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Enable auto-PiP when user leaves the app (e.g. presses home).
  Future<void> enable() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('enablePip');
    } catch (_) {}
  }

  /// Disable auto-PiP.
  Future<void> disable() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('disablePip');
    } catch (_) {}
  }
}
