import '../entities/minecraft_server.dart';
import '../entities/server_types.dart';

abstract class IServerRepository {
  Future<List<MinecraftServer>> getServers();

  Future<void> addServer(MinecraftServer server);

  Future<void> removeServer(String id);

  Future<void> startServer(MinecraftServer server);

  Future<void> stopServer(String serverId);

  Future<void> sendCommand(String serverId, String command);

  Stream<ServerStatus> getServerStatus(String serverId);

  Stream<String> getServerOutput(String serverId);

  Future<void> createServerBackup(MinecraftServer server);

  Future<void> restoreServerBackup(String backupPath, MinecraftServer server);

  Future<void> createConfigBackup();

  Future<void> restoreConfigBackup(String backupPath);

  Map<String, dynamic> getServerMetrics(String serverId);

  bool isServerRunning(String serverId);
}
