import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/providers/downloads_provider.dart';

class DownloadProgressOverlay extends ConsumerWidget {
  final String downloadId;

  const DownloadProgressOverlay({super.key, required this.downloadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadsProvider);
    final download = downloads[downloadId];

    if (download == null || download.isCompleted) {
      return const SizedBox.shrink();
    }

    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Downloading ${download.name}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version: ${download.version}',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: download.progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                  download.error != null
                      ? Colors.red
                      : Theme.of(context).primaryColor
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            Text(
              download.error ?? download.status,
              style: TextStyle(
                color: download.error != null ? Colors.red : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}