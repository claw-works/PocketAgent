import 'package:flutter/services.dart';

/// Bridge to Android Accessibility Service for screen reading and UI automation.
class AccessibilityBridge {
  static const _channel = MethodChannel('com.clawworks.pocket_agent/accessibility');

  static Future<bool> isEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('isEnabled') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<void> openSettings() async {
    await _channel.invokeMethod('openSettings');
  }

  /// Read all visible UI elements on screen.
  static Future<List<Map<String, dynamic>>> readScreen() async {
    final result = await _channel.invokeMethod<List>('readScreen');
    return result?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
  }

  static Future<bool> clickByText(String text) async {
    return await _channel.invokeMethod<bool>('clickByText', {'text': text}) ?? false;
  }

  static Future<bool> clickByIndex(int index) async {
    return await _channel.invokeMethod<bool>('clickByIndex', {'index': index}) ?? false;
  }

  static Future<bool> tap(double x, double y) async {
    return await _channel.invokeMethod<bool>('tap', {'x': x, 'y': y}) ?? false;
  }

  static Future<bool> inputText(String text) async {
    return await _channel.invokeMethod<bool>('inputText', {'text': text}) ?? false;
  }

  static Future<bool> swipe(double x1, double y1, double x2, double y2, {int duration = 300}) async {
    return await _channel.invokeMethod<bool>('swipe', {
      'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2, 'duration': duration,
    }) ?? false;
  }

  static Future<bool> globalAction(String action) async {
    return await _channel.invokeMethod<bool>('globalAction', {'action': action}) ?? false;
  }
}
