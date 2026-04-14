import 'package:flutter/services.dart';

/// Bridge for general Android Intent operations.
class AndroidIntentBridge {
  static const _channel = MethodChannel('com.clawworks.pocket_agent/intent');

  /// Launch an intent by action and optional extras.
  static Future<Map<String, dynamic>> launch({
    required String action,
    String? uri,
    String? packageName,
    Map<String, String>? extras,
  }) async {
    final result = await _channel.invokeMethod<Map>('launchIntent', {
      'action': action,
      if (uri != null) 'uri': uri,
      if (packageName != null) 'package': packageName,
      if (extras != null) 'extras': extras,
    });
    return Map<String, dynamic>.from(result ?? {'status': 'launched'});
  }

  /// Share text to other apps.
  static Future<void> shareText(String text, {String? title}) async {
    await _channel.invokeMethod('shareText', {
      'text': text,
      if (title != null) 'title': title,
    });
  }
}
