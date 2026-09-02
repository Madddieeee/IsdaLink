import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  SearchHistoryService({
    String? userId,
    this.maxItems = 8,
  }) : _storageKey = _keyFor(userId);

  final String _storageKey;
  final int maxItems;

  static String _keyFor(String? userId) {
    final cleanUserId = userId?.trim() ?? '';
    final suffix = cleanUserId.isEmpty ? 'guest' : cleanUserId;

    return 'isdalink_recent_market_searches_$suffix';
  }

  Future<List<String>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getStringList(_storageKey) ?? const <String>[];

    return _normalized(stored);
  }

  Future<List<String>> add(String value) async {
    final clean = value.trim();

    if (clean.length < 2) {
      return load();
    }

    final current = await load();
    current.removeWhere(
      (item) => item.toLowerCase() == clean.toLowerCase(),
    );
    current.insert(0, clean);

    final updated = current.take(maxItems).toList();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_storageKey, updated);

    return updated;
  }

  Future<List<String>> remove(String value) async {
    final clean = value.trim();
    final current = await load();
    current.removeWhere(
      (item) => item.toLowerCase() == clean.toLowerCase(),
    );

    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_storageKey, current);

    return current;
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }

  List<String> _normalized(Iterable<String> values) {
    final result = <String>[];

    for (final value in values) {
      final clean = value.trim();

      if (clean.length < 2 ||
          result.any((item) => item.toLowerCase() == clean.toLowerCase())) {
        continue;
      }

      result.add(clean);

      if (result.length >= maxItems) {
        break;
      }
    }

    return result;
  }
}
