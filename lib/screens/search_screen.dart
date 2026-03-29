import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/diary_entry.dart';
import '../l10n/app_localizations.dart';
import 'document_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _db = DatabaseHelper.instance;
  final _searchController = TextEditingController();
  List<DiaryEntry> _results = [];
  bool _hasSearched = false;

  Future<void> _search() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    final results = await _db.searchEntries(keyword);
    setState(() {
      _results = results;
      _hasSearched = true;
    });
  }

  String _formatDate(String dateStr, AppLocalizations loc) {
    final parts = dateStr.split('-');
    final dt = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final monthName = loc.monthNames[dt.month - 1];
    return '${dt.day} $monthName ${dt.year}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: loc.searchHint,
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _search(),
          style: theme.textTheme.bodyLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _search,
          ),
        ],
      ),
      body: _hasSearched && _results.isEmpty
          ? Center(
              child: Text(
                loc.noResults,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final entry = _results[index];
                return ListTile(
                  title: Text(
                    _formatDate(entry.date, loc),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: entry.textContent.isNotEmpty
                      ? Text(
                          entry.textContent.length > 80
                              ? '${entry.textContent.substring(0, 80)}...'
                              : entry.textContent,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DocumentScreen(date: entry.date),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
