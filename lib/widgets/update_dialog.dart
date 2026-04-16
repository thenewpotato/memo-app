import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import '../l10n/app_localizations.dart';
import '../services/updater.dart';

/// Shows a non-dismissible progress dialog that downloads and installs the
/// given update. The dialog pops itself when the install intent is fired or
/// when an error occurs.
Future<void> showUpdateDownloadDialog(
  BuildContext context,
  UpdateInfo info,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _UpdateDownloadDialog(info: info),
  );
}

class _UpdateDownloadDialog extends StatefulWidget {
  final UpdateInfo info;
  const _UpdateDownloadDialog({required this.info});

  @override
  State<_UpdateDownloadDialog> createState() => _UpdateDownloadDialogState();
}

class _UpdateDownloadDialogState extends State<_UpdateDownloadDialog> {
  double? _progress; // null = indeterminate
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    UpdateService.downloadAndInstall(widget.info).listen(
      (event) {
        if (!mounted) return;
        if (event.status == OtaStatus.DOWNLOADING) {
          final v = double.tryParse(event.value ?? '');
          setState(() => _progress = v == null ? null : v / 100.0);
        } else if (event.status == OtaStatus.INSTALLING ||
            event.status == OtaStatus.INSTALLATION_DONE) {
          Navigator.of(context).maybePop();
        } else {
          // Any error / cancel status. The package exposes several (DOWNLOAD_ERROR,
          // CHECKSUM_ERROR, PERMISSION_NOT_GRANTED_ERROR, CANCELED, etc.) —
          // we surface them uniformly.
          setState(() => _error = event.value ?? event.status.toString());
        }
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _error = e.toString());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text('${loc.updateDownloading} v${widget.info.version}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error == null) ...[
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 12),
            Text(_progress == null
                ? loc.updatePreparing
                : '${(_progress! * 100).toStringAsFixed(0)}%'),
          ] else ...[
            Text(loc.updateFailed,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 8),
            Text(_error!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
      actions: [
        if (_error != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.close),
          ),
      ],
    );
  }
}

/// Compact, dismissible banner shown on the home screen when an update is
/// available. Caller is responsible for hiding it after the user interacts.
class UpdateBanner extends StatelessWidget {
  final UpdateInfo info;
  final VoidCallback onUpdate;
  final VoidCallback onSkip;
  final VoidCallback onDismiss;

  const UpdateBanner({
    super.key,
    required this.info,
    required this.onUpdate,
    required this.onSkip,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            Icon(Icons.system_update,
                color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${loc.updateAvailable} v${info.version}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  if (info.notes.isNotEmpty)
                    Text(
                      info.notes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.8),
                      ),
                    ),
                ],
              ),
            ),
            TextButton(onPressed: onSkip, child: Text(loc.skip)),
            FilledButton.tonal(
                onPressed: onUpdate, child: Text(loc.updateNow)),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDismiss,
              tooltip: loc.close,
            ),
          ],
        ),
      ),
    );
  }
}
