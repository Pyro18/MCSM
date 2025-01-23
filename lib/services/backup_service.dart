import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import '../models/minecraft_server.dart';

class BackupService {
  final String backupDir;
  final int maxBackups;

  BackupService({
    required this.backupDir,
    this.maxBackups = 5,
  });

  Future<void> createBackup(MinecraftServer server) async {
    final serverDir = Directory(server.path);
    if (!await serverDir.exists()) {
      throw Exception('Server directory not found');
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupFile = File(path.join(
      backupDir,
      '${server.id}_$timestamp.zip',
    ));

    // Crea l'archivio
    final archive = Archive();
    await for (final file in serverDir.list(recursive: true)) {
      if (file is File) {
        final relativePath = path.relative(file.path, from: server.path);
        final data = await file.readAsBytes();
        archive.addFile(
          ArchiveFile(relativePath, data.length, data)
        );
      }
    }

    // Salva il backup
    final encoder = ZipEncoder();
    await backupFile.writeAsBytes(encoder.encode(archive)!);

    // Gestisce la rotazione dei backup
    await _rotateBackups(server.id);
  }

  Future<void> restoreBackup(String backupPath, MinecraftServer server) async {
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
      final outputFile = File(path.join(server.path, file.name));
      await outputFile.create(recursive: true);
      await outputFile.writeAsBytes(file.content as List<int>);
    }
  }

  Future<void> _rotateBackups(String serverId) async {
    final dir = Directory(backupDir);
    if (!await dir.exists()) return;

    final backups = await dir
        .list()
        .where((f) => f.path.startsWith('${serverId}_'))
        .toList();

    if (backups.length > maxBackups) {
      // Ordina per data (più vecchi primi)
      backups.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

      // Rimuove i backup più vecchi
      for (var i = 0; i < backups.length - maxBackups; i++) {
        await backups[i].delete();
      }
    }
  }
}
