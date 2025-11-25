import 'package:flutter_test/flutter_test.dart';
import 'package:venom_config/src/parser.dart';
import 'package:venom_config/src/writer.dart';

void main() {
  group('VaxpParser', () {
    final parser = VaxpParser();

    test('parses simple section', () {
      final input = '''
SECTION system {
    theme_mode: "dark";
    scale: 1.5;
}
''';
      final result = parser.parse(input);
      expect(result['system.theme_mode'], 'dark');
      expect(result['system.scale'], 1.5);
    });

    test('parses multiple sections', () {
      final input = '''
SECTION system {
    theme: "dark";
}
SECTION apps.terminal {
    font: 14;
}
''';
      final result = parser.parse(input);
      expect(result['system.theme'], 'dark');
      expect(result['apps.terminal.font'], 14);
    });
  });

  group('VaxpWriter', () {
    final writer = VaxpWriter();

    test('writes simple map', () {
      final data = {
        'system.theme': 'dark',
        'system.scale': 1.0,
      };
      final output = writer.stringify(data);
      expect(output, contains('SECTION system {'));
      expect(output, contains('theme: "dark";'));
      expect(output, contains('scale: 1.0;'));
    });

    test('writes multiple sections', () {
      final data = {
        'system.theme': 'dark',
        'apps.terminal.font': 14,
      };
      final output = writer.stringify(data);
      expect(output, contains('SECTION system {'));
      expect(output, contains('SECTION apps.terminal {'));
    });
  });

  group('Round Trip', () {
    final parser = VaxpParser();
    final writer = VaxpWriter();

    test('preserves data', () {
      final original = {
        'system.theme': 'dark',
        'apps.terminal.font': 14,
        'apps.browser.home': 'google.com',
      };
      final text = writer.stringify(original);
      final parsed = parser.parse(text);
      expect(parsed, equals(original));
    });
  });
}
