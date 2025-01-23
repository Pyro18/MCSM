import 'dart:io';
import 'package:path/path.dart' as path;

class StorageConfig {
  static const String appFolder = 'MCSM';
  static const String dataFolder = 'data';
  static const String configFile = 'config.json';
  static const String serversFile = 'servers.json';
  static const String backupFolder = 'backups';
  static const String serversFolder = 'servers';

  static String get rootPath => Platform.isWindows
      ? path.join(Platform.environment['APPDATA']!, appFolder)
      : path.join(Platform.environment['HOME']!, '.${appFolder.toLowerCase()}');

  static String get dataPath => path.join(rootPath, dataFolder);
  static String get configPath => path.join(dataPath, configFile);
  static String get serversPath => path.join(dataPath, serversFile);
  static String get backupsPath => path.join(rootPath, backupFolder);
  static String get defaultServerPath => path.join(rootPath, serversFolder);

  static Future<void> ensureDirectoriesExist() async {
    final directories = [
      rootPath,
      dataPath,
      backupsPath,
      defaultServerPath,
    ];

    for (final dir in directories) {
      final directory = Directory(dir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        print('Created directory: $dir');
      }
    }
  }
}