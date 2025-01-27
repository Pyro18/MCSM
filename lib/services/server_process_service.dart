import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/minecraft_server.dart';
import '../models/server_types.dart';

class ServerProcessService {
  final _runningProcesses = <String, Process>{};
  final _processOutputControllers = <String, StreamController<String>>{};
  final _serverStatusControllers = <String, StreamController<ServerStatus>>{};

  // Memory usage in MB
  final _memoryUsage = <String, int>{};
  // CPU usage percentage
  final _cpuUsage = <String, double>{};
  // Players online
  final _playersOnline = <String, int>{};
  // TPS (Ticks Per Second)
  final _tps = <String, double>{};

  Stream<String>? getServerOutput(String serverId) {
    _processOutputControllers[serverId] ??= StreamController<String>.broadcast();
    return _processOutputControllers[serverId]?.stream;
  }

  Stream<ServerStatus>? getServerStatus(String serverId) {
    _serverStatusControllers[serverId] ??= StreamController<ServerStatus>.broadcast();
    // Emit initial status
    _serverStatusControllers[serverId]?.add(ServerStatus.stopped);
    return _serverStatusControllers[serverId]?.stream;
  }

  Future<void> startServer(MinecraftServer server) async {
    if (_runningProcesses.containsKey(server.id)) {
      throw Exception('Server is already running');
    }

    // Ensure stream controllers exist
    _processOutputControllers[server.id] ??= StreamController<String>.broadcast();
    _serverStatusControllers[server.id] ??= StreamController<ServerStatus>.broadcast();

    final outputController = _processOutputControllers[server.id]!;

    // Validation checks
    outputController.add('Performing pre-start checks...\n');

    // Check Java path
    final javaFile = File(server.javaPath);
    if (!await javaFile.exists()) {
      final error = 'Java executable not found at: ${server.javaPath}';
      print(error);
      outputController.add('ERROR: $error\n');
      _serverStatusControllers[server.id]?.add(ServerStatus.error);
      throw Exception(error);
    }
    outputController.add('Java executable found.\n');

    // Check server directory
    final serverDir = Directory(server.path);
    if (!await serverDir.exists()) {
      final error = 'Server directory not found: ${server.path}';
      print(error);
      outputController.add('ERROR: $error\n');
      _serverStatusControllers[server.id]?.add(ServerStatus.error);
      throw Exception(error);
    }
    outputController.add('Server directory found.\n');

    // Check server.jar
    final serverJar = File('${server.path}/server.jar');
    if (!await serverJar.exists()) {
      final error = 'server.jar not found in: ${server.path}';
      print(error);
      outputController.add('ERROR: $error\n');
      _serverStatusControllers[server.id]?.add(ServerStatus.error);
      throw Exception(error);
    }
    outputController.add('server.jar found.\n');

    // List directory contents for debugging
    outputController.add('\nServer directory contents:\n');
    await for (var entity in serverDir.list()) {
      outputController.add('${entity.path}\n');
    }

    // Update server status to starting
    _serverStatusControllers[server.id]?.add(ServerStatus.starting);
    outputController.add('\nStarting server...\n');

    // Prepare Java arguments
    final args = [
      '-Xmx${server.memory}M',
      '-Xms${server.memory}M',
      '-jar',
      'server.jar',
      'nogui'
    ];

    outputController.add('Command: ${server.javaPath} ${args.join(' ')}\n');

    try {
      final process = await Process.start(
        server.javaPath,
        args,
        workingDirectory: server.path,
      );
      _runningProcesses[server.id] = process;
      outputController.add('Process started with PID: ${process.pid}\n');

      // Handle stdout
      process.stdout.transform(utf8.decoder).listen(
            (output) {
          print('Server output: $output');
          outputController.add(output);
          _parseServerOutput(server.id, output);
        },
        onError: (error) {
          print('Error reading stdout: $error');
          outputController.add('Error reading stdout: $error\n');
        },
      );

      // Handle stderr
      process.stderr.transform(utf8.decoder).listen(
            (output) {
          print('Server error: $output');
          outputController.add('ERROR: $output');
        },
        onError: (error) {
          print('Error reading stderr: $error');
          outputController.add('Error reading stderr: $error\n');
        },
      );

      // Handle process exit
      process.exitCode.then((code) {
        print('Server process exited with code: $code');
        _runningProcesses.remove(server.id);
        _serverStatusControllers[server.id]?.add(ServerStatus.stopped);
        outputController.add('Server stopped with exit code: $code\n');
      });

      // Start monitoring server metrics
      _startMetricsMonitoring(server.id, process);

      // Update server status to running
      _serverStatusControllers[server.id]?.add(ServerStatus.running);

    } catch (e, stack) {
      print('Error starting server: $e');
      print('Stack trace: $stack');
      outputController.add('Failed to start server: $e\n');
      outputController.add('Stack trace: $stack\n');
      _serverStatusControllers[server.id]?.add(ServerStatus.error);
      rethrow;
    }
  }

  Future<void> stopServer(String serverId) async {
    final process = _runningProcesses[serverId];
    if (process == null) {
      throw Exception('Server is not running');
    }

    _serverStatusControllers[serverId]?.add(ServerStatus.stopping);

    // Send stop command to server
    process.stdin.writeln('stop');

    // Wait for process to exit
    try {
      await process.exitCode.timeout(const Duration(seconds: 30));
    } catch (e) {
      // If server doesn't stop gracefully, force kill it
      process.kill();
    }

    _runningProcesses.remove(serverId);
    _serverStatusControllers[serverId]?.add(ServerStatus.stopped);
  }

  Future<void> sendCommand(String serverId, String command) async {
    final process = _runningProcesses[serverId];
    if (process == null) {
      throw Exception('Server is not running');
    }

    process.stdin.writeln(command);
  }

  bool isServerRunning(String serverId) {
    return _runningProcesses.containsKey(serverId);
  }

  void _parseServerOutput(String serverId, String output) {
    // Parse TPS
    if (output.contains('TPS from last 1m, 5m, 15m:')) {
      final tpsMatch = RegExp(r'TPS from last 1m, 5m, 15m: ([0-9.]+),').firstMatch(output);
      if (tpsMatch != null) {
        _tps[serverId] = double.parse(tpsMatch.group(1)!);
      }
    }

    // Parse players online
    if (output.contains('players online:')) {
      final playersMatch = RegExp(r'(\d+) players online:').firstMatch(output);
      if (playersMatch != null) {
        _playersOnline[serverId] = int.parse(playersMatch.group(1)!);
      }
    }
  }

  void _startMetricsMonitoring(String serverId, Process process) {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_runningProcesses.containsKey(serverId)) {
        timer.cancel();
        return;
      }

      // Get process metrics
      _updateProcessMetrics(serverId, process);
    });
  }

  Future<void> _updateProcessMetrics(String serverId, Process process) async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('tasklist', ['/FI', 'PID eq ${process.pid}', '/FO', 'CSV']);
        final lines = result.stdout.toString().split('\n');
        if (lines.length > 1) {
          final parts = lines[1].split(',');
          if (parts.length > 4) {
            // Memory in KB, convert to MB
            _memoryUsage[serverId] = int.parse(parts[4].replaceAll(RegExp(r'[^0-9]'), '')) ~/ 1024;
          }
        }
      } else {
        final result = await Process.run('ps', ['-p', '${process.pid}', '-o', '%cpu,%mem,rss']);
        final lines = result.stdout.toString().split('\n');
        if (lines.length > 1) {
          final parts = lines[1].trim().split(RegExp(r'\s+'));
          if (parts.length > 2) {
            _cpuUsage[serverId] = double.parse(parts[0]);
            // RSS is in KB, convert to MB
            _memoryUsage[serverId] = int.parse(parts[2]) ~/ 1024;
          }
        }
      }
    } catch (e) {
      print('Error updating process metrics: $e');
    }
  }

  Map<String, dynamic> getServerMetrics(String serverId) {
    return {
      'memoryUsage': _memoryUsage[serverId] ?? 0,
      'cpuUsage': _cpuUsage[serverId] ?? 0.0,
      'playersOnline': _playersOnline[serverId] ?? 0,
      'tps': _tps[serverId] ?? 20.0,
    };
  }

  void dispose(String serverId) {
    _processOutputControllers[serverId]?.close();
    _processOutputControllers.remove(serverId);
    _serverStatusControllers[serverId]?.close();
    _serverStatusControllers.remove(serverId);
    _runningProcesses[serverId]?.kill();
    _runningProcesses.remove(serverId);
  }
}