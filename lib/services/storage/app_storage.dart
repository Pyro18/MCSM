import 'dart:io';
import 'dart:convert';
import 'storage_config.dart';
import '../../models/config_model.dart';
import '../../models/backup_config.dart';
import '../../models/minecraft_server.dart';

class AppStorage {
  Future<void> init() async {
    try {
      await StorageConfig.ensureDirectoriesExist();

      await _createInitialFiles();

      print('Storage initialized successfully');
    } catch (e) {
      print('Error initializing storage: $e');
      rethrow;
    }
  }

  Future<void> _createInitialFiles() async {
    // Config file
    final configFile = File(StorageConfig.configPath);
    if (!await configFile.exists()) {
      final defaultConfig = ConfigModel(
        serverInstallPath: StorageConfig.defaultServerPath,
        javaPath: '',
        backupConfig: BackupConfig.defaults(),
      );
      await configFile.writeAsString(
        jsonEncode(defaultConfig.toJson()),
        flush: true,
      );
      print('Created config file at: ${configFile.path}');
    }

    // Servers file
    final serversFile = File(StorageConfig.serversPath);
    if (!await serversFile.exists()) {
      await serversFile.writeAsString(
        jsonEncode({'servers': []}),
        flush: true,
      );
      print('Created servers file at: ${serversFile.path}');
    }
  }

  Future<ConfigModel> loadConfig() async {
    try {
      final file = File(StorageConfig.configPath);
      if (!await file.exists()) {
        print('Config file not found, creating default');
        final defaultConfig = ConfigModel.defaults();
        await saveConfig(defaultConfig);
        return defaultConfig;
      }

      final content = await file.readAsString();
      final json = jsonDecode(content);
      return ConfigModel.fromJson(json);
    } catch (e) {
      print('Error loading config: $e');
      final defaultConfig = ConfigModel.defaults();
      await saveConfig(defaultConfig);
      return defaultConfig;
    }
  }

  Future<void> saveConfig(ConfigModel config) async {
    final file = File(StorageConfig.configPath);
    await file.writeAsString(jsonEncode(config.toJson()), flush: true);
    print('Saved config to: ${file.path}');
  }

  Future<List<MinecraftServer>> loadServers() async {
    try {
      final file = File(StorageConfig.serversPath);
      if (!await file.exists()) {
        print('Servers file not found, creating empty list');
        await saveServers([]);
        return [];
      }

      final content = await file.readAsString();
      final json = jsonDecode(content);
      final List<dynamic> serverList = json['servers'] ?? [];
      return serverList.map((s) => MinecraftServer.fromJson(s)).toList();
    } catch (e) {
      print('Error loading servers: $e');
      return [];
    }
  }

  Future<void> saveServers(List<MinecraftServer> servers) async {
    final file = File(StorageConfig.serversPath);
    await file.writeAsString(
      jsonEncode({'servers': servers.map((s) => s.toJson()).toList()}),
      flush: true,
    );
    print('Saved servers to: ${file.path}');
  }
}