import 'dart:io';
import 'package:path/path.dart' as path;

class Settings {
  final String serverPath;
  final String javaPath;
  final bool startMinimized;
  final bool closeToTray;
  final bool autoUpdate;
  final BackupSettings backupSettings;

  Settings({
    required this.serverPath,
    required this.javaPath,
    this.startMinimized = false,
    this.closeToTray = true,
    this.autoUpdate = true,
    required this.backupSettings,
  });

  static String get defaultServerPath =>
      Platform.isWindows
          ? path.join(Platform.environment['APPDATA']!, 'MCSM', 'servers')
          : path.join(Platform.environment['HOME']!, '.mcsm', 'servers');

  static String get defaultBackupPath =>
      Platform.isWindows
          ? path.join(Platform.environment['APPDATA']!, 'MCSM', 'backups')
          : path.join(Platform.environment['HOME']!, '.mcsm', 'backups');

  factory Settings.defaults() =>
      Settings(
        serverPath: defaultServerPath,
        javaPath: '',
        backupSettings: BackupSettings.defaults(),
      );

  Settings copyWith({
    String? serverPath,
    String? javaPath,
    bool? startMinimized,
    bool? closeToTray,
    bool? autoUpdate,
    BackupSettings? backupSettings,
  }) {
    return Settings(
      serverPath: serverPath ?? this.serverPath,
      javaPath: javaPath ?? this.javaPath,
      startMinimized: startMinimized ?? this.startMinimized,
      closeToTray: closeToTray ?? this.closeToTray,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      backupSettings: backupSettings ?? this.backupSettings,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'serverPath': serverPath,
      'javaPath': javaPath,
      'startMinimized': startMinimized,
      'closeToTray': closeToTray,
      'autoUpdate': autoUpdate,
      'backup': backupSettings.toJson(),
    };
    print('Converting Settings to JSON. Java path: ${json['javaPath']}');
    return json;
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    print('Creating Settings from JSON. Java path: ${json['javaPath']}');
    return Settings(
      serverPath: json['serverPath'] ?? defaultServerPath,
      javaPath: json['javaPath'] ?? '',
      startMinimized: json['startMinimized'] ?? false,
      closeToTray: json['closeToTray'] ?? true,
      autoUpdate: json['autoUpdate'] ?? true,
      backupSettings: BackupSettings.fromJson(json['backup'] ?? {}),
    );
  }
}

class BackupSettings {
  final String backupPath;
  final bool autoBackup;
  final int frequency;
  final int maxBackups;
  final bool compressBackups;
  final bool backupConfigs;
  final int configMaxBackups;

  BackupSettings({
    required this.backupPath,
    this.autoBackup = true,
    this.frequency = 24,
    this.maxBackups = 5,
    this.compressBackups = true,
    this.backupConfigs = true,
    this.configMaxBackups = 10,
  });

  BackupSettings copyWith({
    String? backupPath,
    bool? autoBackup,
    int? frequency,
    int? maxBackups,
    bool? compressBackups,
    bool? backupConfigs,
    int? configMaxBackups,
  }) {
    return BackupSettings(
      backupPath: backupPath ?? this.backupPath,
      autoBackup: autoBackup ?? this.autoBackup,
      frequency: frequency ?? this.frequency,
      maxBackups: maxBackups ?? this.maxBackups,
      compressBackups: compressBackups ?? this.compressBackups,
      backupConfigs: backupConfigs ?? this.backupConfigs,
      configMaxBackups: configMaxBackups ?? this.configMaxBackups,
    );
  }

  Future<void> ensureBackupDirectoryExists() async {
    final dir = Directory(backupPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  String getBackupFilename(String serverId, DateTime timestamp) {
    final date = timestamp.toIso8601String().replaceAll(':', '-');
    return path.join(backupPath, '${serverId}_$date.zip');
  }

  Future<List<FileSystemEntity>> listBackups(String serverId) async {
    final dir = Directory(backupPath);
    if (!await dir.exists()) {
      return [];
    }

    final List<FileSystemEntity> backups = await dir
        .list()
        .where((entity) =>
    path.basename(entity.path).startsWith('${serverId}_') &&
        path.basename(entity.path).endsWith('.zip'))
        .toList();

    backups.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    return backups;
  }

  Future<void> cleanOldBackups(String serverId) async {
    if (maxBackups <= 0) return;

    final backups = await listBackups(serverId);
    if (backups.length > maxBackups) {
      for (var i = maxBackups; i < backups.length; i++) {
        await backups[i].delete();
      }
    }
  }

  Future<bool> shouldCreateBackup(String serverId) async {
    if (!autoBackup) return false;

    final backups = await listBackups(serverId);
    if (backups.isEmpty) return true;

    final lastBackup = backups.first;
    final lastBackupTime = lastBackup.statSync().modified;
    final hoursSinceLastBackup =
        DateTime.now().difference(lastBackupTime).inHours;

    return hoursSinceLastBackup >= frequency;
  }

  bool isValidBackupFile(String path) {
    return File(path).existsSync() && path.toLowerCase().endsWith('.zip');
  }

  // Metodi per json
  Map<String, dynamic> toJson() => {
    'backupPath': backupPath,
    'autoBackup': autoBackup,
    'frequency': frequency,
    'maxBackups': maxBackups,
    'compressBackups': compressBackups,
    'backupConfigs': backupConfigs,
    'configMaxBackups': configMaxBackups,
  };

  factory BackupSettings.fromJson(Map<String, dynamic> json) => BackupSettings(
    backupPath: json['backupPath'] ?? Settings.defaultBackupPath,
    autoBackup: json['autoBackup'] ?? true,
    frequency: json['frequency'] ?? 24,
    maxBackups: json['maxBackups'] ?? 5,
    compressBackups: json['compressBackups'] ?? true,
    backupConfigs: json['backupConfigs'] ?? true,
    configMaxBackups: json['configMaxBackups'] ?? 10,
  );

  factory BackupSettings.defaults() => BackupSettings(
    backupPath: Settings.defaultBackupPath,
  );
}