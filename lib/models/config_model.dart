import 'dart:io';
import '../services/storage/storage_config.dart';
import './backup_config.dart';

class ConfigModel {
  final String serverInstallPath;
  final String javaPath;
  final bool autoStart;
  final BackupConfig backupConfig;
  final String version;

  ConfigModel({
    required this.serverInstallPath,
    required this.javaPath,
    this.autoStart = false,
    required this.backupConfig,
    this.version = '1.0.0',
  });

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    // Ensure we have the correct default paths
    final serverPath = json['serverInstallPath'] ?? StorageConfig.defaultServerPath;

    return ConfigModel(
      serverInstallPath: serverPath,
      javaPath: json['javaPath'] ?? '',
      autoStart: json['autoStart'] ?? false,
      backupConfig: BackupConfig.fromJson(json['backup'] ?? {}),
      version: json['version'] ?? '1.0.0',
    );
  }

  Map<String, dynamic> toJson() => {
    'serverInstallPath': serverInstallPath,
    'javaPath': javaPath,
    'autoStart': autoStart,
    'backup': backupConfig.toJson(),
    'version': version,
  };

  factory ConfigModel.defaults() => ConfigModel(
    serverInstallPath: StorageConfig.defaultServerPath,
    javaPath: '',
    autoStart: false,
    backupConfig: BackupConfig.defaults(),
    version: '1.0.0',
  );
}