import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/minecraft_server.dart';
import '../../models/server_types.dart';
import '../storage/app_storage.dart';

class ServersNotifier extends StateNotifier<AsyncValue<List<MinecraftServer>>> {
  final AppStorage _storage = AppStorage();
  bool _initialized = false;

  ServersNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;

    state = const AsyncValue.loading();
    try {
      await _storage.init();
      final servers = await _storage.loadServers();
      state = AsyncValue.data(servers);
      _initialized = true;
      print('Loaded ${servers.length} servers');
    } catch (e, stack) {
      print('Error initializing servers: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addServer(
      String name,
      String version,
      ServerType type,
      String path,
      int port,
      int memory,
      bool autoStart,
      String javaPath,
      ) async {
    try {
      if (!_initialized) await _init();

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

      final currentServers = state.value ?? [];
      final updatedServers = [...currentServers, server];

      state = AsyncValue.data(updatedServers);
      await _storage.saveServers(updatedServers);

      print('Server added successfully: ${server.name}');
    } catch (e, stack) {
      print('Error adding server: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> removeServer(String serverId) async {
    try {
      final currentServers = state.value ?? [];
      final updatedServers = currentServers.where((s) => s.id != serverId).toList();

      state = AsyncValue.data(updatedServers);
      await _storage.saveServers(updatedServers);
    } catch (e, stack) {
      print('Error removing server: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final serversProvider =
StateNotifierProvider<ServersNotifier, AsyncValue<List<MinecraftServer>>>((ref) {
  return ServersNotifier();
});