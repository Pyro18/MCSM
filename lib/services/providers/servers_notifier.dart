import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/minecraft_server.dart';
import '../../storage/app_storage.dart';
import 'storage_provider.dart';

class ServersNotifier extends StateNotifier<AsyncValue<List<MinecraftServer>>> {
  final AppStorage _storage;
  
  ServersNotifier(this._storage) : super(const AsyncValue.loading()) {
    _loadServers();
  }

  Future<void> _loadServers() async {
    state = const AsyncValue.loading();
    try {
      final servers = await _storage.loadServers();
      state = AsyncValue.data(servers);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addServer(MinecraftServer server) async {
    final currentState = state;
    if (currentState is AsyncData<List<MinecraftServer>>) {
      final updatedList = [...currentState.value, server];
      await _storage.saveServers(updatedList);
      state = AsyncValue.data(updatedList);
    }
  }

  Future<void> updateServer(MinecraftServer server) async {
    final currentState = state;
    if (currentState is AsyncData<List<MinecraftServer>>) {
      final updatedList = currentState.value
          .map((s) => s.id == server.id ? server : s)
          .toList();
      await _storage.saveServers(updatedList);
      state = AsyncValue.data(updatedList);
    }
  }

  Future<void> removeServer(String serverId) async {
    final currentState = state;
    if (currentState is AsyncData<List<MinecraftServer>>) {
      final updatedList = currentState.value
          .where((s) => s.id != serverId)
          .toList();
      await _storage.saveServers(updatedList);
      state = AsyncValue.data(updatedList);
    }
  }
}

final serversProvider = StateNotifierProvider<ServersNotifier, AsyncValue<List<MinecraftServer>>>((ref) {
  final storage = ref.watch(appStorageProvider);
  return ServersNotifier(storage);
});