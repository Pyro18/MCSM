import 'dart:io';

class StorageConfig {
  static const String appFolder = 'MCSM';
  static const String dataFolder = 'data';
  static const String configFile = 'config.json';
  static const String serversFile = 'servers.json';
  static const String backupFolder = 'backups';

  static String get defaultServerPath => Platform.isWindows
      ? '${Platform.environment['USERPROFILE']}\\AppData\\Roaming\\$appFolder\\servers'
      : '${Platform.environment['HOME']}/.${appFolder.toLowerCase()}/servers';

  static String get rootPath => Platform.isWindows
      ? '${Platform.environment['APPDATA']}\\$appFolder'
      : '${Platform.environment['HOME']}/.${appFolder.toLowerCase()}';

  static String get dataPath => '$rootPath/$dataFolder';
  static String get configPath => '$dataPath/$configFile';
  static String get serversPath => '$dataPath/$serversFile';
  static String get backupsPath => '$rootPath/$backupFolder';
}