import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LogType { info, warning, error, success, command }

class ConsoleMessage {
  final String text;
  final LogType type;
  final DateTime timestamp;
  int count;

  ConsoleMessage({
    required this.text,
    required this.type,
    required this.timestamp,
    this.count = 1,
  });

  String get formattedTime => '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}:'
      '${timestamp.second.toString().padLeft(2, '0')}';

  Color get color {
    switch (type) {
      case LogType.info:
        return Colors.white;
      case LogType.warning:
        return Colors.orange;
      case LogType.error:
        return Colors.red;
      case LogType.success:
        return Colors.green;
      case LogType.command:
        return Colors.cyan;
    }
  }

  factory ConsoleMessage.fromString(String text) {
    final now = DateTime.now();
    final lowerText = text.toLowerCase();

    LogType type;
    if (lowerText.contains('error') || lowerText.contains('exception')) {
      type = LogType.error;
    } else if (lowerText.contains('warn')) {
      type = LogType.warning;
    } else if (lowerText.contains('success') || lowerText.contains('done')) {
      type = LogType.success;
    } else {
      type = LogType.info;
    }

    return ConsoleMessage(
      text: text,
      type: type,
      timestamp: now,
    );
  }
}

class ConsoleScreen extends ConsumerStatefulWidget {
  final String? output;
  final void Function(String) onSendCommand;
  final bool autoScroll;

  const ConsoleScreen({
    super.key,
    this.output,
    required this.onSendCommand,
    this.autoScroll = true,
  });

  @override
  ConsumerState<ConsoleScreen> createState() => _ConsoleScreenState();
}

class _ConsoleScreenState extends ConsumerState<ConsoleScreen> {
  final TextEditingController _commandController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ConsoleMessage> _messages = [];

  bool _showScrollButton = false;
  bool _autoScroll = true;
  String _searchTerm = '';
  Set<LogType> _activeFilters = LogType.values.toSet();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _autoScroll = widget.autoScroll;
  }

  @override
  void didUpdateWidget(ConsoleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.output != null && widget.output != oldWidget.output) {
      _handleNewOutput(widget.output!);
      if (_autoScroll) {
        _scrollToBottom();
      }
    }
  }

  void _handleNewOutput(String output) {
    setState(() {
      if (_messages.isNotEmpty &&
          output == _messages.last.text &&
          DateTime.now().difference(_messages.last.timestamp).inSeconds <= 1) {
        _messages.last.count++;
      } else {
        _messages.add(ConsoleMessage.fromString(output));
      }

      // Se siamo in auto-scroll, programmiamo uno scroll al fondo
      if (_autoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });
  }

  @override
  void dispose() {
    _commandController.dispose();
    _searchController.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final atBottom = (maxScroll - currentScroll) <= 50.0;

    setState(() {
      _showScrollButton = !atBottom;
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _sendCommand() {
    final command = _commandController.text.trim();
    if (command.isEmpty) return;

    widget.onSendCommand(command);

    setState(() {
      if (_messages.isNotEmpty &&
          _messages.last.text == '> $command' &&
          DateTime.now().difference(_messages.last.timestamp).inSeconds <= 1) {
        _messages.last.count++;
      } else {
        _messages.add(ConsoleMessage(
          text: '> $command',
          type: LogType.command,
          timestamp: DateTime.now(),
        ));
      }
    });

    _commandController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _toggleFilter(LogType type) {
    setState(() {
      if (_activeFilters.contains(type)) {
        _activeFilters.remove(type);
      } else {
        _activeFilters.add(type);
      }
    });
  }

  List<ConsoleMessage> _getFilteredMessages() {
    return _messages.where((msg) {
      final matchesSearch =
          msg.text.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesFilter = _activeFilters.contains(msg.type);
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredMessages = _getFilteredMessages();

    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollToBottom();
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with search and filters
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
            // Search Box
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search logs...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchTerm.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchTerm = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) => setState(() => _searchTerm = value),
              ),
            ),
            const SizedBox(width: 16),
            // Filter Chips
            for (final type in LogType.values)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(type.name.toUpperCase()),
                  selected: _activeFilters.contains(type),
                  onSelected: (_) => _toggleFilter(type),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),

        // Console output
        Expanded(
          child: Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is UserScrollNotification) {
                    setState(() {
                      _autoScroll = false;
                    });
                  }
                  return false;
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: RawScrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    thickness: 8,
                    radius: const Radius.circular(4),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredMessages.length,
                      itemBuilder: (context, index) {
                        final message = filteredMessages[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.formattedTime,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: message.text,
                                        style: TextStyle(
                                          color: message.color,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      if (message.count > 1)
                                        TextSpan(
                                          text: ' (×${message.count})',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
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
              ),
              if (_showScrollButton)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      setState(() {
                        _autoScroll = true;
                      });
                      _scrollToBottom();
                    },
                    tooltip: 'Scroll to bottom',
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ),
            ],
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
    );
  }
}
