import 'package:shared_preferences/shared_preferences.dart';

final class SharedPrefsSource {
  SharedPrefsSource._();
  static final SharedPrefsSource _instance = SharedPrefsSource._();
  static SharedPrefsSource get instance => _instance;

  final _prefs = SharedPreferencesAsync();

  //keys
  final _kClearedCacheDate = 'cleared_cache_date';

  Future<DateTime?> get clearedCacheDate async {
    final dateString = await _prefs.getString(_kClearedCacheDate);
    if (dateString == null) return null;
    return DateTime.tryParse(dateString);
  }

  Future<void> setClearedCacheDate(DateTime date) async {
    final dateString = date.toIso8601String();
    await _prefs.setString(_kClearedCacheDate, dateString);
  }
}
