import '../l10n/app_localizations.dart';

String formatEntryDate(String dateStr, AppLocalizations loc) {
  final parts = dateStr.split('-');
  final dt = DateTime(
      int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  return '${dt.day} ${loc.monthNames[dt.month - 1]} ${dt.year}';
}
