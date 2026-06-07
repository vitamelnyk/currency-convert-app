import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  Future<void> saveData({
    required String amount,
    required double result,
    required String fromCurrency,
    required String toCurrency,
    required List<String> history,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('amount', amount);
    await prefs.setDouble('result', result);
    await prefs.setString('fromCurrency', fromCurrency);
    await prefs.setString('toCurrency', toCurrency);
    await prefs.setStringList('history', history);
  }

  Future<Map<String, dynamic>> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'amount': prefs.getString('amount') ?? '',
      'result': prefs.getDouble('result') ?? 0.0,
      'fromCurrency': prefs.getString('fromCurrency') ?? 'USD',
      'toCurrency': prefs.getString('toCurrency') ?? 'EUR',
      'history': prefs.getStringList('history') ?? [],
    };
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('history');
  }
}
