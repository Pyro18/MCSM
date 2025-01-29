import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart' show navigatorKey;
import '../models/server_types.dart';
import '../services/providers/downloads_provider.dart';
import '../services/providers/minecraft_provider.dart';
import '../services/providers/servers_provider.dart';
import '../services/providers/settings_provider.dart';
import 'confetti_overlay.dart';
import 'download_progress_overlay.dart';

class CreateServerDialog extends ConsumerStatefulWidget {
  const CreateServerDialog({super.key});

  @override
  ConsumerState<CreateServerDialog> createState() => _CreateServerDialogState();
}

class _CreateServerDialogState extends ConsumerState<CreateServerDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String? _version;
  int _port = 25565;
  int _memory = 2048;
  String _path = '';
  bool _autoStart = false;
  bool _isLoading = false;
  ServerType _serverType = ServerType.paper;
  late String downloadId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settingsAsync = ref.read(settingsProvider);
    settingsAsync.whenData((settings) {
      setState(() {
        _path = settings.serverPath;
      });
    });
  }

  Future<void> _selectPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Server Directory',
    );

    if (selectedDirectory != null) {
      setState(() {
        _path = selectedDirectory;
      });
    }
  }

  Future<void> _createServer() async {
    if (!_formKey.currentState!.validate() || _version == null) return;

    setState(() => _isLoading = true);
    downloadId = '${_name}_${DateTime
        .now()
        .millisecondsSinceEpoch}';

    final downloadsNotifier = ref.read(downloadsProvider.notifier);
    downloadsNotifier.addDownload(downloadId, _name, _version!);

    try {
      final service = ref.read(minecraftServiceProvider);
      final settingsData = await ref.read(settingsProvider.future);

      void onProgress(double progress) {
        downloadsNotifier.updateProgress(
          downloadId,
          progress,
          'Downloading... ${(progress * 100).toInt()}%',
        );
      }

      final serverPath = await service.downloadServer(
        _version!,
        _serverType,
        _path,
        _name,
        onProgress,
      );

      print('Server downloaded to: $serverPath');
      downloadsNotifier.completeDownload(downloadId);

      print('Adding server to provider...');
      await ref.read(serversProvider.notifier).addServer(
        _name,
        _version!,
        _serverType,
        serverPath,
        _port,
        _memory,
        _autoStart,
        settingsData.javaPath,
      );
      print('Server added to provider successfully');

      if (mounted) {
        Navigator.of(context).pop();
        if (navigatorKey.currentContext != null) {
          showConfetti(navigatorKey.currentContext!);
        }
      }
    } catch (e, stack) {
      print('Error creating server: $e');
      print('Stack trace: $stack');
      downloadsNotifier.setError(downloadId, e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating server: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final versionsAsync = ref.watch(availableVersionsProvider(_serverType));
    ref.watch(settingsProvider).whenData((settings) {
      if (_path == settings.serverPath || _path.isEmpty) {
        _path = settings.serverPath;
      }
    });

    // Se stiamo scaricando, mostra il dialog di progresso
    if (_isLoading && downloadId.isNotEmpty) {
      return DownloadProgressOverlay(downloadId: downloadId);
    }

    // Altrimenti mostra il form di creazione
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create New Server',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Server Type
              SegmentedButton<ServerType>(
                segments: const [
                  ButtonSegment(
                    value: ServerType.paper,
                    label: Text('Paper'),
                    icon: Icon(Icons.rocket_launch),
                  ),
                  ButtonSegment(
                    value: ServerType.vanilla,
                    label: Text('Vanilla'),
                    icon: Icon(Icons.layers),
                  ),
                ],
                selected: {_serverType},
                onSelectionChanged: (Set<ServerType> selected) {
                  setState(() {
                    _serverType = selected.first;
                    _version = null; // Reset version when type changes
                  });
                },
              ),
              const SizedBox(height: 16),

              // Server Name
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Server Name',
                  hintText: 'My Awesome Server',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a server name';
                  }
                  return null;
                },
                onChanged: (value) => _name = value,
              ),
              const SizedBox(height: 16),

              // Version
              versionsAsync.when(
                data: (versions) => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Version',
                  ),
                  value: _version,
                  items: versions
                      .map((v) => DropdownMenuItem<String>(
                    value: v.id,
                    child: Text(v.id),
                  ))
                      .toList(),
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a version';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _version = value);
                    }
                  },
                ),
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Error loading versions: $error'),
              ),
              const SizedBox(height: 16),

              // Server Path
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Installation Path',
                      ),
                      readOnly: true,
                      controller: TextEditingController(text: _path),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an installation path';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _selectPath,
                    icon: const Icon(Icons.folder_open),
                    tooltip: 'Select Path',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Port
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '25565',
                ),
                initialValue: _port.toString(),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a port number';
                  }
                  final port = int.tryParse(value);
                  if (port == null || port < 1024 || port > 65535) {
                    return 'Port must be between 1024 and 65535';
                  }
                  return null;
                },
                onChanged: (value) {
                  _port = int.tryParse(value) ?? 25565;
                },
              ),
              const SizedBox(height: 16),

              // Memory
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Memory (MB)',
                  hintText: '2048',
                  suffixText: 'MB',
                ),
                initialValue: _memory.toString(),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter memory amount';
                  }
                  final memory = int.tryParse(value);
                  if (memory == null || memory < 512) {
                    return 'Memory must be at least 512 MB';
                  }
                  return null;
                },
                onChanged: (value) {
                  _memory = int.tryParse(value) ?? 2048;
                },
              ),
              const SizedBox(height: 16),

              // Auto Start
              SwitchListTile(
                title: const Text('Auto-start with application'),
                value: _autoStart,
                onChanged: (value) {
                  setState(() => _autoStart = value);
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                    _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createServer,
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Create Server'),
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
