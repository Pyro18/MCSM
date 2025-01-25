import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/minecraft_server.dart';
import '../../models/server_types.dart';
import '../storage/app_storage.dart';

class ServersNotifier extends StateNotifier<List<MinecraftServer>> {
  final AppStorage _storage = AppStorage();

  ServersNotifier() : super([]) {
    _loadServers();
  }

  Future<void> _loadServers() async {
    try {
      await _storage.init();
      final servers = await _storage.loadServers();
      state = servers;
    } catch (e) {
      print('Error loading servers: $e');
    }
  }

  void addServer(
    String name,
    String version,
    ServerType type,
    String path,
    int port,
    int memory,
    bool autoStart,
    String javaPath,
  ) {
    final server = MinecraftServer(
      id: const Uuid().v4(),
      name: name,
      version: version,
      type: type,
      path: path,
      port: port,
      memory: memory,
      autoStart: autoStart,
      status: ServerStatus.stopped,
      javaPath: javaPath,
      properties: {},
    );

    state = [...state, server];
    _saveServers();
  }

  void removeServer(String serverId) {
    state = state.where((s) => s.id != serverId).toList();
    _saveServers();
  }

  Future<void> _saveServers() async {
    try {
      await _storage.saveServers(state);
    } catch (e) {
      print('Error saving servers: $e');
    }
  }
}

final serversProvider =
    StateNotifierProvider<ServersNotifier, List<MinecraftServer>>((ref) {
  return ServersNotifier();
});
