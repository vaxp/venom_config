import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'parser.dart';

/// Watches the configuration file for changes and emits updates.
class ConfigWatcher {
  final String filePath;
  final VaxpParser _parser = VaxpParser();
  StreamSubscription? _subscription;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  ConfigWatcher(this.filePath);

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  /// Starts watching the file.
  Future<void> start() async {
    final file = File(filePath);
    if (!await file.exists()) {
      // Create default if not exists
      await file.create(recursive: true);
      await file.writeAsString('// Venom Config File\n');
    }

    // Initial read
    await _readAndEmit();

    print('ConfigWatcher: Watching $filePath'); // DEBUG

    // Watch for changes
    // We listen to all events because atomic writes (rename) might trigger move/create instead of modify
    _subscription =
        file.parent.watch(events: FileSystemEvent.all).listen((event) async {
      print(
          'ConfigWatcher: Event received -> type: ${event.type}, path: ${event.path}'); // DEBUG

      // event.path might be absolute or relative depending on platform
      final eventPath = event.path;
      final targetName = p.basename(filePath);

      // On Linux, atomic rename (mv tmp target) often triggers a 'move' event
      // The path in the event might be the source (tmp) or destination (target) depending on implementation details
      // or sometimes just the directory.

      // We reload if:
      // 1. The event path ends with our target filename
      // 2. The event is a 'move' (rename) - we assume it might be our file being replaced
      // 3. The event path is the temporary file (which means it's being written/moved)

      bool shouldReload = false;

      if (eventPath.endsWith(targetName)) {
        shouldReload = true;
      } else if (event.type == FileSystemEvent.move) {
        // If a move happened in this directory, it's very likely our atomic write finishing
        shouldReload = true;
      } else if (eventPath.endsWith('.tmp')) {
        // If the temp file changed, we might want to wait a bit and check if target changed
        // But usually we wait for the move/modify on the target.
        // However, to be safe, let's check if the target file was modified recently.
      }

      if (shouldReload) {
        print(
            'ConfigWatcher: Target file changed (or likely changed)! Reloading...'); // DEBUG
        // Add a small delay to ensure write is complete
        await Future.delayed(const Duration(milliseconds: 200));
        await _readAndEmit();
      } else {
        print(
            'ConfigWatcher: Ignoring event for $eventPath (target: $targetName)'); // DEBUG
      }
    });
  }

  Future<void> _readAndEmit() async {
    try {
      final content = await File(filePath).readAsString();
      final data = _parser.parse(content);
      _controller.add(data);
    } catch (e) {
      print('Error reading config file: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
