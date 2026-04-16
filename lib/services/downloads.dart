import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Writes text files to the user's public Downloads folder on Android via
/// MediaStore. Survives app uninstall, which the app's sandbox directories
/// don't.
class Downloads {
  static const _channel = MethodChannel('memo/downloads');

  /// Returns a platform-specific location string on success (a MediaStore
  /// content:// URI on Android 10+, or an absolute path on older versions).
  static Future<String> saveText({
    required String filename,
    required String content,
    String mime = 'application/json',
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('saveToDownloads only implemented on Android');
    }
    final result = await _channel.invokeMethod<String>('saveToDownloads', {
      'name': filename,
      'content': content,
      'mime': mime,
    });
    if (result == null) throw StateError('Downloads channel returned null');
    return result;
  }

  /// Best-effort — swallows errors so caller code never fails solely because
  /// of a backup-to-Downloads hiccup.
  static Future<String?> saveTextSafe({
    required String filename,
    required String content,
    String mime = 'application/json',
  }) async {
    try {
      return await saveText(
        filename: filename,
        content: content,
        mime: mime,
      );
    } catch (e) {
      debugPrint('Downloads.saveTextSafe failed: $e');
      return null;
    }
  }
}
