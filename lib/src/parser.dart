/// A parser for the Venom Advanced Exchange Protocol (VAXP) format.
class VaxpParser {
  /// Parses a VAXP string into a flat Map with dot-notation keys.
  ///
  /// Example input:
  /// SECTION system {
  ///   theme_mode: "dark";
  /// }
  ///
  /// Example output:
  /// { "system.theme_mode": "dark" }
  Map<String, dynamic> parse(String content) {
    final Map<String, dynamic> result = {};
    final lines = content.split('\n');
    String? currentSection;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('//')) continue;

      // Handle Section Start
      if (line.startsWith('SECTION')) {
        final match = RegExp(
          r'SECTION\s+([a-zA-Z0-9_.]+)\s*\{',
        ).firstMatch(line);
        if (match != null) {
          currentSection = match.group(1);
        }
        continue;
      }

      // Handle Section End
      if (line == '}') {
        currentSection = null;
        continue;
      }

      // Handle Key-Value pairs
      if (currentSection != null && line.contains(':')) {
        final parts = line.split(':');
        final key = parts[0].trim();
        var valueRaw = parts
            .sublist(1)
            .join(':')
            .trim(); // Re-join in case value has ':' (e.g. URL)

        if (valueRaw.endsWith(';')) {
          valueRaw = valueRaw.substring(0, valueRaw.length - 1);
        }

        final fullKey = '$currentSection.$key';
        result[fullKey] = _parseValue(valueRaw);
      }
    }

    return result;
  }

  dynamic _parseValue(String value) {
    if (value == 'true') return true;
    if (value == 'false') return false;

    // Number
    if (RegExp(r'^-?\d+(\.\d+)?$').hasMatch(value)) {
      if (value.contains('.')) return double.parse(value);
      return int.parse(value);
    }

    // String
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      return value.substring(1, value.length - 1);
    }

    // Fallback (return as string)
    return value;
  }
}
