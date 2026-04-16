import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateInfo {
  final String version;
  final int buildNumber;
  final String apkUrl;
  final String notes;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.apkUrl,
    required this.notes,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String,
      buildNumber: (json['buildNumber'] as num).toInt(),
      apkUrl: json['apkUrl'] as String,
      notes: (json['notes'] as String?) ?? '',
    );
  }
}

class UpdateService {
  static const _manifestUrl =
      'https://pub-6035be7f014a43ecbf3c2024ecb05431.r2.dev/latest.json';
  static const _lastCheckKey = 'updater.lastCheckMs';
  static const _skippedBuildKey = 'updater.skippedBuild';
  static const _minCheckInterval = Duration(hours: 24);

  /// Returns an [UpdateInfo] if a newer version is available, else null.
  /// Respects throttling (at most one check per 24h) unless [force] is true.
  /// Also returns null if the user previously dismissed this specific build.
  static Future<UpdateInfo?> checkForUpdate({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!force) {
      final last = prefs.getInt(_lastCheckKey) ?? 0;
      final sinceLast = DateTime.now().millisecondsSinceEpoch - last;
      if (sinceLast < _minCheckInterval.inMilliseconds) return null;
    }

    final UpdateInfo remote;
    try {
      final res = await http
          .get(Uri.parse(_manifestUrl))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      remote = UpdateInfo.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Update check failed: $e');
      return null;
    }

    await prefs.setInt(
        _lastCheckKey, DateTime.now().millisecondsSinceEpoch);

    final info = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(info.buildNumber) ?? 0;
    if (remote.buildNumber <= currentBuild) return null;

    if (!force) {
      final skipped = prefs.getInt(_skippedBuildKey) ?? -1;
      if (skipped == remote.buildNumber) return null;
    }

    return remote;
  }

  /// Persist the user's "skip this version" choice so we don't nag until the
  /// next release.
  static Future<void> skipBuild(int buildNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_skippedBuildKey, buildNumber);
  }

  /// Downloads and fires the install intent for [info].
  /// The returned stream yields progress events until the OS installer takes
  /// over (at which point the app will be killed/replaced).
  static Stream<OtaEvent> downloadAndInstall(UpdateInfo info) {
    return OtaUpdate().execute(info.apkUrl);
  }

  /// Removes APKs left behind in the ota_update staging directory. Called on
  /// app start — each file is ~50MB so they add up fast across releases.
  static Future<void> cleanupStaleApks() async {
    try {
      final support = await getApplicationSupportDirectory();
      final dir = Directory(p.join(support.path, 'ota_update'));
      if (!dir.existsSync()) return;
      for (final entity in dir.listSync()) {
        if (entity is File) {
          try {
            entity.deleteSync();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('OTA cleanup failed: $e');
    }
  }
}
