import 'dart:io';
import 'dart:convert';

class JsonFileStorage {
  Future<Map<String, dynamic>> read(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return {};
    }
    
    final content = await file.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }
  
  Future<void> write(String path, Map<String, dynamic> data) async {
    final file = File(path);
    await file.writeAsString(jsonEncode(data));
  }
  
  Future<void> backup(String sourcePath, String backupPath) async {
    final sourceFile = File(sourcePath);
    if (await sourceFile.exists()) {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFile = File('$backupPath/$timestamp.json');
      await sourceFile.copy(backupFile.path);
    }
  }
}