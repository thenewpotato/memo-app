import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime displayMonth;
  final DateTime? selectedDate;
  final Set<String> datesWithEntries;
  final Set<String> datesWithIncompleteTodos;
  final ValueChanged<DateTime> onDateTap;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const CalendarWidget({
    super.key,
    required this.displayMonth,
    this.selectedDate,
    required this.datesWithEntries,
    required this.datesWithIncompleteTodos,
    required this.onDateTap,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final todayKey = _dateKey(now);

    final year = displayMonth.year;
    final month = displayMonth.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    // Monday = 1, Sunday = 7
    final startWeekday = firstDay.weekday; // 1=Mon

    final dayLabels = [
      loc.get('mon'),
      loc.get('tue'),
      loc.get('wed'),
      loc.get('thu'),
      loc.get('fri'),
      loc.get('sat'),
      loc.get('sun'),
    ];

    return Column(
      children: [
        // Month navigation header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 28),
                onPressed: onPreviousMonth,
              ),
              Text(
                '${loc.monthNames[month - 1]} $year',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 28),
                onPressed: onNextMonth,
              ),
            ],
          ),
        ),
        // Day-of-week headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: dayLabels
                .map((label) => Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),
        // Calendar grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildGrid(context, firstDay, lastDay, startWeekday, todayKey, theme),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, DateTime firstDay, DateTime lastDay,
      int startWeekday, String todayKey, ThemeData theme) {
    final cells = <Widget>[];
    // Pad before first day (Monday=1 means 0 padding, Sunday=7 means 6 padding)
    final paddingDays = startWeekday - 1;
    for (int i = 0; i < paddingDays; i++) {
      cells.add(const SizedBox());
    }
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(firstDay.year, firstDay.month, day);
      final key = _dateKey(date);
      final isToday = key == todayKey;
      final isSelected =
          selectedDate != null && _dateKey(selectedDate!) == key;
      final hasEntry = datesWithEntries.contains(key);
      final hasIncompleteTodo = datesWithIncompleteTodos.contains(key);

      cells.add(
        GestureDetector(
          onTap: () => onDateTap(date),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer
                  : isToday
                      ? theme.colorScheme.tertiaryContainer.withOpacity(0.5)
                      : null,
              borderRadius: BorderRadius.circular(12),
              border: isToday
                  ? Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight:
                        isToday || isSelected ? FontWeight.bold : null,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasEntry)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (hasEntry && hasIncompleteTodo)
                      const SizedBox(width: 3),
                    if (hasIncompleteTodo)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      children: cells,
    );
  }
}
