import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/java_installation.dart';
import '../services/providers/java_provider.dart';

class JavaSettingsWidget extends ConsumerWidget {
  const JavaSettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installationsAsync = ref.watch(javaInstallationsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Rescan'),
              onPressed: () {
                ref.invalidate(javaInstallationsProvider);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        installationsAsync.when(
          data: (installations) => installations.isEmpty
              ? const Center(
                  child: Text('No Java installations found'),
                )
              : Column(
                  children: [
                    ...installations.map((inst) => _JavaInstallationTile(
                      installation: inst,
                    )),
                  ],
                ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        ),
        
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Java Installation'),
          onPressed: () => _addJavaInstallation(context, ref),
        ),
      ],
    );
  }
  
  Future<void> _addJavaInstallation(BuildContext context, WidgetRef ref) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe'],
      dialogTitle: 'Select Java Executable',
    );

    if (result != null) {
      final service = ref.read(javaServiceProvider);
      final installations = await service.detectJavaInstallations();
      final path = result.files.single.path!;
      
      // Validate the selected Java path
      if (!installations.any((inst) => inst.path == path)) {
        // If it's a new installation, add it
        final newInstallations = [
          ...installations,
          JavaInstallation(
            path: path,
            version: 'Custom Installation', // This will be updated by the service
          ),
        ];
        
        await service.saveJavaInstallations(newInstallations);
        ref.invalidate(javaInstallationsProvider);
      }
    }
  }
}

class _JavaInstallationTile extends ConsumerWidget {
  final JavaInstallation installation;

  const _JavaInstallationTile({
    required this.installation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: Text('Java ${installation.version}'),
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
                  final service = ref.read(javaServiceProvider);
                  final installations = await service.loadJavaInstallations();
                  
                  final updatedInstallations = installations.map((inst) {
                    if (inst.path == installation.path) {
                      return JavaInstallation(
                        path: inst.path,
                        version: inst.version,
                        isDefault: true,
                      );
                    }
                    return JavaInstallation(
                      path: inst.path,
                      version: inst.version,
                      isDefault: false,
                    );
                  }).toList();
                  
                  await service.saveJavaInstallations(updatedInstallations);
                  ref.invalidate(javaInstallationsProvider);
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final service = ref.read(javaServiceProvider);
                final installations = await service.loadJavaInstallations();
                
                final updatedInstallations = installations
                    .where((inst) => inst.path != installation.path)
                    .toList();
                
                await service.saveJavaInstallations(updatedInstallations);
                ref.invalidate(javaInstallationsProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}