import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Chrome DevTools Protocol client over WebSocket.
/// Launches Chrome with --remote-debugging-port and connects via CDP.
class CdpClient {
  WebSocket? _ws;
  int _id = 0;
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  String? _sessionId;

  /// Find or launch Chrome with debug port, connect CDP.
  Future<void> connect({int port = 9222}) async {
    // Try connecting to existing debug instance first
    if (!await _tryConnect(port)) {
      // Launch Chrome with debug port
      final chromePath = await _findChrome();
      if (chromePath == null) throw Exception('Chrome not found');

      final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
      final profileDir = '$home/.pocketagent/chrome_profile';
      await Directory(profileDir).create(recursive: true);

      await Process.start(chromePath, [
        '--remote-debugging-port=$port',
        '--no-first-run',
        '--no-default-browser-check',
        '--user-data-dir=$profileDir',
      ]);

      // Wait for Chrome to start
      for (var i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (await _tryConnect(port)) return;
      }
      throw Exception('Chrome debug port $port not responding');
    }
  }

  Future<bool> _tryConnect(int port) async {
    try {
      final resp = await HttpClient()
          .getUrl(Uri.parse('http://127.0.0.1:$port/json'))
          .then((r) => r.close())
          .timeout(const Duration(seconds: 2));
      final body = await resp.transform(utf8.decoder).join();
      final tabs = jsonDecode(body) as List;
      final page = tabs.firstWhere(
        (t) => t['type'] == 'page',
        orElse: () => null,
      );
      if (page == null) return false;

      final wsUrl = page['webSocketDebuggerUrl'] as String;
      _ws = await WebSocket.connect(wsUrl);
      _ws!.listen(_onMessage, onDone: () => _ws = null);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _findChrome() async {
    if (Platform.isMacOS) {
      const paths = [
        '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
        '/Applications/Chromium.app/Contents/MacOS/Chromium',
      ];
      for (final p in paths) {
        if (await File(p).exists()) return p;
      }
    } else if (Platform.isWindows) {
      final envPaths = [
        Platform.environment['PROGRAMFILES'],
        Platform.environment['PROGRAMFILES(X86)'],
        Platform.environment['LOCALAPPDATA'],
      ];
      for (final base in envPaths) {
        if (base == null) continue;
        for (final sub in ['Google/Chrome/Application/chrome.exe', 'Google\\Chrome\\Application\\chrome.exe']) {
          final p = '$base/$sub';
          if (await File(p).exists()) return p;
        }
      }
    } else if (Platform.isLinux) {
      for (final name in ['google-chrome', 'chromium-browser', 'chromium']) {
        final r = await Process.run('which', [name]);
        if (r.exitCode == 0) return (r.stdout as String).trim();
      }
    }
    return null;
  }

  void _onMessage(dynamic data) {
    final msg = jsonDecode(data as String) as Map<String, dynamic>;
    final id = msg['id'] as int?;
    if (id != null && _pending.containsKey(id)) {
      _pending.remove(id)!.complete(msg);
    }
  }

  /// Send a CDP command and wait for result.
  Future<Map<String, dynamic>> send(String method, [Map<String, dynamic>? params]) async {
    if (_ws == null) throw Exception('CDP not connected');
    final id = ++_id;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;

    _ws!.add(jsonEncode({
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    }));

    return completer.future.timeout(const Duration(seconds: 30));
  }

  bool get isConnected => _ws != null;

  Future<void> close() async {
    await _ws?.close();
    _ws = null;
  }
}
