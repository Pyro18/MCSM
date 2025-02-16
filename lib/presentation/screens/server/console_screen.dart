import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/server/console_provider.dart';

class ConsoleScreen extends ConsumerStatefulWidget {
  final String serverId;
  final String? output;
  final void Function(String) onSendCommand;
  final bool autoScroll;
  final String serverPath;

  const ConsoleScreen({
    super.key,
    required this.serverId,
    this.output,
    required this.onSendCommand,
    this.autoScroll = true,
    required this.serverPath,
  });

  @override
  ConsumerState<ConsoleScreen> createState() => _ConsoleScreenState();
}

class _ConsoleScreenState extends ConsumerState<ConsoleScreen> {
  final TextEditingController _commandController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _showScrollButton = false;
  bool _autoScroll = true;
  String _searchTerm = '';

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
      Future(() {
        if (mounted) {
          ref.read(consoleProvider(widget.serverId).notifier).addMessage(widget.output!);
          if (_autoScroll) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          }
        }
      });
    }
  }

  Future<List<FileSystemEntity>> _getLogFiles() async {
    final logDir = Directory('${widget.serverPath}/logs');
    if (!await logDir.exists()) {
      return [];
    }

    final files = await logDir.list().where((entity) =>
        entity.path.endsWith('.log')).toList();

    files.sort((a, b) {
      return b.statSync().modified.compareTo(a.statSync().modified);
    });

    return files;
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final atBottom = (maxScroll - currentScroll) <= 50.0;

    setState(() {
      _showScrollButton = !atBottom;
      if (atBottom) {
        _autoScroll = true;
      }
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
    final consoleNotifier = ref.read(consoleProvider(widget.serverId).notifier);
    consoleNotifier.addMessage('> $command');

    _commandController.clear();
    _scrollToBottom();
  }

  void _copyConsoleContent() {
    final consoleState = ref.read(consoleProvider(widget.serverId));
    final textToCopy = consoleState.messages.join('\n');

    Clipboard.setData(ClipboardData(text: textToCopy)).then((_) {
      ScaffoldMessenger.of(context).clearSnackBars();
      final snackBar = SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Console content copied to clipboard'),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: 20,
          right: 20,
          left: MediaQuery.of(context).size.width * 0.5,
        ),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  @override
  Widget build(BuildContext context) {
    final consoleState = ref.watch(consoleProvider(widget.serverId));

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: FutureBuilder<List<FileSystemEntity>>(
            future: _getLogFiles(),
            builder: (context, snapshot) {
              return Theme(
                data: Theme.of(context).copyWith(
                  iconTheme: IconThemeData(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                child: ExpansionTile(
                  key: GlobalKey(),
                  title: Text(consoleState.selectedLogLabel),
                  shape: const RoundedRectangleBorder(
                    side: BorderSide.none,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _copyConsoleContent,
                        tooltip: 'Copy to clipboard',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          ref.read(consoleProvider(widget.serverId).notifier).clearMessages();
                        },
                        tooltip: 'Clear',
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          if (consoleState.currentLogEntity != null) {
                            ref.read(consoleProvider(widget.serverId).notifier)
                                .loadLogFile(consoleState.currentLogEntity!);
                          }
                        },
                        tooltip: 'Refresh',
                      ),
                      const Icon(Icons.expand_more),
                    ],
                  ),
                  children: [
                    ListTile(
                      title: const Text('Live Console'),
                      selected: consoleState.currentLogFile.isEmpty,
                      onTap: () {
                        ref.read(consoleProvider(widget.serverId).notifier)
                            .switchToLiveConsole();
                        Future.delayed(const Duration(milliseconds: 100), () {
                          setState(() {});
                        });
                      },
                    ),
                    if (snapshot.hasData)
                      ...snapshot.data!.map((file) => ListTile(
                        title: Text(_getLogFileName(file)),
                        selected: consoleState.currentLogFile == file.path,
                        onTap: () {
                          ref.read(consoleProvider(widget.serverId).notifier)
                              .loadLogFile(file);
                          Future.delayed(const Duration(milliseconds: 100), () {
                            setState(() {});
                          });
                        },
                      )),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        TextField(
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
          ),
          onChanged: (value) => setState(() => _searchTerm = value),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: consoleState.messages.length,
                  itemBuilder: (context, index) {
                    final message = consoleState.messages[index];
                    if (!message.toLowerCase().contains(_searchTerm.toLowerCase())) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SelectableText(
                        message,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                if (_showScrollButton)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: () {
                        setState(() => _autoScroll = true);
                        _scrollToBottom();
                      },
                      tooltip: 'Scroll to bottom',
                      child: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (consoleState.currentLogFile.isEmpty) ...[
          const SizedBox(height: 8),
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
      ],
    );
  }

  String _getLogFileName(FileSystemEntity entity) {
    final path = entity.path;
    final name = path.split(Platform.pathSeparator).last;

    if (name == 'latest.log') {
      return name;
    }

    final date = File(path).statSync().modified;
    return '${name.split('.').first} - ${_formatDate(date)}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _commandController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

