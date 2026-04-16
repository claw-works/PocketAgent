import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'base_tool.dart';

/// 🖥️ macOS: 打开应用、执行 shell 命令、用 AppleScript 操控
class MacOsTool extends BaseTool {
  @override
  String get name => 'macos_shell';

  @override
  String get description =>
  @override
  bool get requiresConfirmation => true;
      '（macOS）执行 shell 命令、打开应用程序、或运行 AppleScript';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['run', 'open_app', 'applescript'],
            'description': 'run: 执行 shell 命令, open_app: 打开应用, applescript: 执行 AppleScript',
          },
          'command': {
            'type': 'string',
            'description': 'shell 命令（run 时）、应用名称（open_app 时）、或 AppleScript 代码（applescript 时）',
          },
          'timeout_seconds': {
            'type': 'integer',
            'description': '超时秒数，默认 30',
          },
        },
        'required': ['action', 'command'],
      };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    if (!Platform.isMacOS) {
      return jsonEncode({'status': 'error', 'message': '此工具仅支持 macOS'});
    }

    final action = args['action'] as String;
    final command = args['command'] as String;
    final timeout = args['timeout_seconds'] as int? ?? 30;

    try {
      switch (action) {
        case 'open_app':
          final result = await Process.run('open', ['-a', command],
              runInShell: false)
              .timeout(Duration(seconds: timeout));
          return jsonEncode({
            'status': result.exitCode == 0 ? 'ok' : 'error',
            'message': result.exitCode == 0 ? '已打开 $command' : result.stderr,
          });

        case 'applescript':
          final result = await Process.run('osascript', ['-e', command])
              .timeout(Duration(seconds: timeout));
          return jsonEncode({
            'status': result.exitCode == 0 ? 'ok' : 'error',
            'stdout': (result.stdout as String).trim(),
            'stderr': (result.stderr as String).trim(),
          });

        case 'run':
          final result = await Process.run('bash', ['-c', command])
              .timeout(Duration(seconds: timeout));
          return jsonEncode({
            'status': result.exitCode == 0 ? 'ok' : 'error',
            'stdout': (result.stdout as String).trim(),
            'stderr': (result.stderr as String).trim(),
            'exit_code': result.exitCode,
          });

        default:
          return jsonEncode({'status': 'error', 'message': '未知 action: $action'});
      }
    } on TimeoutException {
      return jsonEncode({'status': 'error', 'message': '执行超时（${timeout}s）'});
    } catch (e) {
      return jsonEncode({'status': 'error', 'message': '$e'});
    }
  }
}
