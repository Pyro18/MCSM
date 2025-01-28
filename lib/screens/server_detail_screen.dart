import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/eula_dialog.dart';
import 'console_screen.dart';

import '../models/minecraft_server.dart';
import '../models/server_types.dart';
import '../services/providers/server_process_provider.dart';

class ServerDetailScreen extends ConsumerStatefulWidget {
  final MinecraftServer server;

  const ServerDetailScreen({
    super.key,
    required this.server,
  });

  @override
  ConsumerState<ServerDetailScreen> createState() => _ServerDetailScreenState();
}

class _ServerDetailScreenState extends ConsumerState<ServerDetailScreen> {
  final List<FlSpot> _cpuData = [];
  final List<FlSpot> _memoryData = [];
  final List<FlSpot> _networkData = [];
  bool _eulaDialogShown = false;

  // Queste funzioni rimangono perché sono specifiche del server
  Future<void> _restartServer() async {
    final service = ref.read(serverProcessServiceProvider);
    try {
      if (service.isServerRunning(widget.server.id)) {
        await service.stopServer(widget.server.id);
        await Future.delayed(const Duration(seconds: 2));
      }
      await service.startServer(widget.server);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restarting server: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _checkAndShowEula(String output) {
    if (!_eulaDialogShown && output.contains('You need to agree to the EULA')) {
      _eulaDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => EulaDialog(
              serverPath: widget.server.path,
              onAccept: _restartServer,
            ),
          ).then((_) => _eulaDialogShown = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(serverStatusProvider(widget.server.id));
    final outputAsync = ref.watch(serverOutputProvider(widget.server.id));
    final metricsAsync = ref.watch(serverMetricsProvider(widget.server.id));

    // Controlliamo l'EULA quando riceviamo nuovo output
    outputAsync.whenData((output) {
      if (output.isNotEmpty) {
        _checkAndShowEula(output);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.server.name),
        actions: [
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final service = ref.read(serverProcessServiceProvider);
                  service.startServer(widget.server);
                },
                child: const Text('Start'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: _restartServer,
                child: const Text('Restart'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final service = ref.read(serverProcessServiceProvider);
                  service.stopServer(widget.server.id);
                },
                child: const Text('Stop'),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicatore di stato
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: statusAsync.when(
              data: (status) => Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: status == ServerStatus.running
                          ? Colors.green
                          : status == ServerStatus.stopped
                          ? Colors.grey
                          : status == ServerStatus.error
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status.displayName,
                    style: TextStyle(
                      color: status == ServerStatus.running
                          ? Colors.green
                          : status == ServerStatus.stopped
                          ? Colors.grey
                          : status == ServerStatus.error
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error getting server status'),
            ),
          ),

          // Console e metriche
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Console Screen
                  Expanded(
                    flex: 2,
                    child: ConsoleScreen(
                      output: outputAsync.when(
                        data: (output) => output,
                        loading: () => null,
                        error: (_, __) => null,
                      ),
                      onSendCommand: (command) {
                        final service = ref.read(serverProcessServiceProvider);
                        service.sendCommand(widget.server.id, command);
                      },
                    ),
                  ),

                  // Right sidebar (Metrics)
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 300,
                    child: metricsAsync.when(
                      data: (metrics) => Column(
                        children: [
                          _MetricCard(
                            title: 'Address',
                            value: '${widget.server.port}',
                            icon: Icons.computer,
                          ),
                          const SizedBox(height: 16),
                          _MetricCard(
                            title: 'CPU Load',
                            value: '${metrics['cpuUsage'].toStringAsFixed(2)}%',
                            icon: Icons.memory,
                          ),
                          const SizedBox(height: 16),
                          _MetricCard(
                            title: 'Memory',
                            value:
                            '${(metrics['memoryUsage'] / 1024).toStringAsFixed(2)} GB',
                            icon: Icons.storage,
                            maxValue: widget.server.memory.toDouble(),
                            currentValue: metrics['memoryUsage'].toDouble(),
                          ),
                          const SizedBox(height: 16),
                          _MetricCard(
                            title: 'Players',
                            value: '${metrics['playersOnline']}',
                            icon: Icons.people,
                          ),
                          const SizedBox(height: 16),
                          _MetricCard(
                            title: 'TPS',
                            value: metrics['tps'].toStringAsFixed(1),
                            icon: Icons.speed,
                          ),
                        ],
                      ),
                      loading: () =>
                      const Center(child: CircularProgressIndicator()),
                      error: (_, __) =>
                      const Center(child: Text('Error loading metrics')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final double? maxValue;
  final double? currentValue;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.maxValue,
    this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (maxValue != null && currentValue != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: currentValue! / maxValue!,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ],
      ),
    );
  }
}
