import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:convert';
import '../models/java_installation.dart';

class JavaService {
  static const List<String> _windowsSearchPaths = [
    r'C:\Program Files\Java',
    r'C:\Program Files (x86)\Java',
    r'C:\Program Files\Eclipse Adoptium',
    r'C:\Program Files\Eclipse Foundation',
    r'C:\Program Files\Microsoft\jdk',
  ];

  static const List<String> _unixSearchPaths = [
    '/usr/lib/jvm',
    '/usr/java',
    '/usr/local/java',
    '/opt/java',
    '/Library/Java/JavaVirtualMachines', // macOS
  ];

  Future<List<JavaInstallation>> detectJavaInstallations() async {
    final List<JavaInstallation> installations = [];
    
    // Check JAVA_HOME first
    final javaHome = Platform.environment['JAVA_HOME'];
    if (javaHome != null && javaHome.isNotEmpty) {
      final javaPath = await _validateJavaPath(
        Platform.isWindows 
          ? path.join(javaHome, 'bin', 'java.exe')
          : path.join(javaHome, 'bin', 'java')
      );
      if (javaPath != null) {
        final version = await _getJavaVersion(javaPath);
        if (version != null) {
          installations.add(JavaInstallation(
            path: javaPath,
            version: version,
            isDefault: true,
          ));
        }
      }
    }

    // Search in common locations
    final searchPaths = Platform.isWindows ? _windowsSearchPaths : _unixSearchPaths;
    
    for (final searchPath in searchPaths) {
      final directory = Directory(searchPath);
      if (await directory.exists()) {
        await for (final entity in directory.list(recursive: true)) {
          if (entity is File && _isJavaExecutable(entity.path)) {
            final javaPath = await _validateJavaPath(entity.path);
            if (javaPath != null) {
              final version = await _getJavaVersion(javaPath);
              if (version != null && !installations.any((inst) => inst.path == javaPath)) {
                installations.add(JavaInstallation(
                  path: javaPath,
                  version: version,
                ));
              }
            }
          }
        }
      }
    }

    return installations;
  }

  bool _isJavaExecutable(String path) {
    final fileName = path.toLowerCase();
    return Platform.isWindows 
      ? fileName.endsWith('java.exe')
      : fileName.endsWith('/bin/java');
  }

  Future<String?> _validateJavaPath(String javaPath) async {
    try {
      final file = File(javaPath);
      if (await file.exists()) {
        // Try to execute java -version to validate
        final result = await Process.run(javaPath, ['-version']);
        if (result.exitCode == 0) {
          return javaPath;
        }
      }
    } catch (e) {
      print('Error validating Java path: $e');
    }
    return null;
  }

  Future<String?> _getJavaVersion(String javaPath) async {
    try {
      final result = await Process.run(javaPath, ['-version']);
      if (result.exitCode == 0) {
        // Java version output comes in stderr
        final versionOutput = result.stderr.toString();
        final match = RegExp(r'version "([^"]+)"').firstMatch(versionOutput);
        if (match != null) {
          return match.group(1);
        }
      }
    } catch (e) {
      print('Error getting Java version: $e');
    }
    return null;
  }

  Future<void> saveJavaInstallations(List<JavaInstallation> installations) async {
    final configDir = await _getConfigDirectory();
    final configFile = File(path.join(configDir.path, 'java_installations.json'));
    
    await configFile.writeAsString(
      jsonEncode(installations.map((inst) => inst.toJson()).toList())
    );
  }

  Future<List<JavaInstallation>> loadJavaInstallations() async {
    try {
      final configDir = await _getConfigDirectory();
      final configFile = File(path.join(configDir.path, 'java_installations.json'));
      
      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        return jsonList
          .map((json) => JavaInstallation.fromJson(json))
          .toList();
      }
    } catch (e) {
      print('Error loading Java installations: $e');
    }
    return [];
  }

  Future<Directory> _getConfigDirectory() async {
    final appData = Platform.isWindows
        ? Platform.environment['APPDATA']
        : Platform.environment['HOME'];
        
    final configDir = Directory(path.join(
      appData!,
      Platform.isWindows ? 'MCSM' : '.mcsm'
    ));
    
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }
    
    return configDir;
  }
}