import 'dart:convert';
import 'dart:io';
import '../models/config_model.dart';
import '../models/minecraft_server.dart';
import 'storage_config.dart';

class AppStorage {
  Future<void> init() async {
    final directories = [
      StorageConfig.rootPath,
      StorageConfig.dataPath,
      StorageConfig.backupsPath,
    ];
    
    for (final dir in directories) {
      final directory = Directory(dir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }
  }

  Future<ConfigModel> loadConfig() async {
    try {
      final file = File(StorageConfig.configPath);
      if (!await file.exists()) {
        return ConfigModel.defaults();
      }
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return ConfigModel.fromJson(json);
    } catch (e) {
      print('Error loading config: $e');
      return ConfigModel.defaults();
    }
  }

  Future<void> saveConfig(ConfigModel config) async {
    final file = File(StorageConfig.configPath);
    await file.writeAsString(jsonEncode(config.toJson()));
  }

  Future<List<MinecraftServer>> loadServers() async {
    try {
      final file = File(StorageConfig.serversPath);
      if (!await file.exists()) {
        return [];
      }
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final List<dynamic> serverList = json['servers'] ?? [];
      return serverList.map((s) => MinecraftServer.fromJson(s)).toList();
    } catch (e) {
      print('Error loading servers: $e');
      return [];
    }
  }

  Future<void> saveServers(List<MinecraftServer> servers) async {
    final file = File(StorageConfig.serversPath);
    await file.writeAsString(jsonEncode({
      'servers': servers.map((s) => s.toJson()).toList(),
    }));
  }
}