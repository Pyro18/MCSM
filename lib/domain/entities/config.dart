import '../../data/datasources/local/storage_config.dart';
import 'settings.dart';

class ConfigModel {
  final String serverInstallPath;
  final String javaPath;
  final bool autoStart;
  final bool closeToTray;
  final bool checkUpdatesAutomatically;
  final BackupSettings backupSettings;
  final String version;

  ConfigModel({
    required this.serverInstallPath,
    required this.javaPath,
    this.autoStart = false,
    this.closeToTray = true,
    this.checkUpdatesAutomatically = true,
    required this.backupSettings,
    this.version = '1.0.0',
  });

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    final serverPath = json['serverInstallPath'] as String? ?? StorageConfig.defaultServerPath;

    return ConfigModel(
      serverInstallPath: serverPath.isEmpty ? StorageConfig.defaultServerPath : serverPath,
      javaPath: json['javaPath'] as String? ?? '',
      autoStart: json['autoStart'] as bool? ?? false,
      closeToTray: json['closeToTray'] as bool? ?? true,
      checkUpdatesAutomatically: json['checkUpdatesAutomatically'] as bool? ?? true,
      backupSettings: BackupSettings.fromJson(json['backup'] ?? {}),
      version: json['version'] as String? ?? '1.0.0',
    );
  }

  Map<String, dynamic> toJson() => {
    'serverInstallPath': serverInstallPath,
    'javaPath': javaPath,
    'autoStart': autoStart,
    'closeToTray': closeToTray,
    'checkUpdatesAutomatically': checkUpdatesAutomatically,
    'backup': backupSettings.toJson(),
    'version': version,
  };

  factory ConfigModel.defaults() => ConfigModel(
    serverInstallPath: StorageConfig.defaultServerPath,
    javaPath: '',
    autoStart: false,
    closeToTray: true,
    checkUpdatesAutomatically: true,
    backupSettings: BackupSettings.defaults(),
    version: '1.0.0',
  );

  ConfigModel copyWith({
    String? serverInstallPath,
    String? javaPath,
    bool? autoStart,
    bool? closeToTray,
    bool? checkUpdatesAutomatically,
    BackupSettings? backupConfig,
    String? version,
  }) {
    return ConfigModel(
      serverInstallPath: serverInstallPath ?? this.serverInstallPath,
      javaPath: javaPath ?? this.javaPath,
      autoStart: autoStart ?? this.autoStart,
      closeToTray: closeToTray ?? this.closeToTray,
      checkUpdatesAutomatically: checkUpdatesAutomatically ?? this.checkUpdatesAutomatically,
      backupSettings: backupConfig ?? this.backupSettings,
      version: version ?? this.version,
    );
  }
}