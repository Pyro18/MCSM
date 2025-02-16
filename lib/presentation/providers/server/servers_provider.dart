import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/datasources/local/app_storage.dart';
import '../../../data/datasources/remote/server_process_service.dart';
import '../../../data/repositories/server_repository_impl.dart';
import '../../../domain/entities/minecraft_server.dart';
import '../../../domain/entities/server_types.dart';
import '../../../domain/repositories/server_repository.dart';
import 'backup_provider.dart';

// AppStorage provider
final appStorageProvider = FutureProvider<AppStorage>((ref) async {
  final storage = AppStorage();
  await storage.init();
  return storage;
});

final serverProcessServiceProvider = Provider((ref) => ServerProcessService());

final serverRepositoryProvider = FutureProvider<IServerRepository>((ref) async {
  final processService = ref.watch(serverProcessServiceProvider);
  final storage = await ref.watch(appStorageProvider.future);
  final backupService = ref.watch(backupServiceProvider);
  return ServerRepositoryImpl(processService, storage, backupService);
});

class ServersNotifier extends AsyncNotifier<List<MinecraftServer>> {
  @override
  Future<List<MinecraftServer>> build() async {
    try {
      final repository = await ref.watch(serverRepositoryProvider.future);
      return await repository.getServers();
    } catch (e, stack) {
      print('Error in build: $e\n$stack');
      rethrow;
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
      // 1. Otteniamo prima il repository
      final repository = await ref.read(serverRepositoryProvider.future);

      // 2. Creiamo il nuovo server
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
        createdAt: DateTime.now(),
      );

      // 3. Aggiorniamo lo stato a loading
      state = const AsyncValue.loading();

      // 4. Salviamo il server nel repository
      await repository.addServer(server);

      // 5. Ricarichiamo la lista completa dei server
      final updatedServers = await repository.getServers();

      // 6. Aggiorniamo lo stato con la nuova lista
      state = AsyncValue.data(updatedServers);

      print('Server added successfully: ${server.name}');
      print('Total servers after addition: ${updatedServers.length}');
    } catch (e, stack) {
      print('Error adding server: $e');
      print('Stack trace: $stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> removeServer(String serverId) async {
    try {
      final repository = await ref.read(serverRepositoryProvider.future);

      // 1. Rimuoviamo il server
      await repository.removeServer(serverId);

      // 2. Ricarichiamo la lista aggiornata
      final updatedServers = await repository.getServers();

      // 3. Aggiorniamo lo stato
      state = AsyncValue.data(updatedServers);
    } catch (e, stack) {
      print('Error removing server: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final serversProvider = AsyncNotifierProvider<ServersNotifier, List<MinecraftServer>>(
  ServersNotifier.new,
);