import 'package:flutter/material.dart';

enum ServerStatus {
  running,
  stopped,
  error
}

class ServerCard extends StatelessWidget {
  final String name;
  final String version;
  final int port;
  final ServerStatus status;

  const ServerCard({
    super.key,
    required this.name,
    required this.version,
    required this.port,
    required this.status,
  });

  Color _getStatusColor() {
    switch (status) {
      case ServerStatus.running:
        return Colors.green;
      case ServerStatus.stopped:
        return Colors.grey;
      case ServerStatus.error:
        return Colors.red;
    }
  }

  String _getStatusText() {
    switch (status) {
      case ServerStatus.running:
        return 'Running';
      case ServerStatus.stopped:
        return 'Stopped';
      case ServerStatus.error:
        return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          if (status == ServerStatus.running) {
            // Open console in a dialog when server is running
            showDialog(
              context: context,
              builder: (context) => Dialog(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.8,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$name - Console',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Expanded(child: ConsoleView()),
                    ],
                  ),
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
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
                        onPressed: status == ServerStatus.stopped ? () {} : null,
                        tooltip: 'Start Server',
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop),
                        onPressed: status == ServerStatus.running ? () {} : null,
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
                value: version,
              ),
              const SizedBox(height: 4),
              _InfoRow(
                label: 'Port',
                value: port.toString(),
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

// Console view widget to be implemented
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