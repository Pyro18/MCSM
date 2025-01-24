import 'dart:io';
import 'dart:convert';
import 'package:synchronized/synchronized.dart';

class AtomicStorage {
  final Lock _lock = Lock();
  final String _directory;

  AtomicStorage(this._directory);

  Future<void> init() async {
    final dir = Directory(_directory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Future<T> transaction<T>(Future<T> Function() action) async {
    return await _lock.synchronized(() async {
      try {
        final result = await action();
        return result;
      } catch (e) {
        // if an error occurs, rethrow it
        rethrow;
      }
    });
  }

  Future<void> atomicWrite(String filePath, Map<String, dynamic> data) async {
    final file = File(filePath);
    final tempFile = File('${file.path}.tmp');
    final backupFile = File('${file.path}.bak');

    await transaction(() async {
      try {
        // writes the data to a temp file
        await tempFile.writeAsString(
            JsonEncoder.withIndent('  ').convert(data),
            flush: true
        );

        // if the original file exists, make a backup
        if (await file.exists()) {
          await file.copy(backupFile.path);
        }

        // renames the temp file to the original file
        await tempFile.rename(file.path);

        // if everything went well, delete the backup
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
      } catch (e) {
        // if something goes wrong, restore the backup
        if (await backupFile.exists()) {
          if (await file.exists()) {
            await file.delete();
          }
          await backupFile.rename(file.path);
        }
        rethrow;
      } finally {
        // cleanup
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });
  }

  Future<Map<String, dynamic>> atomicRead(String filePath) async {
    return await transaction(() async {
      final file = File(filePath);
      final backupFile = File('${file.path}.bak');

      try {
        if (await file.exists()) {
          final content = await file.readAsString();
          try {
            return jsonDecode(content) as Map<String, dynamic>;
          } catch (e) {
            // if the file is corrupted, try to restore from backup
            if (await backupFile.exists()) {
              final backupContent = await backupFile.readAsString();
              return jsonDecode(backupContent) as Map<String, dynamic>;
            }
            rethrow;
          }
        }
        return {};
      } catch (e) {
        throw StorageException('Failed to read file: $filePath', e);
      }
    });
  }

  Future<void> validateJson(String content) async {
    try {
      jsonDecode(content);
    } catch (e) {
      throw StorageException('Invalid JSON format', e);
    }
  }
}

class StorageException implements Exception {
  final String message;
  final dynamic originalError;

  StorageException(this.message, [this.originalError]);

  @override
  String toString() => 'StorageException: $message${originalError != null ? ' ($originalError)' : ''}';
}