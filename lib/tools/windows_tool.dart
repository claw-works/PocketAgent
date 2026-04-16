import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'base_tool.dart';

/// 🪟 Windows: PowerShell 命令、打开应用
class WindowsTool extends BaseTool {
  @override
  String get name => 'windows_shell';

  @override
  String get description =>
  @override
  bool get requiresConfirmation => true;
      '（Windows）执行 PowerShell 命令、打开应用程序';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['run', 'open_app', 'powershell'],
            'description': 'run: 执行 cmd 命令, open_app: 打开应用, powershell: 执行 PowerShell 脚本',
          },
          'command': {
            'type': 'string',
            'description': '命令内容或应用名称',
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
    if (!Platform.isWindows) {
      return jsonEncode({'status': 'error', 'message': '此工具仅支持 Windows'});
    }

    final action = args['action'] as String;
    final command = args['command'] as String;
    final timeout = args['timeout_seconds'] as int? ?? 30;

    try {
      switch (action) {
        case 'open_app':
          final result = await Process.run('cmd', ['/c', 'start', '', command])
              .timeout(Duration(seconds: timeout));
          return jsonEncode({
            'status': result.exitCode == 0 ? 'ok' : 'error',
            'message': result.exitCode == 0 ? '已打开 $command' : (result.stderr as String).trim(),
          });

        case 'powershell':
          final result = await Process.run(
            'powershell', ['-NoProfile', '-Command', command],
          ).timeout(Duration(seconds: timeout));
          return jsonEncode({
            'status': result.exitCode == 0 ? 'ok' : 'error',
            'stdout': (result.stdout as String).trim(),
            'stderr': (result.stderr as String).trim(),
            'exit_code': result.exitCode,
          });

        case 'run':
          final result = await Process.run('cmd', ['/c', command])
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
