import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/minecraft_server.dart';
import '../../../domain/entities/server_types.dart';
import '../../../data/datasources/local/app_storage.dart';

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
    state = const AsyncValue.loading();
    try {
      if (!_initialized) await _init();

      print('Creating new server: $name');
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

      final currentServers = state.valueOrNull ?? [];
      final updatedServers = [...currentServers, server];

      print('Saving server to storage...');
      await _storage.saveServers(updatedServers);
      print('Server saved successfully');

      state = AsyncValue.data(updatedServers);
      print('State updated with new server. Total servers: ${updatedServers.length}');
    } catch (e, stack) {
      print('Error adding server: $e');
      print('Stack trace: $stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> removeServer(String serverId) async {
    try {
      final currentServers = state.valueOrNull ?? [];
      final updatedServers = currentServers.where((s) => s.id != serverId).toList();

      await _storage.saveServers(updatedServers);
      state = AsyncValue.data(updatedServers);
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