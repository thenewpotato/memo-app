import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../db/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../services/downloads.dart';
import '../services/updater.dart';
import '../widgets/update_dialog.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  Future<void> _export(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    try {
      final json = await DatabaseHelper.instance.exportToJson();
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-');
      final filename = 'diary_backup_$timestamp.json';

      // Primary: write to public Downloads so the file survives uninstall.
      final downloadsLoc =
          await Downloads.saveTextSafe(filename: filename, content: json);

      // Also stage a copy in app docs for the share sheet.
      final shareFile = await DatabaseHelper.instance.exportToFile();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(shareFile.path)],
          title: loc.exportShareTitle,
        ),
      );

      if (context.mounted) {
        final msg = downloadsLoc != null
            ? loc.exportSavedToDownloads
            : loc.exportSuccess;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
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

  Future<void> _checkForUpdate(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(loc.checkingForUpdates),
        duration: const Duration(seconds: 2),
      ),
    );
    final info = await UpdateService.checkForUpdate(force: true);
    if (!context.mounted) return;
    if (info == null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(loc.upToDate)));
      return;
    }
    await showUpdateDownloadDialog(context, info);
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

      final jsonStr = await File(filePath).readAsString();
      final preview =
          await DatabaseHelper.instance.previewImport(jsonStr);

      if (!context.mounted) return;
      final confirmed = await _confirmImport(context, preview);
      if (confirmed != true) return;

      final count =
          await DatabaseHelper.instance.importFromJson(jsonStr);
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

  Future<bool?> _confirmImport(
    BuildContext context,
    ({int toAdd, int toOverwrite, List<String> overwriteDates}) preview,
  ) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sample = preview.overwriteDates.take(5).join(', ');
    final moreCount =
        preview.overwriteDates.length - 5;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.importConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.importConfirmAdd(preview.toAdd)),
            const SizedBox(height: 8),
            Text(
              loc.importConfirmOverwrite(preview.toOverwrite),
              style: preview.toOverwrite > 0
                  ? TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    )
                  : null,
            ),
            if (preview.overwriteDates.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                moreCount > 0
                    ? '$sample, +$moreCount'
                    : sample,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (preview.toOverwrite > 0) ...[
              const SizedBox(height: 12),
              Text(
                loc.importConfirmWarning,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.confirm),
          ),
        ],
      ),
    );
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
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _checkForUpdate(context),
              icon: const Icon(Icons.system_update),
              label: Text(loc.checkForUpdates),
            ),
            const Spacer(),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final text = snapshot.hasData
                    ? 'v${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                    : '';
                return Text(
                  text,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
