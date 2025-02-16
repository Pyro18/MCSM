import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/minecraft_server.dart';
import '../../../domain/entities/server_types.dart';
import '../../providers/server/server_process_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/server/eula_dialog.dart';
import '../../widgets/common/play_time_display.dart';
import '../../widgets/server/server_settings_dialog.dart';
import 'console_screen.dart';

class ServerDetailScreen extends ConsumerStatefulWidget {
  final MinecraftServer server;

  const ServerDetailScreen({
    super.key,
    required this.server,
  });

  @override
  ConsumerState<ServerDetailScreen> createState() => _ServerDetailScreenState();
}

class _ServerDetailScreenState extends ConsumerState<ServerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showSettings = false;
  bool _eulaDialogShown = false;
  String _selectedLogFile = 'Live Log';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  Widget _buildHeader(ServerStatus status) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 16),
          // Server Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.dns, color: AppTheme.primaryGreen, size: 24),
          ),
          const SizedBox(width: 16),
          // Server Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.server.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.memory, size: 16),
                          const SizedBox(width: 4),
                          Text(widget.server.version),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.dns_outlined, size: 16),
                          const SizedBox(width: 4),
                          Text(widget.server.type.displayName),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    PlayTimeDisplay(playTime: widget.server.totalPlayTime),
                  ],
                ),
              ],
            ),
          ),
          // Action Buttons
          Row(
            children: [
              // Server Status Indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: status == ServerStatus.running
                            ? AppTheme.primaryGreen
                            : status == ServerStatus.stopped
                                ? Colors.grey
                                : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Play/Stop Button
              if (status == ServerStatus.stopped)
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow,
                      size: 20, color: Colors.black),
                  label: const Text('Play'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => ref
                      .read(serverProcessServiceProvider)
                      .startServer(widget.server),
                )
              else
                OutlinedButton.icon(
                  icon: const Icon(Icons.stop, size: 20),
                  label: const Text('Stop'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => ref
                      .read(serverProcessServiceProvider)
                      .stopServer(widget.server.id),
                ),
              const SizedBox(width: 8),
              // Settings Button
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => setState(() => _showSettings = true),
                  tooltip: 'Settings',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ServerStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: status == ServerStatus.running
                  ? Colors.green
                  : status == ServerStatus.stopped
                      ? Colors.grey
                      : Colors.orange,
            ),
          ),
          Text(status.displayName),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
      ),
      child: Row(
        children: [
          _buildTab('Overview', 0),
          _buildTab('Console', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final selected = _tabController.index == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _tabController.animateTo(index),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryGreen.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              Icon(
                index == 0 ? Icons.dashboard : Icons.terminal,
                size: 18,
                color: selected ? AppTheme.primaryGreen : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppTheme.primaryGreen : Colors.grey,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogs(String? output) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Log Controls
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLogFile,
                      items: [
                        'Live Log',
                        'latest.log',
                        'latest.log.1',
                        'latest.log.2',
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedLogFile = value);
                        }
                      },
                      style: const TextStyle(fontSize: 14),
                      icon: const Icon(Icons.arrow_drop_down),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {},
                  tooltip: 'Copy',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () {},
                  tooltip: 'Clear',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () {},
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Console Output
          Expanded(
            child: ConsoleScreen(
              serverId: widget.server.id,
              output: output,
              onSendCommand: (command) {
                final service = ref.read(serverProcessServiceProvider);
                service.sendCommand(widget.server.id, command);
              },
              serverPath: widget.server.path,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(serverStatusProvider(widget.server.id));
    final outputAsync = ref.watch(serverOutputProvider(widget.server.id));

    outputAsync.whenData((output) {
      if (output.isNotEmpty) {
        _checkAndShowEula(output);
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              statusAsync.when(
                data: (status) => _buildHeader(status),
                loading: () => _buildHeader(ServerStatus.stopped),
                error: (_, __) => _buildHeader(ServerStatus.error),
              ),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    const Center(
                      child: Text(
                        'Content Coming Soon...',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: ConsoleScreen(
                        serverId: widget.server.id,
                        output: outputAsync.when(
                          data: (output) => output,
                          loading: () => null,
                          error: (_, __) => null,
                        ),
                        onSendCommand: (command) {
                          final service = ref.read(serverProcessServiceProvider);
                          service.sendCommand(widget.server.id, command);
                        },
                        serverPath: widget.server.path,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showSettings)
            ServerSettingsDialog(
              server: widget.server,
              onClose: () => setState(() => _showSettings = false),
            ),
        ],
      ),
    );
  }
}
