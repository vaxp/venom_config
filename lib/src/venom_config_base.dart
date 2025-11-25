import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'writer.dart';
import 'watcher.dart';

/// The central configuration manager for Venom.
class VenomConfig {
  static final VenomConfig _instance = VenomConfig._internal();

  factory VenomConfig() => _instance;

  VenomConfig._internal();

  Map<String, dynamic> _config = {};
  ConfigWatcher? _watcher;
  final VaxpWriter _writer = VaxpWriter();
  final _changeController = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of configuration changes.
  Stream<Map<String, dynamic>> get onConfigChanged => _changeController.stream;

  /// Initializes the configuration system.
  ///
  /// [customPath] can be used to override the default config location (~/.config/venom/settings.vaxp).
  Future<void> init({String? customPath}) async {
    String path;
    if (customPath != null) {
      path = customPath;
    } else {
      final home = Platform.environment['HOME'] ?? '/';
      path = p.join(home, '.config', 'venom', 'settings.vaxp');
    }

    _watcher = ConfigWatcher(path);

    // Listen to file changes
    _watcher!.stream.listen((newData) {
      _config = newData;
      _changeController.add(_config);
    });

    await _watcher!.start();
  }

  /// Retrieves a value from the configuration.
  ///
  /// Returns [defaultValue] if the key is not found.
  T? get<T>(String key, {T? defaultValue}) {
    return _config[key] as T? ?? defaultValue;
  }

  // Mutex lock to prevent race conditions during atomic writes
  Completer<void>? _writeLock;

  /// Sets a value and persists it to the file.
  Future<void> set(String key, dynamic value) async {
    // Wait for any active write to complete
    while (_writeLock != null) {
      await _writeLock!.future;
    }

    // Acquire lock
    final completer = Completer<void>();
    _writeLock = completer;

    try {
      _config[key] = value;
      // Optimistic update: notify listeners immediately
      _changeController.add(_config);

      // Write to file atomically
      if (_watcher != null) {
        final path = _watcher!.filePath;
        final tempFile = File('$path.tmp');
        final content = _writer.stringify(_config);

        await tempFile.writeAsString(content, flush: true);
        await tempFile.rename(path);
      }
    } finally {
      // Release lock
      _writeLock = null;
      completer.complete();
    }
  }

  /// Gets the entire configuration map.
  Map<String, dynamic> getAll() => Map.unmodifiable(_config);

  void dispose() {
    _watcher?.dispose();
    _changeController.close();
  }
}
