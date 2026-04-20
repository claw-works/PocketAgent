import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'base_tool.dart';
import '../services/pa_paths.dart';

/// 📸 Screenshot tool — capture screen, window, or region.
/// Returns base64 image for LLM vision analysis.
class ScreenshotTool extends BaseTool {
  @override
  String get name => 'screenshot';

  @override
  String get description =>
      '静默截取屏幕截图（全屏或当前最前窗口），无需用户交互，返回图片供分析。';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'mode': {
            'type': 'string',
            'enum': ['fullscreen', 'window'],
            'description': 'fullscreen: 全屏截图, window: 当前最前窗口（均为静默截图，无需用户操作）',
          },
        },
        'required': ['mode'],
      };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    final mode = args['mode'] as String? ?? 'fullscreen';

    if (Platform.isMacOS) return _macOS(mode);
    if (Platform.isLinux) return _linux(mode);
    if (Platform.isWindows) return _windows(mode);
    return jsonEncode({'status': 'unavailable', 'message': '当前平台不支持截图'});
  }

  Future<String> _macOS(String mode) async {
    final path = await _tempPath();

    try {
      if (mode == 'window') {
        // Silent window capture: get front window ID via AppleScript, then screencapture -l
        final idResult = await Process.run('osascript', ['-e',
          'tell application "System Events" to set fApp to name of first application process whose frontmost is true\n'
          'tell application fApp to set wID to id of front window\n'
          'return wID',
        ]).timeout(const Duration(seconds: 5));

        if (idResult.exitCode == 0) {
          final windowId = (idResult.stdout as String).trim();
          // screencapture -l<windowID> captures specific window silently
          await Process.run('screencapture', ['-l$windowId', '-o', '-x', path])
              .timeout(const Duration(seconds: 10));
        } else {
          // Fallback: full screen capture (silent)
          await Process.run('screencapture', ['-x', path])
              .timeout(const Duration(seconds: 10));
        }
      } else {
        // fullscreen: -x = silent (no sound), no user interaction
        await Process.run('screencapture', ['-x', path])
            .timeout(const Duration(seconds: 10));
      }
      return _readAndEncode(path);
    } on TimeoutException {
      return jsonEncode({'status': 'error', 'message': '截图超时'});
    }
  }

  Future<String> _linux(String mode) async {
    final path = await _tempPath();
    // Try gnome-screenshot or scrot
    final tool = await _findLinuxTool();
    if (tool == null) {
      return jsonEncode({'status': 'error', 'message': '未找到截图工具（需要 gnome-screenshot 或 scrot）'});
    }

    final toolArgs = switch (tool) {
      'gnome-screenshot' => switch (mode) {
          'window' => ['-w', '-f', path],
          'region' => ['-a', '-f', path],
          _ => ['-f', path],
        },
      _ => switch (mode) { // scrot
          'window' => ['-u', path],
          'region' => ['-s', path],
          _ => [path],
        },
    };

    try {
      final result = await Process.run(tool, toolArgs)
          .timeout(const Duration(seconds: 30));
      if (result.exitCode != 0) {
        return jsonEncode({'status': 'error', 'message': (result.stderr as String).trim()});
      }
      return _readAndEncode(path);
    } on TimeoutException {
      return jsonEncode({'status': 'error', 'message': '截图超时'});
    }
  }

  Future<String> _windows(String mode) async {
    // PowerShell screenshot using .NET
    final path = await _tempPath();
    final ps = mode == 'fullscreen'
        ? 'Add-Type -AssemblyName System.Windows.Forms; '
          '[System.Windows.Forms.Screen]::PrimaryScreen | ForEach-Object { '
          '\$b = [System.Drawing.Rectangle]::FromLTRB(0, 0, \$_.Bounds.Width, \$_.Bounds.Height); '
          '\$bmp = New-Object System.Drawing.Bitmap(\$b.Width, \$b.Height); '
          '\$g = [System.Drawing.Graphics]::FromImage(\$bmp); '
          '\$g.CopyFromScreen(\$b.Location, [System.Drawing.Point]::Empty, \$b.Size); '
          '\$bmp.Save("$path"); }'
        : 'Add-Type -AssemblyName System.Windows.Forms; '
          '[System.Windows.Forms.Screen]::PrimaryScreen | ForEach-Object { '
          '\$b = [System.Drawing.Rectangle]::FromLTRB(0, 0, \$_.Bounds.Width, \$_.Bounds.Height); '
          '\$bmp = New-Object System.Drawing.Bitmap(\$b.Width, \$b.Height); '
          '\$g = [System.Drawing.Graphics]::FromImage(\$bmp); '
          '\$g.CopyFromScreen(\$b.Location, [System.Drawing.Point]::Empty, \$b.Size); '
          '\$bmp.Save("$path"); }';

    try {
      final result = await Process.run('powershell', ['-NoProfile', '-Command', ps])
          .timeout(const Duration(seconds: 15));
      if (result.exitCode != 0) {
        return jsonEncode({'status': 'error', 'message': (result.stderr as String).trim()});
      }
      return _readAndEncode(path);
    } on TimeoutException {
      return jsonEncode({'status': 'error', 'message': '截图超时'});
    }
  }

  Future<String> _readAndEncode(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return jsonEncode({'status': 'error', 'message': '截图文件未生成（用户可能取消了）'});
    }
    final bytes = await file.readAsBytes();
    final base64Img = base64Encode(bytes);
    // Clean up
    await file.delete().catchError((_) => file);
    return jsonEncode({
      'status': 'ok',
      'image_base64': base64Img,
      'size_bytes': bytes.length,
      'message': '截图成功（${bytes.length ~/ 1024}KB）',
    });
  }

  Future<String> _tempPath() async {
    final dir = await PAPaths.dataDir;
    return '$dir/screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
  }

  Future<String?> _findLinuxTool() async {
    for (final tool in ['gnome-screenshot', 'scrot']) {
      final r = await Process.run('which', [tool]);
      if (r.exitCode == 0) return tool;
    }
    return null;
  }
}
