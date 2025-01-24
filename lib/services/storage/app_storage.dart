import 'dart:io';
import 'storage_config.dart';
import '../../models/config_model.dart';
import '../../models/minecraft_server.dart';
import './atomic_storage.dart';

class AppStorage {
  late final AtomicStorage _storage;

  Future<void> init() async {
    try {
      await StorageConfig.ensureDirectoriesExist();
      _storage = AtomicStorage(StorageConfig.dataPath);
      await _storage.init();

      await _createInitialFiles();
      print('Storage initialized successfully');
    } catch (e) {
      print('Error initializing storage: $e');
      rethrow;
    }
  }

  Future<void> _createInitialFiles() async {
    try {
      // Config file
      if (!File(StorageConfig.configPath).existsSync()) {
        final defaultConfig = ConfigModel.defaults();
        await _storage.atomicWrite(
          StorageConfig.configPath,
          defaultConfig.toJson(),
        );
        print('Created config file at: ${StorageConfig.configPath}');
      }

      // Servers file
      if (!File(StorageConfig.serversPath).existsSync()) {
        await _storage.atomicWrite(
          StorageConfig.serversPath,
          {'servers': [], 'schemaVersion': '1.0.0'},
        );
        print('Created servers file at: ${StorageConfig.serversPath}');
      }
    } catch (e) {
      throw StorageException('Failed to create initial files', e);
    }
  }

  Future<ConfigModel> loadConfig() async {
    try {
      final json = await _storage.atomicRead(StorageConfig.configPath);
      return ConfigModel.fromJson(json);
    } catch (e) {
      print('Error loading config: $e');
      // In caso di errore, ritorna la configurazione di default
      final defaultConfig = ConfigModel.defaults();
      await saveConfig(defaultConfig);
      return defaultConfig;
    }
  }

  Future<void> saveConfig(ConfigModel config) async {
    try {
      await _storage.atomicWrite(
        StorageConfig.configPath,
        config.toJson(),
      );
      print('Saved config to: ${StorageConfig.configPath}');
    } catch (e) {
      throw StorageException('Failed to save config', e);
    }
  }

  Future<List<MinecraftServer>> loadServers() async {
    try {
      final json = await _storage.atomicRead(StorageConfig.serversPath);
      final List<dynamic> serverList = json['servers'] ?? [];
      return serverList.map((s) => MinecraftServer.fromJson(s)).toList();
    } catch (e) {
      print('Error loading servers: $e');
      return [];
    }
  }

  Future<void> saveServers(List<MinecraftServer> servers) async {
    try {
      await _storage.atomicWrite(
        StorageConfig.serversPath,
        {
          'servers': servers.map((s) => s.toJson()).toList(),
          'schemaVersion': '1.0.0'
        },
      );
      print('Saved servers to: ${StorageConfig.serversPath}');
    } catch (e) {
      throw StorageException('Failed to save servers', e);
    }
  }
}