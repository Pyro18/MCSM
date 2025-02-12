import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/server_types.dart';

class ServerActionDialog extends ConsumerWidget {
  final String serverName;
  final ServerStatus targetStatus;

  const ServerActionDialog({
    super.key,
    required this.serverName,
    required this.targetStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              targetStatus == ServerStatus.running
                  ? 'Starting ${serverName}...'
                  : 'Stopping ${serverName}...',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              targetStatus == ServerStatus.running
                  ? 'Please wait while the server starts up'
                  : 'Please wait while the server shuts down safely',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}