import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/minecraft_server.dart';
import '../../../domain/entities/server_types.dart';
import '../../screens/server/server_detail_screen.dart';
import '../../providers/server/server_process_provider.dart';
import '../../../core/theme/app_theme.dart';

class ServerCard extends ConsumerWidget {
  final MinecraftServer server;

  const ServerCard({
    super.key,
    required this.server,
  });

  Color _getStatusColor(ServerStatus status) {
    switch (status) {
      case ServerStatus.running:
        return AppTheme.primaryGreen;
      case ServerStatus.stopped:
        return Colors.grey;
      case ServerStatus.error:
        return Colors.red;
      case ServerStatus.starting:
      case ServerStatus.stopping:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(serverStatusProvider(server.id));
    final service = ref.read(serverProcessServiceProvider);
    final status = statusAsync.valueOrNull ?? ServerStatus.stopped;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ServerDetailScreen(server: server),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          server.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                server.version,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                server.type.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action Buttons - Always show them
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          status == ServerStatus.running
                              ? Icons.stop
                              : Icons.play_arrow,
                          color: AppTheme.primaryGreen,
                        ),
                        onPressed: status == ServerStatus.running
                            ? () => service.stopServer(server.id)
                            : () => service.startServer(server),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Status indicator
              Row(
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
                    status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}