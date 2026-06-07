import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rate_point.dart';
import '../enums/period.dart';

Future<List<RatePoint>> fetchHistoryData({
  required String fromCurrency,
  required String toCurrency,
  required Period selectedPeriod,
}) async {
  try{
    if (fromCurrency == toCurrency) {
      return [RatePoint(DateTime.now(), 1.0)];
    }
    int days;
    switch (selectedPeriod) {
      case Period.d7:
        days = 7;
        break;
      case Period.d30:
        days = 30;
        break;
      case Period.d90:
        days = 90;
        break;
    }
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final start =
        "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";

    final end =
        "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

    final url =
        "http://currency-proxy-production.up.railway.app/history?start=$start&end=$end&from=$fromCurrency&to=$toCurrency";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(response.body);

    if (data["rates"] == null) {
      return [];
    }
    final Map<String, dynamic> ratesData = data["rates"];
    final List<RatePoint> points = [];
    ratesData.forEach((date, value) {
      final rate = value[toCurrency];
      if (rate is num) {
        points.add(RatePoint(DateTime.parse(date), rate.toDouble()));
      }
    });
    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  } catch (e) {
    print("fetchHistoryData error: $e");
    return [];
  }
}
