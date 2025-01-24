// providers/servers_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/minecraft_server.dart';
import '../storage/app_storage.dart';

final serversProvider = AsyncNotifierProvider<ServersNotifier, List<MinecraftServer>>(ServersNotifier.new);

class ServersNotifier extends AsyncNotifier<List<MinecraftServer>> {
  @override
  Future<List<MinecraftServer>> build() async {
    // Carica i server dal storage
    final storage = AppStorage();
    await storage.init();
    return storage.loadServers();
  }

  Future<void> addServer(MinecraftServer server) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentServers = await future;
      final updatedServers = [...currentServers, server];
      final storage = AppStorage();
      await storage.saveServers(updatedServers);
      return updatedServers;
    });
  }

  Future<void> removeServer(String serverId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentServers = await future;
      final updatedServers = currentServers.where((s) => s.id != serverId).toList();
      final storage = AppStorage();
      await storage.saveServers(updatedServers);
      return updatedServers;
    });
  }
}