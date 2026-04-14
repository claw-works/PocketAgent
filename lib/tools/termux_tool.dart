import 'dart:convert';
import 'base_tool.dart';
import '../services/platform/termux_bridge.dart';

/// 🐧 Android: Termux 互操作 — 通过 Termux 执行真实 Linux shell 命令
class TermuxTool extends BaseTool {
  @override
  String get name => 'termux_shell';

  @override
  String get description =>
      '（Android）通过 Termux 执行 Linux shell 命令。需要设备已安装 Termux 并授予 RUN_COMMAND 权限。'
      '可执行任意 bash 命令，包括 python、node、curl、git 等 Termux 中已安装的工具。';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'command': {
            'type': 'string',
            'description': '要执行的 bash 命令',
          },
          'background': {
            'type': 'boolean',
            'description': '是否在后台执行（默认 true，不弹出 Termux 窗口）',
          },
        },
        'required': ['command'],
      };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    final command = args['command'] as String;
    final background = args['background'] as bool? ?? true;

    final installed = await TermuxBridge.isInstalled();
    if (!installed) {
      return jsonEncode({
        'status': 'error',
        'message': 'Termux 未安装，请先从 F-Droid 或 GitHub 安装 Termux',
      });
    }

    try {
      final result = await TermuxBridge.run(command, background: background);
      return jsonEncode({
        'status': 'ok',
        'command': command,
        'stdout': result['stdout'] ?? '',
        'stderr': result['stderr'] ?? '',
        'exit_code': result['exit_code'] ?? -1,
      });
    } catch (e) {
      return jsonEncode({'status': 'error', 'message': '$e'});
    }
  }
}
