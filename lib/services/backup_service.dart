import 'dart:convert';
import 'dart:io';
import 'package:mcsm/services/storage/storage_config.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import '../models/minecraft_server.dart';
import '../models/settings_model.dart';

class BackupService {
  final String backupDir;
  final BackupSettings settings;

  BackupService({
    required this.backupDir,
    required this.settings,
  });

  Future<String> createServerBackup(MinecraftServer server) async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupFile = File(path.join(
      backupDir,
      'servers',
      '${server.id}_$timestamp.zip',
    ));

    await backupFile.parent.create(recursive: true);

    final archive = Archive();

    await _addDirectoryToArchive(
      Directory(server.path),
      archive,
      baseDir: server.path,
    );

    final serverConfig = server.toJson();
    final configBytes = utf8.encode(json.encode(serverConfig));
    archive.addFile(
        ArchiveFile('server_config.json', configBytes.length, configBytes)
    );

    final encoder = ZipEncoder();
    await backupFile.writeAsBytes(encoder.encode(archive)!);

    await _rotateBackups(
      path.join(backupDir, 'servers'),
      server.id,
      settings.maxBackups,
    );

    return backupFile.path;
  }

  Future<String> createConfigBackup() async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupFile = File(path.join(
      backupDir,
      'configs',
      'config_$timestamp.zip',
    ));

    await backupFile.parent.create(recursive: true);

    final archive = Archive();

    final configDir = Directory(path.join(StorageConfig.rootPath, 'data'));
    if (await configDir.exists()) {
      await _addDirectoryToArchive(
        configDir,
        archive,
        baseDir: configDir.path,
        filter: (file) => file.path.endsWith('.json'),
      );
    }

    final encoder = ZipEncoder();
    await backupFile.writeAsBytes(encoder.encode(archive)!);

    await _rotateBackups(
      path.join(backupDir, 'configs'),
      'config',
      settings.maxBackups,
    );

    return backupFile.path;
  }

  Future<void> restoreServerBackup(String backupPath, MinecraftServer server) async {
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      throw Exception('Backup file not found');
    }

    final bytes = await backupFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final serverDir = Directory(server.path);
    if (await serverDir.exists()) {
      await serverDir.delete(recursive: true);
    }
    await serverDir.create();

    for (final file in archive.files) {
      if (file.name == 'server_config.json') continue;

      final outputFile = File(path.join(server.path, file.name));
      await outputFile.create(recursive: true);
      await outputFile.writeAsBytes(file.content as List<int>);
    }
  }

  Future<void> restoreConfigBackup(String backupPath) async {
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      throw Exception('Backup file not found');
    }

    final bytes = await backupFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final configDir = Directory(path.join(StorageConfig.rootPath, 'data'));
    await configDir.create(recursive: true);

    for (final file in archive.files) {
      final outputFile = File(path.join(configDir.path, file.name));
      await outputFile.create(recursive: true);
      await outputFile.writeAsBytes(file.content as List<int>);
    }
  }

  Future<void> _addDirectoryToArchive(
      Directory directory,
      Archive archive, {
        required String baseDir,
        bool Function(File)? filter,
      }) async {
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        if (filter != null && !filter(entity)) continue;

        final relativePath = path.relative(entity.path, from: baseDir);
        final data = await entity.readAsBytes();
        archive.addFile(
            ArchiveFile(relativePath, data.length, data)
        );
      }
    }
  }

  Future<void> _rotateBackups(
      String directory,
      String prefix,
      int maxBackups,
      ) async {
    final dir = Directory(directory);
    if (!await dir.exists()) return;

    final backups = await dir
        .list()
        .where((f) => path.basename(f.path).startsWith('${prefix}_'))
        .toList();

    if (backups.length > maxBackups) {
      backups.sort((a, b) =>
          a.statSync().modified.compareTo(b.statSync().modified));

      for (var i = 0; i < backups.length - maxBackups; i++) {
        await backups[i].delete();
      }
    }
  }
}