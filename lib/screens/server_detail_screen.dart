import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/minecraft_server.dart';
import '../models/server_types.dart';
import '../services/providers/server_process_provider.dart';
import '../theme/app_theme.dart';

import '../widgets/eula_dialog.dart';
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

class _ServerDetailScreenState extends ConsumerState<ServerDetailScreen> with SingleTickerProviderStateMixin {
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
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 16),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.dns, color: AppTheme.primaryGreen, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.server.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildInfoChip(
                      widget.server.version,
                      Icons.update,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      widget.server.type.displayName,
                      Icons.settings_ethernet,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(status),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status == ServerStatus.stopped)
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => ref
                      .read(serverProcessServiceProvider)
                      .startServer(widget.server),
                )
              else
                OutlinedButton.icon(
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () => ref
                      .read(serverProcessServiceProvider)
                      .stopServer(widget.server.id),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => setState(() => _showSettings = true),
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
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTab('IDK', 0),
          _buildTab('Console', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final selected = _tabController.index == index;
    return InkWell(
      onTap: () => _tabController.animateTo(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: selected ? AppTheme.primaryGreen : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.primaryGreen : Colors.grey,
            fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLogs(String? output) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Log Controls
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                          // TODO: implement log file selection
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  // TODO: implement copy functionality
                },
                tooltip: 'Copy',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  // TODO: implement clear functionality
                },
                tooltip: 'Clear',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // TODO: implement refresh functionality
                },
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Console Output
          Expanded(
            child: ConsoleScreen(
              output: output,
              onSendCommand: (command) {
                final service = ref.read(serverProcessServiceProvider);
                service.sendCommand(widget.server.id, command);
              },
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
                    _buildLogs(
                      outputAsync.when(
                        data: (output) => output,
                        loading: () => null,
                        error: (_, __) => null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showSettings)
            _ServerSettingsDialog(
              server: widget.server,
              onClose: () => setState(() => _showSettings = false),
            ),
        ],
      ),
    );
  }
}

class _ServerSettingsDialog extends StatelessWidget {
  final MinecraftServer server;
  final VoidCallback onClose;

  const _ServerSettingsDialog({
    required this.server,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent tap from closing dialog
            child: Container(
              width: 600,
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.dns),
                        const SizedBox(width: 8),
                        Text(
                          '${server.name} > Settings',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: onClose,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Settings Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SettingsSection(
                              title: 'General',
                              children: [
                                _SettingsField(
                                  label: 'Name',
                                  value: server.name,
                                ),
                                _SettingsField(
                                  label: 'Server Type',
                                  value: server.type.displayName,
                                ),
                                _SettingsField(
                                  label: 'Version',
                                  value: server.version,
                                ),
                              ],
                            ),
                            _SettingsSection(
                              title: 'Installation',
                              children: [
                                _SettingsField(
                                  label: 'Path',
                                  value: server.path,
                                  subtitle: 'Location where server files are stored',
                                ),
                                _SettingsField(
                                  label: 'Java Path',
                                  value: server.javaPath,
                                  subtitle: 'Java executable used to run the server',
                                ),
                              ],
                            ),
                            _SettingsSection(
                              title: 'Server Configuration',
                              children: [
                                _SettingsField(
                                  label: 'Port',
                                  value: server.port.toString(),
                                ),
                                _SettingsField(
                                  label: 'Memory',
                                  value: '${server.memory}MB',
                                ),
                                _SettingsField(
                                  label: 'Auto Start',
                                  value: server.autoStart ? 'Yes' : 'No',
                                ),
                              ],
                            ),
                            _SettingsSection(
                              title: 'Danger Zone',
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.delete_forever),
                                    label: const Text('Delete Server'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      // TODO: Implement delete functionality
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsField extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;

  const _SettingsField({
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}