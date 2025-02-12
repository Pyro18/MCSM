import '../../domain/repositories/server_repository.dart';
import '../../domain/entities/minecraft_server.dart';
import '../../domain/entities/server_types.dart';
import '../datasources/remote/server_process_service.dart';
import '../datasources/local/app_storage.dart';
import '../datasources/remote/backup_service.dart';

class ServerRepositoryImpl implements IServerRepository {
  final ServerProcessService _processService;
  final AppStorage _storage;
  final BackupService _backupService;

  ServerRepositoryImpl(this._processService, this._storage, this._backupService);

  @override
  Future<List<MinecraftServer>> getServers() => _storage.loadServers();

  @override
  Future<void> addServer(MinecraftServer server) async {
    final servers = await getServers();
    servers.add(server);
    await _storage.saveServers(servers);
  }

  @override
  Future<void> removeServer(String id) async {
    final servers = await getServers();
    servers.removeWhere((s) => s.id == id);
    await _storage.saveServers(servers);
  }

  @override
  Future<void> startServer(MinecraftServer server) =>
      _processService.startServer(server);

  @override
  Future<void> stopServer(String serverId) =>
      _processService.stopServer(serverId);

  @override
  Future<void> sendCommand(String serverId, String command) =>
      _processService.sendCommand(serverId, command);

  @override
  Stream<ServerStatus> getServerStatus(String serverId) =>
      _processService.getServerStatus(serverId) ?? Stream.empty();

  @override
  Stream<String> getServerOutput(String serverId) =>
      _processService.getServerOutput(serverId) ?? Stream.empty();

  @override
  Future<void> createServerBackup(MinecraftServer server) =>
      _backupService.createServerBackup(server);

  @override
  Future<void> restoreServerBackup(String backupPath, MinecraftServer server) =>
      _backupService.restoreServerBackup(backupPath, server);

  @override
  Future<void> createConfigBackup() => _backupService.createConfigBackup();

  @override
  Future<void> restoreConfigBackup(String backupPath) =>
      _backupService.restoreConfigBackup(backupPath);

  @override
  Map<String, dynamic> getServerMetrics(String serverId) =>
      _processService.getServerMetrics(serverId);

  @override
  bool isServerRunning(String serverId) =>
      _processService.isServerRunning(serverId);
}