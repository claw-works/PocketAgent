import 'dart:io';

/// Pick an image file using native OS file dialog.
Future<String?> pickImageFile() async {
  if (Platform.isMacOS) {
    final result = await Process.run('osascript', [
      '-e',
      'set f to choose file of type {"public.image"} with prompt "选择头像图片"',
      '-e',
      'POSIX path of f',
    ]);
    if (result.exitCode == 0) {
      final path = (result.stdout as String).trim();
      if (path.isNotEmpty) return path;
    }
  } else if (Platform.isLinux) {
    final result = await Process.run('zenity', [
      '--file-selection',
      '--file-filter=Images | *.png *.jpg *.jpeg *.gif *.webp',
      '--title=选择头像图片',
    ]);
    if (result.exitCode == 0) {
      final path = (result.stdout as String).trim();
      if (path.isNotEmpty) return path;
    }
  } else if (Platform.isWindows) {
    final result = await Process.run('powershell', [
      '-NoProfile', '-Command',
      'Add-Type -AssemblyName System.Windows.Forms; '
      '\$d = New-Object System.Windows.Forms.OpenFileDialog; '
      '\$d.Filter = "Images|*.png;*.jpg;*.jpeg;*.gif;*.webp"; '
      '\$d.Title = "选择头像图片"; '
      'if (\$d.ShowDialog() -eq "OK") { \$d.FileName }',
    ]);
    if (result.exitCode == 0) {
      final path = (result.stdout as String).trim();
      if (path.isNotEmpty) return path;
    }
  }
  return null;
}
