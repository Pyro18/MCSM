import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/server_types.dart';
import '../models/minecraft_server.dart';
import '../screens/server_detail_screen.dart';
import '../services/providers/server_process_provider.dart';
import 'server_action_dialog.dart';

class ServerCard extends ConsumerWidget {
  final MinecraftServer server;

  const ServerCard({
    super.key,
    required this.server,
  });

  Color _getStatusColor(ServerStatus status) {
    switch (status) {
      case ServerStatus.running:
        return Colors.green;
      case ServerStatus.stopped:
        return Colors.grey;
      case ServerStatus.error:
        return Colors.red;
      case ServerStatus.starting:
      case ServerStatus.stopping:
        return Colors.orange;
    }
  }

  Future<void> _handleStartServer(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ServerActionDialog(
        serverName: server.name,
        targetStatus: ServerStatus.running,
      ),
    );

    try {
      final service = ref.read(serverProcessServiceProvider);
      await service.startServer(server);

      // Attendiamo un paio di secondi per dare tempo al server di iniziare
      await Future.delayed(const Duration(seconds: 3));

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting server: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop(); // Chiude il dialog
      }
    }
  }

  Future<void> _handleStopServer(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ServerActionDialog(
        serverName: server.name,
        targetStatus: ServerStatus.stopped,
      ),
    );

    try {
      final service = ref.read(serverProcessServiceProvider);
      await service.stopServer(server.id);

      // Aspettiamo qualche secondo per dare tempo al server di fermarsi
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping server: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop(); // Chiude il dialog
      }
    }
  }

  String _getStatusText(ServerStatus status) {
    return status.displayName;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Inizializziamo subito il service per questo server
    final service = ref.read(serverProcessServiceProvider);
    service.initializeServerStatus(server.id);

    // Ora osserviamo lo stato
    final statusAsync = ref.watch(serverStatusProvider(server.id));

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ServerDetailScreen(
                server: server,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      server.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      // Mostriamo subito i pulsanti con lo stato corretto
                      statusAsync.when(
                        data: (status) => Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.play_arrow),
                              onPressed: status == ServerStatus.stopped
                                  ? () => _handleStartServer(context, ref)
                                  : null,
                              tooltip: 'Start Server',
                            ),
                            IconButton(
                              icon: const Icon(Icons.stop),
                              onPressed: status == ServerStatus.running
                                  ? () => _handleStopServer(context, ref)
                                  : null,
                              tooltip: 'Stop Server',
                            ),
                          ],
                        ),
                        loading: () => const Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.play_arrow),
                              onPressed: null,
                            ),
                            IconButton(
                              icon: Icon(Icons.stop),
                              onPressed: null,
                            ),
                          ],
                        ),
                        error: (_, __) => const Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.play_arrow),
                              onPressed: null,
                            ),
                            IconButton(
                              icon: Icon(Icons.stop),
                              onPressed: null,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () {},
                        tooltip: 'Settings',
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              _InfoRow(
                label: 'Version',
                value: server.version,
              ),
              const SizedBox(height: 4),
              _InfoRow(
                label: 'Port',
                value: server.port.toString(),
              ),
              const SizedBox(height: 4),
              statusAsync.when(
                data: (status) => Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getStatusText(status),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                loading: () => const Text('Loading...'),
                error: (_, __) => const Text(
                  'Error',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        Text(value),
      ],
    );
  }
}