import 'package:flutter/material.dart';
import '../models/server_types.dart';
import '../models/minecraft_server.dart';
import '../screens/server_detail_screen.dart';

class ServerCard extends StatelessWidget {
  final MinecraftServer server;

  const ServerCard({
    super.key,
    required this.server,
  });

  Color _getStatusColor() {
    switch (server.status) {
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

  String _getStatusText() {
    return server.status.displayName;
  }

  @override
  Widget build(BuildContext context) {
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
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed:
                        server.status == ServerStatus.stopped ? () {} : null,
                        tooltip: 'Start Server',
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop),
                        onPressed:
                        server.status == ServerStatus.running ? () {} : null,
                        tooltip: 'Stop Server',
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
              // Server info
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
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w500,
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

// TODO: Console view widget to be implemented
class ConsoleView extends StatelessWidget {
  const ConsoleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                'Server console output will appear here...',
                style: TextStyle(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter command...',
                    prefixText: '> ',
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: null,
                child: Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}