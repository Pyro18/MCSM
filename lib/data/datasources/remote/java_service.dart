import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

import '../../../domain/entities/java_installation.dart';
import '../local/storage_config.dart';

class JavaService {
  static const List<String> _windowsSearchPaths = [
    r'C:\Program Files\Java',
    r'C:\Program Files (x86)\Java',
    r'C:\Program Files\Eclipse Adoptium',
    r'C:\Program Files\Eclipse Foundation',
    r'C:\Program Files\Microsoft\jdk',
    r'C:\Program Files\OpenJDK',
    r'C:\Program Files\Zulu',
    r'C:\Program Files\Amazon Corretto',
  ];

  static const List<String> _unixSearchPaths = [
    '/usr/lib/jvm',
    '/usr/java',
    '/usr/local/java',
    '/opt/java',
    '/Library/Java/JavaVirtualMachines',
  ];

  Future<void> saveJavaInstallations(List<JavaInstallation> installations) async {
    try {
      final configFile = File(path.join(StorageConfig.dataPath, 'java_installations.json'));

      print('Saving ${installations.length} Java installations to: ${configFile.path}');
      await configFile.writeAsString(
        jsonEncode(installations.map((inst) => inst.toJson()).toList()),
      );
      print('Java installations saved successfully');
    } catch (e, stack) {
      print('Error saving Java installations: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }

  Future<List<JavaInstallation>> loadJavaInstallations() async {
    try {
      final configFile = File(path.join(StorageConfig.dataPath, 'java_installations.json'));

      if (await configFile.exists()) {
        print('Loading Java installations from: ${configFile.path}');
        final content = await configFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        final installations = jsonList.map((json) => JavaInstallation.fromJson(json)).toList();
        print('Loaded ${installations.length} Java installations');
        return installations;
      }
    } catch (e, stack) {
      print('Error loading Java installations: $e');
      print('Stack trace: $stack');
    }
    return [];
  }

  Future<List<JavaInstallation>> detectJavaInstallations() async {
    final List<JavaInstallation> installations = [];
    bool foundDefault = false;

    try {
      print('Starting Java detection...');

      // 1. Check PATH first
      if (Platform.isWindows) {
        print('Checking system PATH for Java...');
        try {
          final result = await Process.run('where', ['java.exe']);
          if (result.exitCode == 0) {
            final paths = result.stdout.toString().split('\n')
                .where((p) => p.trim().isNotEmpty)
                .toList();

            for (final javaPath in paths) {
              print('Found Java in PATH: ${javaPath.trim()}');
              final version = await validateAndGetVersion(javaPath.trim());
              if (version != null) {
                installations.add(JavaInstallation(
                  path: javaPath.trim(),
                  version: version,
                  isDefault: !foundDefault,
                ));
                foundDefault = true;
                print('Added Java from PATH: ${javaPath.trim()} (version: $version)');
              }
            }
          }
        } catch (e) {
          print('Error checking PATH: $e');
        }
      }

      // 2. Check JAVA_HOME
      final javaHome = Platform.environment['JAVA_HOME'];
      print('Checking JAVA_HOME: $javaHome');

      if (javaHome != null && javaHome.isNotEmpty) {
        final javaPath = Platform.isWindows
            ? path.join(javaHome, 'bin', 'java.exe')
            : path.join(javaHome, 'bin', 'java');

        print('Checking Java executable at: $javaPath');

        if (await _validateJavaPath(javaPath) != null) {
          final version = await validateAndGetVersion(javaPath);
          if (version != null) {
            if (!installations.any((inst) => inst.path == javaPath)) {
              installations.add(JavaInstallation(
                path: javaPath,
                version: version,
                isDefault: !foundDefault,
              ));
              foundDefault = true;
              print('Added Java from JAVA_HOME: $javaPath (version: $version)');
            }
          }
        }
      }

      // 3. Search in common locations
      final searchPaths = Platform.isWindows ? _windowsSearchPaths : _unixSearchPaths;
      print('Searching in common locations...');

      for (final searchPath in searchPaths) {
        print('Searching in: $searchPath');
        final directory = Directory(searchPath);
        if (await directory.exists()) {
          await for (final entity in directory.list(recursive: true)) {
            if (entity is File && _isJavaExecutable(entity.path)) {
              print('Found potential Java executable: ${entity.path}');
              final validPath = await _validateJavaPath(entity.path);
              if (validPath != null) {
                final version = await validateAndGetVersion(validPath);
                if (version != null && !installations.any((inst) => inst.path == validPath)) {
                  installations.add(JavaInstallation(
                    path: validPath,
                    version: version,
                    isDefault: !foundDefault,
                  ));
                  if (!foundDefault) foundDefault = true;
                  print('Added Java installation: $validPath (version: $version)');
                }
              }
            }
          }
        } else {
          print('Directory does not exist: $searchPath');
        }
      }

      print('Java detection completed. Found ${installations.length} installations');
      installations.forEach((inst) {
        print('- ${inst.path} (version: ${inst.version}, default: ${inst.isDefault})');
      });

      return installations;
    } catch (e, stack) {
      print('Error detecting Java installations: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }

  Future<String?> validateAndGetVersion(String javaPath) async {
    try {
      print('Validating Java at: $javaPath');
      final result = await Process.run(javaPath, ['-version']);
      print('Validation output: ${result.stderr}');

      if (result.exitCode == 0) {
        final versionOutput = result.stderr.toString();
        final match = RegExp(r'version "(.*?)"').firstMatch(versionOutput);
        if (match != null) {
          print('Found valid Java version: ${match.group(1)}');
          return match.group(1);
        }
      }
    } catch (e) {
      print('Error validating Java path: $e');
    }
    return null;
  }

  Future<Directory> _getConfigDirectory() async {
    final appData = Platform.isWindows
        ? Platform.environment['APPDATA']
        : Platform.environment['HOME'];

    final configDir = Directory(path.join(appData!, Platform.isWindows ? 'MCSM' : '.mcsm'));

    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }

    return configDir;
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
}