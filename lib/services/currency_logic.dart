class CurrencyLogic {
  static double convert({
    required double amount,
    required Map<String, dynamic> rates,
    required String from,
    required String to,
  }) {
    if (!rates.containsKey(from) || !rates.containsKey(to)) {
      return 0.0;
    }

    final fromRate = (rates[from] as num).toDouble();
    final toRate = (rates[to] as num).toDouble();

    final usd = amount / fromRate;
    return usd * toRate;
  }

  static double minValue(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a < b ? a : b);
  }

  static double maxValue(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a > b ? a : b);
  }

  static double percentChange(List<double> values) {
    if (values.length < 2) return 0;
    return ((values.last - values.first) / values.first) * 100;
  }

  static String buildHistory({
    required double amount,
    required String from,
    required double result,
    required String to,
  }) {
    return '${amount.toStringAsFixed(2)} $from → '
        '${result.toStringAsFixed(2)} $to';
  }
}
