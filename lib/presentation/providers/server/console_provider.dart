import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConsoleState {
  final List<String> messages;
  final List<String> liveMessages;
  final String currentLogFile;
  final FileSystemEntity? currentLogEntity;
  final String selectedLogLabel;

  ConsoleState({
    required this.messages,
    List<String>? liveMessages,
    this.currentLogFile = '',
    this.currentLogEntity,
    this.selectedLogLabel = 'Live Console',
  }) : liveMessages = liveMessages ?? [];

  ConsoleState copyWith({
    List<String>? messages,
    List<String>? liveMessages,
    String? currentLogFile,
    FileSystemEntity? currentLogEntity,
    String? selectedLogLabel,
  }) {
    return ConsoleState(
      messages: messages ?? this.messages,
      liveMessages: liveMessages ?? this.liveMessages,
      currentLogFile: currentLogFile ?? this.currentLogFile,
      currentLogEntity: currentLogEntity ?? this.currentLogEntity,
      selectedLogLabel: selectedLogLabel ?? this.selectedLogLabel,
    );
  }
}

class ConsoleNotifier extends StateNotifier<ConsoleState> {
  ConsoleNotifier() : super(ConsoleState(messages: []));

  void addMessage(String message) {
    if (state.currentLogFile.isEmpty) {
      state = state.copyWith(
        messages: [...state.messages, message],
        liveMessages: [...state.liveMessages, message],
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(messages: []);
  }

  Future<void> loadLogFile(FileSystemEntity logFile) async {
    try {
      state = state.copyWith(
        messages: [],
        currentLogFile: logFile.path,
        currentLogEntity: logFile,
        selectedLogLabel: _getLogFileName(logFile),
      );

      final file = File(logFile.path);
      if (await file.exists()) {
        final content = await file.readAsString();
        final messages = content
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
        state = state.copyWith(messages: messages);
      }
    } catch (e) {
      state = state.copyWith(
        messages: ['Error loading log file: $e'],
      );
    }
  }

  void switchToLiveConsole() {
    state = state.copyWith(
      messages: state.liveMessages,
      currentLogFile: '',
      currentLogEntity: null,
      selectedLogLabel: 'Live Console',
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
}

final consoleProvider = StateNotifierProvider.family<ConsoleNotifier, ConsoleState, String>(
      (ref, serverId) => ConsoleNotifier(),
);