import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/settings.dart';
import '../../providers/settings/settings_provider.dart';
import '../../providers/java/java_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {

  Future<void> _selectJavaPath(
      BuildContext context,
      WidgetRef ref,
      Settings currentSettings,
      ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Java Executable',
        type: FileType.custom,
        allowedExtensions: ['exe'],
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path!;
        final javaRepo = ref.read(javaRepositoryProvider);
        final installation = await javaRepo.selectAndValidateJavaPath(path);

        if (installation != null) {
          final newSettings = currentSettings.copyWith(javaPath: installation.path);
          await ref.read(settingsProvider.notifier).updateSettings(newSettings);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Java path updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid Java executable'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting Java: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDirectory(
    BuildContext context,
    WidgetRef ref,
    Settings currentSettings,
    String title,
    void Function(String) onSelected,
  ) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: title,
    );

    if (result != null) {
      onSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: settingsAsync.when(
        data: (settings) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Java Settings
                    const Text(
                      'Java Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Java Path',
                          ),
                          readOnly: true,
                          controller: TextEditingController(
                            text: settingsAsync.when(
                              data: (settings) => settings.javaPath,
                              loading: () => 'Loading...',
                              error: (_, __) => 'Error loading Java path',
                            ),
                          ),
                        )),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () =>
                              _selectJavaPath(context, ref, settings),
                          icon: const Icon(Icons.folder_open),
                          tooltip: 'Select Java Path',
                        ),
                        IconButton(
                          onPressed: () async {
                            await ref
                                .read(settingsProvider.notifier)
                                .autoDetectJava();
                          },
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Auto Detect Java',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Server Settings
                    const Text(
                      'Server Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Default Server Location',
                            ),
                            readOnly: true,
                            controller: TextEditingController(
                                text: settings.serverPath),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _selectDirectory(
                            context,
                            ref,
                            settings,
                            'Select Server Location',
                            (path) async {
                              final newSettings =
                                  settings.copyWith(serverPath: path);
                              await ref
                                  .read(settingsProvider.notifier)
                                  .updateSettings(newSettings);
                            },
                          ),
                          icon: const Icon(Icons.folder_open),
                          tooltip: 'Select Server Path',
                        ),
                        IconButton(
                          onPressed: () async {
                            final newSettings = settings.copyWith(
                              serverPath: Settings.defaultServerPath,
                            );
                            await ref
                                .read(settingsProvider.notifier)
                                .updateSettings(newSettings);
                          },
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Reset to Default',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Application Settings
                    const Text(
                      'Application Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Start Minimized'),
                      subtitle: const Text(
                          'Start the application minimized to system tray'),
                      value: settings.startMinimized,
                      onChanged: (value) async {
                        final newSettings =
                            settings.copyWith(startMinimized: value);
                        await ref
                            .read(settingsProvider.notifier)
                            .updateSettings(newSettings);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Close to Tray'),
                      subtitle: const Text(
                          'Minimize to system tray when closing the window'),
                      value: settings.closeToTray,
                      onChanged: (value) async {
                        final newSettings =
                            settings.copyWith(closeToTray: value);
                        await ref
                            .read(settingsProvider.notifier)
                            .updateSettings(newSettings);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Automatic Updates'),
                      subtitle: const Text(
                          'Automatically check for application updates'),
                      value: settings.autoUpdate,
                      onChanged: (value) async {
                        final newSettings =
                            settings.copyWith(autoUpdate: value);
                        await ref
                            .read(settingsProvider.notifier)
                            .updateSettings(newSettings);
                      },
                    ),
                    const SizedBox(height: 32),

                    // Backup Settings
                    const Text(
                      'Backup Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Backup Location',
                            ),
                            readOnly: true,
                            controller: TextEditingController(
                              text: settings.backupSettings.backupPath,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _selectDirectory(
                            context,
                            ref,
                            settings,
                            'Select Backup Location',
                            (path) async {
                              final newBackupSettings = settings.backupSettings
                                  .copyWith(backupPath: path);
                              final newSettings = settings.copyWith(
                                backupSettings: newBackupSettings,
                              );
                              await ref
                                  .read(settingsProvider.notifier)
                                  .updateSettings(newSettings);
                            },
                          ),
                          icon: const Icon(Icons.folder_open),
                          tooltip: 'Select Backup Path',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Automatic Backups'),
                      subtitle: const Text('Enable automatic server backups'),
                      value: settings.backupSettings.autoBackup,
                      onChanged: (value) async {
                        final newBackupSettings =
                            settings.backupSettings.copyWith(autoBackup: value);
                        final newSettings = settings.copyWith(
                          backupSettings: newBackupSettings,
                        );
                        await ref
                            .read(settingsProvider.notifier)
                            .updateSettings(newSettings);
                      },
                    ),
                    if (settings.backupSettings.autoBackup) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Backup Frequency',
                                suffixText: 'hours',
                              ),
                              keyboardType: TextInputType.number,
                              initialValue:
                                  settings.backupSettings.frequency.toString(),
                              onChanged: (value) async {
                                final frequency = int.tryParse(value);
                                if (frequency != null) {
                                  final newBackupSettings = settings
                                      .backupSettings
                                      .copyWith(frequency: frequency);
                                  final newSettings = settings.copyWith(
                                    backupSettings: newBackupSettings,
                                  );
                                  await ref
                                      .read(settingsProvider.notifier)
                                      .updateSettings(newSettings);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Maximum Backups',
                                suffixText: 'backups',
                              ),
                              keyboardType: TextInputType.number,
                              initialValue:
                                  settings.backupSettings.maxBackups.toString(),
                              onChanged: (value) async {
                                final maxBackups = int.tryParse(value);
                                if (maxBackups != null) {
                                  final newBackupSettings = settings
                                      .backupSettings
                                      .copyWith(maxBackups: maxBackups);
                                  final newSettings = settings.copyWith(
                                    backupSettings: newBackupSettings,
                                  );
                                  await ref
                                      .read(settingsProvider.notifier)
                                      .updateSettings(newSettings);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading settings: $error',
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(settingsProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
