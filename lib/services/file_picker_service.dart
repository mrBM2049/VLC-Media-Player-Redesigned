import 'dart:io';

/// Platform-native file picker service adhering to Ponytail 7-Rung discipline.
/// Invokes standard OS file pickers without external third-party dependencies.
class FilePickerService {
  /// Opens the native OS file picker to choose a video or audio file.
  /// Returns the absolute POSIX path or null if cancelled.
  static Future<String?> pickMediaFile() async {
    try {
      if (Platform.isMacOS) {
        final result = await Process.run('osascript', [
          '-e',
          'POSIX path of (choose file of type {"public.movie", "public.audio", "mp4", "mkv", "avi", "mov", "webm", "mp3", "flac", "wav", "m4a", "aac"} with prompt "Select Media File for VLC")'
        ]);
        if (result.exitCode == 0) {
          final path = (result.stdout as String).trim();
          if (path.isNotEmpty && File(path).existsSync()) {
            return path;
          }
        }
      } else if (Platform.isLinux) {
        final result = await Process.run('zenity', [
          '--file-selection',
          '--title=Select Media File for VLC',
          '--file-filter=Media Files | *.mp4 *.mkv *.avi *.mov *.webm *.mp3 *.flac *.wav *.m4a',
        ]);
        if (result.exitCode == 0) {
          final path = (result.stdout as String).trim();
          if (path.isNotEmpty && File(path).existsSync()) {
            return path;
          }
        }
      } else if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          '''
Add-Type -AssemblyName System.Windows.Forms
\$dialog = New-Object System.Windows.Forms.OpenFileDialog
\$dialog.Filter = "Media Files (*.mp4;*.mkv;*.avi;*.mov;*.webm;*.mp3;*.flac)|*.mp4;*.mkv;*.avi;*.mov;*.webm;*.mp3;*.flac|All files (*.*)|*.*"
\$dialog.Title = "Select Media File for VLC"
if (\$dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    Write-Output \$dialog.FileName
}
'''
        ]);
        if (result.exitCode == 0) {
          final path = (result.stdout as String).trim();
          if (path.isNotEmpty && File(path).existsSync()) {
            return path;
          }
        }
      }
    } catch (_) {}
    return null;
  }
}

