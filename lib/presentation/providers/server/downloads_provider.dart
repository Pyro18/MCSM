import 'package:flutter_riverpod/flutter_riverpod.dart';

class DownloadState {
  final String id;
  final String name;
  final String version;
  final double progress;
  final String status;
  final bool isCompleted;
  final String? error;

  DownloadState({
    required this.id,
    required this.name,
    required this.version,
    this.progress = 0,
    this.status = 'Starting...',
    this.isCompleted = false,
    this.error,
  });

  DownloadState copyWith({
    double? progress,
    String? status,
    bool? isCompleted,
    String? error,
  }) {
    return DownloadState(
      id: id,
      name: name,
      version: version,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error ?? this.error,
    );
  }
}

class DownloadsNotifier extends StateNotifier<Map<String, DownloadState>> {
  DownloadsNotifier() : super({});

  void addDownload(String id, String name, String version) {
    final newState = Map<String, DownloadState>.from(state);
    newState[id] = DownloadState(
      id: id,
      name: name,
      version: version,
    );
    state = newState;
  }

  void updateProgress(String id, double progress, [String? status]) {
    if (!state.containsKey(id)) return;

    final newState = Map<String, DownloadState>.from(state);
    newState[id] = state[id]!.copyWith(
      progress: progress,
      status: status,
    );
    state = newState;
  }

  void completeDownload(String id) {
    if (!state.containsKey(id)) return;

    final newState = Map<String, DownloadState>.from(state);
    newState[id] = state[id]!.copyWith(
      progress: 1.0,
      status: 'Completed',
      isCompleted: true,
    );
    state = newState;
  }

  void setError(String id, String error) {
    if (!state.containsKey(id)) return;

    final newState = Map<String, DownloadState>.from(state);
    newState[id] = state[id]!.copyWith(
      status: 'Error: $error',
      error: error,
    );
    state = newState;
  }

  void removeDownload(String id) {
    final newState = Map<String, DownloadState>.from(state);
    newState.remove(id);
    state = newState;
  }
}

final downloadsProvider =
    StateNotifierProvider<DownloadsNotifier, Map<String, DownloadState>>(
  (ref) => DownloadsNotifier(),
);
