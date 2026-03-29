import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../db/database_helper.dart';
import '../l10n/app_localizations.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  Future<void> _export(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    try {
      final file = await DatabaseHelper.instance.exportToFile();
      // Share the file
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          title: loc.exportShareTitle,
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.exportSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  Future<void> _import(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.first.path;
      if (filePath == null) return;

      final file = File(filePath);
      final count = await DatabaseHelper.instance.importFromFile(file);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.importSuccess(count))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.importError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.backup),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.cloud_download_outlined,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              loc.backup,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _export(context),
              icon: const Icon(Icons.upload),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(loc.exportData,
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _import(context),
              icon: const Icon(Icons.download),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(loc.importData,
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
