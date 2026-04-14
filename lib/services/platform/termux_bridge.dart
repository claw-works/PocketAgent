import 'package:flutter/services.dart';

/// Bridge to native Android Termux integration via MethodChannel.
class TermuxBridge {
  static const _channel = MethodChannel('com.clawworks.pocket_agent/termux');

  /// Check if Termux is installed on the device.
  static Future<bool> isInstalled() async {
    try {
      return await _channel.invokeMethod<bool>('isTermuxInstalled') ?? false;
    } on MissingPluginException {
      return false; // not on Android
    }
  }

  /// Run a shell command via Termux.
  /// Returns {stdout, stderr, exit_code}.
  static Future<Map<String, dynamic>> run(
    String command, {
    bool background = true,
  }) async {
    final result = await _channel.invokeMethod<Map>('runCommand', {
      'command': command,
      'background': background,
    });
    return Map<String, dynamic>.from(result ?? {});
  }
}
