import 'dart:io';
import 'server_types.dart';
import 'validation.dart';

class MinecraftServer {
  static final _nameRegExp = RegExp(r'^[a-zA-Z0-9\-_\s]+$');
  static const _minPort = 1024;
  static const _maxPort = 65535;
  static const _minMemory = 512;
  static const _maxMemory = 32768;

  final String id;
  final String name;
  final String version;
  final ServerType type;
  final String path;
  final int port;
  final int memory;
  final bool autoStart;
  final ServerStatus status;
  final String javaPath;
  final Map<String, dynamic> properties;
  final DateTime createdAt;
  final DateTime? lastStarted;
  final String schemaVersion;

  MinecraftServer._({
    required this.id,
    required this.name,
    required this.version,
    required this.type,
    required this.path,
    required this.port,
    required this.memory,
    required this.autoStart,
    required this.status,
    required this.javaPath,
    required this.properties,
    required this.createdAt,
    this.lastStarted,
    this.schemaVersion = '1.0.0',
  });

  factory MinecraftServer({
    required String id,
    required String name,
    required String version,
    required ServerType type,
    required String path,
    required int port,
    required int memory,
    bool autoStart = false,
    ServerStatus status = ServerStatus.stopped,
    required String javaPath,
    Map<String, dynamic> properties = const {},
    DateTime? createdAt,
    DateTime? lastStarted,
    String schemaVersion = '1.0.0',
  }) {
    // Validazione
    if (!_nameRegExp.hasMatch(name)) {
      throw ValidationError(
        'Server name can only contain letters, numbers, spaces, hyphens and underscores',
        'name'
      );
    }

    if (port < _minPort || port > _maxPort) {
      throw ValidationError(
        'Port must be between $_minPort and $_maxPort',
        'port'
      );
    }

    if (memory < _minMemory || memory > _maxMemory) {
      throw ValidationError(
        'Memory must be between $_minMemory and $_maxMemory MB',
        'memory'
      );
    }

    if (!File(javaPath).existsSync()) {
      throw ValidationError(
        'Java executable not found',
        'javaPath'
      );
    }

    return MinecraftServer._(
      id: id,
      name: name,
      version: version,
      type: type,
      path: path,
      port: port,
      memory: memory,
      autoStart: autoStart,
      status: status,
      javaPath: javaPath,
      properties: Map.from(properties),
      createdAt: createdAt ?? DateTime.now(),
      lastStarted: lastStarted,
      schemaVersion: schemaVersion,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'name': name,
      'version': version,
      'type': type.toString().split('.').last,
      'path': path,
      'port': port,
      'memory': memory,
      'autoStart': autoStart,
      'status': status.toString().split('.').last,
      'javaPath': javaPath,
      'properties': properties,
      'createdAt': createdAt.toIso8601String(),
      'schemaVersion': schemaVersion,
    };

    if (lastStarted != null) {
      json['lastStarted'] = lastStarted!.toIso8601String();
    }

    return json;
  }

  factory MinecraftServer.fromJson(Map<String, dynamic> json) {
    return MinecraftServer(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      type: ServerType.values.firstWhere(
            (e) => e.toString().split('.').last == json['type'],
      ),
      path: json['path'] as String,
      port: json['port'] as int,
      memory: json['memory'] as int,
      autoStart: json['autoStart'] as bool? ?? false,
      status: ServerStatus.values.firstWhere(
            (e) => e.toString().split('.').last == json['status'],
        orElse: () => ServerStatus.stopped,
      ),
      javaPath: json['javaPath'] as String,
      properties: json['properties'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastStarted: json['lastStarted'] == null
          ? null
          : DateTime.parse(json['lastStarted'] as String),
    );
  }
}
