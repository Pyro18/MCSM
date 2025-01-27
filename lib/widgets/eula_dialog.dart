// eula_dialog.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class EulaDialog extends ConsumerStatefulWidget {
  final String serverPath;
  final VoidCallback? onAccept;

  const EulaDialog({
    super.key,
    required this.serverPath,
    this.onAccept,
  });

  @override
  ConsumerState<EulaDialog> createState() => _EulaDialogState();
}

class _EulaDialogState extends ConsumerState<EulaDialog> {
  bool _isAccepting = false;

  Future<void> _acceptEula() async {
    setState(() => _isAccepting = true);

    try {
      final eulaFile = File('${widget.serverPath}/eula.txt');
      if (await eulaFile.exists()) {
        final content = await eulaFile.readAsString();
        final updatedContent = content.replaceAll('eula=false', 'eula=true');
        await eulaFile.writeAsString(updatedContent);

        if (mounted) {
          Navigator.of(context).pop(true);
          widget.onAccept?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting EULA: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }

  Future<void> _openEulaWebsite() async {
    const url = 'https://account.mojang.com/documents/minecraft_eula';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Minecraft EULA Acceptance Required'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Before starting the server, you need to accept the Minecraft End User License Agreement (EULA).',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('You can read the EULA at: '),
              InkWell(
                onTap: _openEulaWebsite,
                child: Text(
                  'Minecraft EULA',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isAccepting ? null : _acceptEula,
          child: _isAccepting
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Accept EULA'),
        ),
      ],
    );
  }
}