import 'dart:io';

class AppSettings {
  final String defaultServerPath;
  final bool startMinimized;
  final bool closeToTray;
  final bool checkUpdatesAutomatically;
  final String backupLocation;
  final bool autoBackup;
  final int backupFrequency;
  final String schemaVersion;

  AppSettings({
    required this.defaultServerPath,
    this.startMinimized = false,
    this.closeToTray = true,
    this.checkUpdatesAutomatically = true,
    required this.backupLocation,
    this.autoBackup = true,
    this.backupFrequency = 24,
    this.schemaVersion = '1.0.0',
  });

  factory AppSettings.defaults() {
    final defaultPath = Platform.isWindows
        ? '${Platform.environment['USERPROFILE']}\\AppData\\Roaming\\MCSM\\servers'
        : '${Platform.environment['HOME']}/.mcsm/servers';

    final backupPath = Platform.isWindows
        ? '${Platform.environment['USERPROFILE']}\\AppData\\Roaming\\MCSM\\backups'
        : '${Platform.environment['HOME']}/.mcsm/backups';

    return AppSettings(
      defaultServerPath: defaultPath,
      backupLocation: backupPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'defaultServerPath': defaultServerPath,
        'startMinimized': startMinimized,
        'closeToTray': closeToTray,
        'checkUpdatesAutomatically': checkUpdatesAutomatically,
        'backupLocation': backupLocation,
        'autoBackup': autoBackup,
        'backupFrequency': backupFrequency,
        'schemaVersion': schemaVersion,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        defaultServerPath: json['defaultServerPath'] as String,
        startMinimized: json['startMinimized'] as bool? ?? false,
        closeToTray: json['closeToTray'] as bool? ?? true,
        checkUpdatesAutomatically:
            json['checkUpdatesAutomatically'] as bool? ?? true,
        backupLocation: json['backupLocation'] as String,
        autoBackup: json['autoBackup'] as bool? ?? true,
        backupFrequency: json['backupFrequency'] as int? ?? 24,
        schemaVersion: json['schemaVersion'] as String? ?? '1.0.0',
      );
}
