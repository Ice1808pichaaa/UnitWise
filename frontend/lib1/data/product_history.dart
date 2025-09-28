import 'package:shared_preferences/shared_preferences.dart';

class ProductHistory {
  ProductHistory._();
  static final ProductHistory instance = ProductHistory._();

  static const _key = 'product_history_texts';

  Future<List<String>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? <String>[];
  }

  Future<bool> add(String text) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];

    String normalize(String s) => s.replaceAll(RegExp(r'\s+'), '').trim();

    final normalizedNew = normalize(text);
    final normalizedList = list.map(normalize).toList();

    if (normalizedList.contains(normalizedNew)) {
      return false; // already exists
    }

    list.add(text); // keep original formatting for display
    await prefs.setStringList(_key, list);
    return true; // newly added
  }

  Future<void> removeAt(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      await prefs.setStringList(_key, list);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
