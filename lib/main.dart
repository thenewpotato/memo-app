import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/calendar_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/document_screen.dart';
import 'screens/search_screen.dart';
import 'screens/filter_screen.dart';
import 'screens/backup_screen.dart';
import 'services/downloads.dart';
import 'services/updater.dart';
import 'widgets/update_dialog.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    // Any uncaught Flutter-framework error lands here.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _logCrash(details.exceptionAsString(), details.stack);
    };

    // Fire-and-forget — don't block app launch on FS cleanup.
    unawaited(UpdateService.cleanupStaleApks());
    runApp(const DiaryApp());
  }, (error, stack) {
    // Anything asynchronous that escaped all other handlers lands here.
    _logCrash(error.toString(), stack);
  });
}

Future<void> _logCrash(String message, StackTrace? stack) async {
  try {
    final now = DateTime.now();
    final ts = now.toIso8601String().replaceAll(':', '-');
    final body = [
      'Time: ${now.toIso8601String()}',
      'Message: $message',
      'Stack:',
      stack?.toString() ?? '(no stack)',
      '',
    ].join('\n');
    await Downloads.saveTextSafe(
      filename: 'memo_crash_$ts.log',
      content: body,
      mime: 'text/plain',
    );
  } catch (_) {
    // Never let the crash logger itself crash.
  }
}

class DiaryApp extends StatelessWidget {
  const DiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Warm, diary-like color scheme
    const seedColor = Color(0xFF8B6914); // Warm amber/brown

    return MaterialApp(
      title: 'Memo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: seedColor,
        brightness: Brightness.light,
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: seedColor,
        brightness: Brightness.dark,
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
      ],
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _calendarKey = GlobalKey<CalendarScreenState>();
  final _taskListKey = GlobalKey<TaskListScreenState>();
  UpdateInfo? _pendingUpdate;

  @override
  void initState() {
    super.initState();
    _checkForUpdateSilent();
  }

  Future<void> _checkForUpdateSilent() async {
    final info = await UpdateService.checkForUpdate();
    if (!mounted || info == null) return;
    setState(() => _pendingUpdate = info);
  }

  void _refreshAll() {
    _calendarKey.currentState?.refresh();
    _taskListKey.currentState?.refresh();
  }

  Future<void> _runUpdate(UpdateInfo info) async {
    await showUpdateDownloadDialog(context, info);
    if (mounted) setState(() => _pendingUpdate = null);
  }

  Future<void> _skipUpdate(UpdateInfo info) async {
    await UpdateService.skipBuild(info.buildNumber);
    if (mounted) setState(() => _pendingUpdate = null);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _openToday() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentScreen(date: _todayKey()),
      ),
    );
    _refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final screens = [
      CalendarScreen(key: _calendarKey),
      TaskListScreen(key: _taskListKey),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.appName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FilterScreen()),
              );
              _refreshAll();
            },
            tooltip: loc.filterIncompleteTodos,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
              _refreshAll();
            },
            tooltip: loc.search,
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'backup') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BackupScreen()),
                );
                _refreshAll();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'backup',
                child: Row(
                  children: [
                    const Icon(Icons.cloud_download_outlined),
                    const SizedBox(width: 12),
                    Text(loc.backup),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_pendingUpdate != null)
            UpdateBanner(
              info: _pendingUpdate!,
              onUpdate: () => _runUpdate(_pendingUpdate!),
              onSkip: () => _skipUpdate(_pendingUpdate!),
              onDismiss: () =>
                  setState(() => _pendingUpdate = null),
            ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openToday,
        icon: const Icon(Icons.add),
        label: Text(loc.today),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            _calendarKey.currentState?.refresh();
          } else {
            _taskListKey.currentState?.refresh();
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: loc.calendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt),
            label: loc.taskList,
          ),
        ],
      ),
    );
  }
}
