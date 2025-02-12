import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../../domain/entities/minecraft_server.dart';
import '../../../core/theme/app_theme.dart';

class ServerSettingsDialog extends StatefulWidget {
  final MinecraftServer server;
  final VoidCallback onClose;

  const ServerSettingsDialog({
    super.key,
    required this.server,
    required this.onClose,
  });

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  String _selectedSection = 'General';

  final List<Map<String, dynamic>> _sections = [
    {
      'id': 'General',
      'icon': Icons.settings,
      'color': Colors.green,
    },
    {
      'id': 'Installation',
      'icon': Icons.folder_outlined,
      'color': Colors.blue,
    },
    //{
    //  'id': 'Window',
    //  'icon': Icons.window_outlined,
    //  'color': Colors.orange,
    //},
    {
      'id': 'Java and memory',
      'icon': Icons.memory_outlined,
      'color': Colors.purple,
    },
    //{
    //  'id': 'Launch hooks',
    //  'icon': Icons.terminal_outlined,
    //  'color': Colors.red,
    //},
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blurred background
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ),
        // Dialog content
        GestureDetector(
          onTap: widget.onClose,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(32),
            child: Center(
              child: GestureDetector(
                onTap: () {}, // Prevent tap from closing dialog
                child: Container(
                  width: 900,
                  height: 600,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1C1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Left sidebar with sections
                      Container(
                        width: 200,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.grey.withOpacity(0.1),
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with title and close button
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.dns,
                                        color: AppTheme.primaryGreen),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Settings',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            // Sections list
                            Expanded(
                              child: ListView(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                children: _sections.map((section) {
                                  final bool isSelected =
                                      _selectedSection == section['id'];
                                  return InkWell(
                                    onTap: () => setState(
                                        () => _selectedSection = section['id']),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? section['color'].withOpacity(0.1)
                                            : Colors.transparent,
                                        border: isSelected
                                            ? Border(
                                                left: BorderSide(
                                                  color: section['color'],
                                                  width: 3,
                                                ),
                                              )
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            section['icon'],
                                            size: 20,
                                            color: isSelected
                                                ? section['color']
                                                : Colors.grey,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            section['id'],
                                            style: TextStyle(
                                              color: isSelected
                                                  ? section['color']
                                                  : Colors.grey,
                                              fontWeight: isSelected
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right content area
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top bar with instance name and actions
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.withOpacity(0.1),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      /*image: const DecorationImage(
                                        image: AssetImage('assets/server_icon.png'),
                                        fit: BoxFit.cover,
                                      ),*/
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    widget.server.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: widget.onClose,
                                  ),
                                ],
                              ),
                            ),
                            // Content based on selected section
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: _buildSectionContent(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case 'General':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingField(
              'Name',
              widget.server.name,
              const Icon(Icons.edit, size: 20),
            ),
            const SizedBox(height: 24),
            _buildDuplicateSection(),
            const SizedBox(height: 24),
            _buildLibraryGroupsSection(),
            const SizedBox(height: 24),
            _buildDangerZone(),
          ],
        );
      case 'Installation':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPathSection(),
            const SizedBox(height: 24),
            _buildJavaPathSection(),
          ],
        );
      default:
        return const Center(
          child: Text('Coming soon...'),
        );
    }
  }

  Widget _buildPathSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Server Location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The location where your server files are stored.',
          style: TextStyle(
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.server.path,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Open Folder'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () async {
                      try {
                        if (Platform.isWindows) {
                          await Process.run('explorer', [widget.server.path]);
                        } else if (Platform.isMacOS) {
                          await Process.run('open', [widget.server.path]);
                        } else if (Platform.isLinux) {
                          await Process.run('xdg-open', [widget.server.path]);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error opening folder: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              if (Directory(widget.server.path).existsSync()) ...[
                const SizedBox(height: 8),
                FutureBuilder<int>(
                  future: _calculateFolderSize(widget.server.path),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final sizeInMB = snapshot.data! / (1024 * 1024);
                      return Text(
                        'Size: ${sizeInMB.toStringAsFixed(1)} MB',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<int> _calculateFolderSize(String path) async {
    int totalSize = 0;
    try {
      final dir = Directory(path);
      await for (final file in dir.list(recursive: true)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
    } catch (e) {
      print('Error calculating folder size: $e');
    }
    return totalSize;
  }

  Widget _buildJavaPathSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Java Installation',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The Java executable used to run this server.',
          style: TextStyle(
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.server.javaPath,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Open Folder'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () async {
                      try {
                        final javaDir =
                            Directory(path.dirname(widget.server.javaPath));
                        if (Platform.isWindows) {
                          await Process.run('explorer', [javaDir.path]);
                        } else if (Platform.isMacOS) {
                          await Process.run('open', [javaDir.path]);
                        } else if (Platform.isLinux) {
                          await Process.run('xdg-open', [javaDir.path]);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error opening folder: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingField(String label, String value, Widget? action) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: value),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (action != null) action,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDuplicateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duplicate instance',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Creates a copy of this instance, including worlds, configs, mods, etc.',
          style: TextStyle(
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('Duplicate'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            // TODO: Implements duplication logic
          },
        ),
      ],
    );
  }

  Widget _buildLibraryGroupsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Library groups',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Library groups allow you to organize your servers into different sections.',
          style: TextStyle(
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Enter group name',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create new group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                // TODO: idk what to do here
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delete instance',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Permanently deletes the server from your device, including your worlds, configs, and all installed content. Be careful, as once you delete a server there is no way to recover it.',
          style: TextStyle(
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.delete_forever),
          label: const Text('Delete Server'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            // TODO: Implement deletion logic
          },
        ),
      ],
    );
  }
}
