import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:archive/archive.dart';

enum ServerType {
  vanilla,
  paper
}

class MinecraftVersion {
  final String id;
  final String? releaseDate;
  final String type; // release, snapshot
  final String? url;

  MinecraftVersion({
    required this.id,
    this.releaseDate,
    required this.type,
    this.url,
  });

  factory MinecraftVersion.fromJson(Map<String, dynamic> json) {
    return MinecraftVersion(
      id: json['id'] as String,
      releaseDate: json['releaseTime'] as String?,
      type: json['type'] as String,
      url: json['url'] as String?,
    );
  }
}

class MinecraftService {
  static const String vanillaVersionManifestUrl = 'https://launchermeta.mojang.com/mc/game/version_manifest.json';
  static const String paperApiUrl = 'https://api.papermc.io/v2/projects/paper';
  
  Future<List<MinecraftVersion>> getAvailableVersions(ServerType type) async {
    switch (type) {
      case ServerType.vanilla:
        return _getVanillaVersions();
      case ServerType.paper:
        return _getPaperVersions();
    }
  }

  List<String> _sortVersionsDescending(List<String> versions) {
    versions.sort((a, b) {
      List<int> partsA = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> partsB = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < partsA.length && i < partsB.length; i++) {
        if (partsA[i] != partsB[i]) {
          return partsB[i].compareTo(partsA[i]);
        }
      }
      return partsB.length.compareTo(partsA.length);
    });
    return versions;
  }

  Future<List<MinecraftVersion>> _getVanillaVersions() async {
    final response = await http.get(Uri.parse(vanillaVersionManifestUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final versions = data['versions'] as List;
      
      return versions
          .where((v) => v['type'] == 'release' && _isVersionSupported(v['id']))
          .map((v) => MinecraftVersion.fromJson(v))
          .toList();
    }
    throw Exception('Failed to load vanilla versions');
  }

  Future<List<MinecraftVersion>> _getPaperVersions() async {
    final response = await http.get(Uri.parse(paperApiUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<String> versions = (data['versions'] as List)
          .map((v) => v.toString())
          .where((v) => _isVersionSupported(v))
          .toList();
          
      versions = _sortVersionsDescending(versions);
      
      return versions
          .map((v) => MinecraftVersion(
                id: v,
                releaseDate: '',
                type: 'release',
                url: '$paperApiUrl/versions/$v',
              ))
          .toList();
    }
    throw Exception('Failed to load paper versions');
  }

  bool _isVersionSupported(String version) {
    try {
      final parts = version.split('.');
      final major = int.parse(parts[1]); // es: 1.8.9 -> 8
      return major >= 8; // Supportiamo dalla 1.8.x in poi
    } catch (e) {
      return false;
    }
  }

  Future<String> downloadServer(String version, ServerType type, String basePath, String serverName) async {
    // Crea la directory del server
    final serverDir = Directory(path.join(basePath, serverName));
    if (!await serverDir.exists()) {
      await serverDir.create();
    }

    final String serverJarPath = path.join(serverDir.path, 'server.jar');
    String downloadUrl;

    switch (type) {
      case ServerType.vanilla:
        downloadUrl = await _getVanillaDownloadUrl(version);
        break;
      case ServerType.paper:
        downloadUrl = await _getPaperDownloadUrl(version);
        break;
    }

    final response = await http.get(Uri.parse(downloadUrl));
    if (response.statusCode == 200) {
      await File(serverJarPath).writeAsBytes(response.bodyBytes);
      return serverDir.path;
    }
    throw Exception('Failed to download server jar');
  }

  Future<String> _getVanillaDownloadUrl(String version) async {
    final response = await http.get(Uri.parse(vanillaVersionManifestUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final versionInfo = (data['versions'] as List)
          .firstWhere((v) => v['id'] == version);
      
      final versionResponse = await http.get(Uri.parse(versionInfo['url']));
      if (versionResponse.statusCode == 200) {
        final versionData = json.decode(versionResponse.body);
        return versionData['downloads']['server']['url'];
      }
    }
    throw Exception('Failed to get vanilla download URL');
  }

  Future<String> _getPaperDownloadUrl(String version) async {
    // Prima otteniamo tutte le build disponibili per la versione
    final buildsResponse = await http.get(
      Uri.parse('https://api.papermc.io/v2/projects/paper/versions/$version/builds')
    );
    
    if (buildsResponse.statusCode == 200) {
      final data = json.decode(buildsResponse.body);
      final builds = data['builds'] as List;
      
      if (builds.isEmpty) {
        throw Exception('No builds found for version $version');
      }
      
      final latestBuild = builds.last;
      final buildNumber = latestBuild['build'] as int;
      
      final fileName = 'paper-$version-$buildNumber.jar';
      
      // L'URL di download corretto secondo l'API
      return 'https://api.papermc.io/v2/projects/paper/versions/$version/builds/$buildNumber/downloads/$fileName';
    }
    throw
    
     Exception('Failed to get paper builds');
  }

  Future<String> findJavaPath() async {
    final String javaHome = Platform.environment['JAVA_HOME'] ?? '';
    
    if (javaHome.isNotEmpty) {
      final String javaPath = Platform.isWindows
          ? path.join(javaHome, 'bin', 'java.exe')
          : path.join(javaHome, 'bin', 'java');
          
      if (await File(javaPath).exists()) {
        return javaPath;
      }
    }

    // Cerca nei percorsi comuni
    final List<String> commonPaths = Platform.isWindows
        ? [
            'C:\\Program Files\\Java',
            'C:\\Program Files (x86)\\Java',
          ]
        : [
            '/usr/bin/java',
            '/usr/local/bin/java',
          ];

    for (final String basePath in commonPaths) {
      if (await Directory(basePath).exists()) {
        // Su Windows cerca nelle sottocartelle
        if (Platform.isWindows) {
          final List<FileSystemEntity> entries = await Directory(basePath)
              .list(recursive: true)
              .where((entry) => entry.path.endsWith(Platform.isWindows ? 'java.exe' : 'java'))
              .toList();

          if (entries.isNotEmpty) {
            // Prendi il primo java.exe trovato
            return entries.first.path;
          }
        } else if (await File(basePath).exists()) {
          return basePath;
        }
      }
    }

    
    throw Exception('Java installation not found');
  }
}