import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'pa_paths.dart';

/// Chrome DevTools Protocol client over WebSocket.
/// Launches Chrome with --remote-debugging-port and connects via CDP.
class CdpClient {
  WebSocket? _ws;
  int _id = 0;
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  final _eventListeners = <String, List<Completer<Map<String, dynamic>>>>{};
  String? _sessionId;

  /// Find or launch Chrome with debug port, connect CDP.
  Future<void> connect({int port = 9333}) async {
    // Try connecting to existing debug instance first
    if (!await _tryConnect(port)) {
      // Launch Chrome with debug port
      final chromePath = await _findChrome();
      if (chromePath == null) throw Exception('Chrome not found');

      final profileDir = await PAPaths.chromeProfileDir;

      await Process.start(chromePath, [
        '--remote-debugging-port=$port',
        '--no-first-run',
        '--no-default-browser-check',
        '--new-window',
        '--user-data-dir=$profileDir',
      ]);

      // Wait for Chrome to start
      for (var i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (await _tryConnect(port)) {
          await _bringToFront();
          return;
        }
      }
      throw Exception('Chrome debug port $port not responding');
    } else {
      await _bringToFront();
    }
  }

  /// 把 Chrome 窗口拉到前台（macOS/Windows/Linux）
  Future<void> _bringToFront() async {
    try {
      if (Platform.isMacOS) {
        await Process.run('osascript', ['-e', 'tell application "Google Chrome" to activate']);
      } else if (Platform.isWindows) {
        // PowerShell 激活 Chrome 窗口
        await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          r'(New-Object -ComObject WScript.Shell).AppActivate((Get-Process chrome | Where-Object {$_.MainWindowTitle} | Select-Object -First 1).Id)',
        ]);
      } else if (Platform.isLinux) {
        await Process.run('wmctrl', ['-a', 'Chrome']);
      }
    } catch (_) {
      // 激活失败不影响主流程
    }
  }

  /// 需要过滤的 Chrome 内部假 target URL 前缀
  static const _internalPrefixes = [
    'chrome://',
    'chrome-extension://',
    'devtools://',
    'about:',
  ];

  /// 判断是否为真实的用户页面 target
  static bool _isRealPage(Map<String, dynamic> t) {
    if (t['type'] != 'page') return false;
    final url = (t['url'] as String?) ?? '';
    for (final prefix in _internalPrefixes) {
      if (url.startsWith(prefix)) return false;
    }
    return true;
  }

  Future<bool> _tryConnect(int port) async {
    // Chrome 147+ 可能只监听 IPv6，依次尝试
    for (final host in ['[::1]', '127.0.0.1']) {
      try {
        final resp = await HttpClient()
            .getUrl(Uri.parse('http://$host:$port/json'))
            .then((r) => r.close())
            .timeout(const Duration(seconds: 2));
        final body = await resp.transform(utf8.decoder).join();
        final tabs = jsonDecode(body) as List;
        // 优先找真实页面，找不到就用任意 page 类型（含 newtab）
        final allPages = tabs.cast<Map<String, dynamic>>().where((t) => t['type'] == 'page').toList();
        final page = allPages.where(_isRealPage).firstOrNull ?? allPages.firstOrNull;
        if (page == null) continue;

        final wsUrl = page['webSocketDebuggerUrl'] as String;
        _ws = await WebSocket.connect(wsUrl);
        _ws!.listen(_onMessage, onDone: _onDone, onError: _onError);
        await send('Page.enable');
        return true;
      } catch (_) {
        continue;
      }
    }
    return false;
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
    // 分发 CDP 事件给等待者
    final method = msg['method'] as String?;
    if (method != null && _eventListeners.containsKey(method)) {
      final waiters = _eventListeners.remove(method)!;
      for (final c in waiters) {
        c.complete(msg);
      }
    }
  }

  void _onDone() {
    _ws = null;
    // Complete all pending with error to prevent hanging
    for (final c in _pending.values) {
      c.completeError(Exception('CDP connection closed'));
    }
    _pending.clear();
  }

  void _onError(Object error) {
    debugPrint('[CDP] WebSocket error: $error');
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

  /// 等待某个 CDP 事件触发
  Future<Map<String, dynamic>> waitForEvent(String event, {Duration timeout = const Duration(seconds: 15)}) {
    final completer = Completer<Map<String, dynamic>>();
    _eventListeners.putIfAbsent(event, () => []).add(completer);
    return completer.future.timeout(timeout, onTimeout: () {
      _eventListeners[event]?.remove(completer);
      return <String, dynamic>{'timeout': true};
    });
  }

  /// 等待页面加载完成（Page.loadEventFired）
  Future<void> waitForLoad({Duration timeout = const Duration(seconds: 15)}) async {
    await waitForEvent('Page.loadEventFired', timeout: timeout);
  }

  Future<void> close() async {
    await _ws?.close();
    _ws = null;
  }
}
