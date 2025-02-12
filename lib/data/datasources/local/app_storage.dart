import 'dart:io';

import '../../../domain/entities/minecraft_server.dart';
import 'atomic_storage.dart';
import 'storage_config.dart';

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
      if (!await File(StorageConfig.serversPath).exists()) {
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

  Future<List<MinecraftServer>> loadServers() async {
    try {
      final json = await _storage.atomicRead(StorageConfig.serversPath);
      final List<dynamic> serverList = json['servers'] ?? [];
      final servers =
          serverList.map((s) => MinecraftServer.fromJson(s)).toList();
      print('Loaded ${servers.length} servers from storage');
      return servers;
    } catch (e) {
      print('Error loading servers: $e');
      rethrow;
    }
  }

  Future<void> saveServers(List<MinecraftServer> servers) async {
    try {
      print('Attempting to save ${servers.length} servers');
      final json = {
        'servers': servers.map((s) => s.toJson()).toList(),
        'schemaVersion': '1.0.0'
      };
      await _storage.atomicWrite(StorageConfig.serversPath, json);
      print('Successfully saved servers to: ${StorageConfig.serversPath}');

      final savedContent = await _storage.atomicRead(StorageConfig.serversPath);
      print('Verification - Saved content: $savedContent');
    } catch (e, stack) {
      print('Error saving servers: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }
}
