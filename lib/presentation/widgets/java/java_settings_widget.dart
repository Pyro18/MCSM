import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/java_installation.dart';
import '../../providers/java/java_provider.dart';
import '../../providers/settings/settings_provider.dart';

class JavaSettingsWidget extends ConsumerStatefulWidget {
  const JavaSettingsWidget({super.key});

  @override
  ConsumerState<JavaSettingsWidget> createState() => _JavaSettingsWidgetState();
}

class _JavaSettingsWidgetState extends ConsumerState<JavaSettingsWidget> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).autoDetectJava();
    });
  }

  @override
  Widget build(BuildContext context) {
    final installationsAsync = ref.watch(javaInstallationsProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con azioni
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Java Installations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                // Auto-detect button
                TextButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('Auto Detect'),
                  onPressed: () async {
                    try {
                      await ref
                          .read(settingsProvider.notifier)
                          .autoDetectJava();
                      ref.invalidate(javaInstallationsProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Java detected successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error detecting Java: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(width: 8),
                // Rescan button
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rescan'),
                  onPressed: () {
                    ref.invalidate(javaInstallationsProvider);
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Lista delle installazioni
        installationsAsync.when(
          data: (installations) => installations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No Java installations found'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          try {
                            await ref
                                .read(settingsProvider.notifier)
                                .autoDetectJava();
                            ref.invalidate(javaInstallationsProvider);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error detecting Java: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Try Auto Detect'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    ...installations.map((inst) => _JavaInstallationTile(
                          installation: inst,
                          isCurrentPath: settingsAsync.whenOrNull(
                                data: (settings) =>
                                    settings.javaPath == inst.path,
                              ) ??
                              false,
                        )),
                  ],
                ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error: $error'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(javaInstallationsProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Add manually button
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Java Installation'),
          onPressed: () => _addJavaInstallation(context, ref),
        ),
      ],
    );
  }
}

Future<void> _addJavaInstallation(BuildContext context, WidgetRef ref) async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe'],
      dialogTitle: 'Select Java Executable',
    );

    if (result != null) {
      final service = ref.read(javaServiceProvider);
      final installations = await service.detectJavaInstallations();
      final path = result.files.single.path!;

      if (!installations.any((inst) => inst.path == path)) {
        // Verifica che il file sia un eseguibile Java valido
        final version = await service.validateAndGetVersion(path);
        if (version != null) {
          final newInstallations = [
            ...installations,
            JavaInstallation(
              path: path,
              version: version,
              isDefault: installations.isEmpty,
            ),
          ];

          await service.saveJavaInstallations(newInstallations);
          ref.invalidate(javaInstallationsProvider);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Java installation added successfully'),
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
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This Java installation is already added'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding Java installation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _JavaInstallationTile extends ConsumerWidget {
  final JavaInstallation installation;
  final bool isCurrentPath;

  const _JavaInstallationTile({
    required this.installation,
    required this.isCurrentPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: Row(
          children: [
            Text('Java ${installation.version}'),
            if (isCurrentPath) ...[
              const SizedBox(width: 8),
              const Chip(
                label: Text('Current'),
                backgroundColor: Colors.green,
                labelStyle: TextStyle(color: Colors.white),
              ),
            ],
          ],
        ),
        subtitle: Text(installation.path),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (installation.isDefault)
              Chip(
                label: const Text('Default'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            else
              TextButton(
                child: const Text('Set as Default'),
                onPressed: () async {
                  try {
                    final service = ref.read(javaServiceProvider);
                    final installations = await service.loadJavaInstallations();

                    final updatedInstallations = installations.map((inst) {
                      return JavaInstallation(
                        path: inst.path,
                        version: inst.version,
                        isDefault: inst.path == installation.path,
                      );
                    }).toList();

                    await service.saveJavaInstallations(updatedInstallations);

                    // Update settings to use this Java path
                    final settings = await ref.read(settingsProvider.future);
                    await ref.read(settingsProvider.notifier).updateSettings(
                          settings.copyWith(javaPath: installation.path),
                        );

                    ref.invalidate(javaInstallationsProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Error setting default installation: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                try {
                  final service = ref.read(javaServiceProvider);
                  final installations = await service.loadJavaInstallations();

                  if (installations.length == 1) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Cannot remove the last Java installation'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                    return;
                  }

                  final updatedInstallations = installations
                      .where((inst) => inst.path != installation.path)
                      .toList();

                  await service.saveJavaInstallations(updatedInstallations);
                  ref.invalidate(javaInstallationsProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error removing installation: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
