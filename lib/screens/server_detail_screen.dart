import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mcsm/widgets/eula_dialog.dart';

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
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<FlSpot> _cpuData = [];
  final List<FlSpot> _memoryData = [];
  final List<FlSpot> _networkData = [];
  final List<String> _consoleHistory = [];
  bool _eulaDialogShown = false;
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent) {
      setState(() => _autoScroll = false);
    } else {
      setState(() => _autoScroll = true);
    }
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _updateConsoleOutput(String newOutput) {
    setState(() {
      _consoleHistory.addAll(newOutput.split('\n').where((line) => line.isNotEmpty));
      // Manteniamo solo le ultime 1000 righe per evitare problemi di memoria
      if (_consoleHistory.length > 1000) {
        _consoleHistory.removeRange(0, _consoleHistory.length - 1000);
      }
    });

    // Scroll to bottom if auto-scroll is enabled
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _restartServer() async {
    final service = ref.read(serverProcessServiceProvider);
    try {
      if (service.isServerRunning(widget.server.id)) {
        await service.stopServer(widget.server.id);

        await Future.delayed(const Duration(seconds: 2));
      }
      // Poi lo riavviamo
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

  void _sendCommand() {
    if (_commandController.text.isEmpty) return;

    final service = ref.read(serverProcessServiceProvider);
    service.sendCommand(widget.server.id, _commandController.text);
    _commandController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(serverStatusProvider(widget.server.id));
    final outputAsync = ref.watch(serverOutputProvider(widget.server.id));
    final metricsAsync = ref.watch(serverMetricsProvider(widget.server.id));

    outputAsync.whenData((output) {
      if (output.isNotEmpty) {
        _updateConsoleOutput(output);
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
                onPressed: () async {
                  final service = ref.read(serverProcessServiceProvider);
                  await service.stopServer(widget.server.id);
                  await Future.delayed(const Duration(seconds: 1));
                  service.startServer(widget.server);
                },
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
                  // Main content (Console)
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2D2D),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: _consoleHistory
                                          .map((line) => Text(
                                                line,
                                                style: const TextStyle(
                                                  fontFamily: 'monospace',
                                                  color: Colors.white,
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Color(0xFF3D3D3D)),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _commandController,
                                          style: const TextStyle(
                                              color: Colors.white),
                                          decoration: const InputDecoration(
                                            hintText: 'Type a command...',
                                            hintStyle:
                                                TextStyle(color: Colors.grey),
                                            border: InputBorder.none,
                                            prefixIcon: Icon(
                                                Icons.keyboard_arrow_right,
                                                color: Colors.grey),
                                          ),
                                          onSubmitted: (_) => _sendCommand(),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.send,
                                            color: Colors.blue),
                                        onPressed: _sendCommand,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
