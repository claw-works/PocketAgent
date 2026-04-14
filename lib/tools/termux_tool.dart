import 'dart:convert';
import 'base_tool.dart';

/// 🐧 Android: Termux 互操作 — 执行 shell 命令
class TermuxTool extends BaseTool {
  @override
  String get name => 'termux_shell';

  @override
  String get description => '（Android）通过 Termux 执行 Linux shell 命令';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'command': {
            'type': 'string',
            'description': '要执行的 shell 命令',
          },
          'timeout_seconds': {
            'type': 'integer',
            'description': '超时秒数，默认 30',
          },
        },
        'required': ['command'],
      };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    final command = args['command'] as String;
    final timeout = args['timeout_seconds'] ?? 30;
    // TODO: integrate Termux:API intent or RUN_COMMAND intent
    return jsonEncode({
      'status': 'ok',
      'command': command,
      'stdout': '(stub output for: $command)',
      'exit_code': 0,
      'timeout': timeout,
    });
  }
}
