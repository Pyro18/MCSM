import 'package:flutter/material.dart';

class ConsoleScreen extends StatefulWidget {
  const ConsoleScreen({super.key});

  @override
  State<ConsoleScreen> createState() => _ConsoleScreenState();
}

class _ConsoleScreenState extends State<ConsoleScreen> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ConsoleMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // Add some example messages
    _messages.addAll([
      ConsoleMessage(
        text: '[Server] Starting Minecraft server version 1.20.1',
        type: MessageType.info,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      ConsoleMessage(
        text: '[Server] Loading properties',
        type: MessageType.info,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
      ConsoleMessage(
        text: '[Warning] Failed to load eula.txt',
        type: MessageType.warning,
        timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
      ),
      ConsoleMessage(
        text: '[Error] Could not bind to port 25565',
        type: MessageType.error,
        timestamp: DateTime.now(),
      ),
    ]);
  }

  void _sendCommand() {
    if (_commandController.text.isEmpty) return;

    setState(() {
      _messages.add(ConsoleMessage(
        text: '> ${_commandController.text}',
        type: MessageType.command,
        timestamp: DateTime.now(),
      ));
    });

    // TODO: Process command

    _commandController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with server selector
          Row(
            children: [
              const Text(
                'Console',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: 'survival',
                items: const [
                  DropdownMenuItem(
                    value: 'survival',
                    child: Text('Survival Server'),
                  ),
                ],
                onChanged: (value) {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Console output
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.formattedTime,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color: message.color,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Command input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commandController,
                  decoration: const InputDecoration(
                    hintText: 'Enter command...',
                    prefixText: '> ',
                  ),
                  onSubmitted: (_) => _sendCommand(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _sendCommand,
                child: const Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum MessageType { info, warning, error, command }

class ConsoleMessage {
  final String text;
  final MessageType type;
  final DateTime timestamp;

  ConsoleMessage({
    required this.text,
    required this.type,
    required this.timestamp,
  });

  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

  Color get color {
    switch (type) {
      case MessageType.info:
        return Colors.white;
      case MessageType.warning:
        return Colors.yellow;
      case MessageType.error:
        return Colors.red;
      case MessageType.command:
        return Colors.green;
    }
  }
}