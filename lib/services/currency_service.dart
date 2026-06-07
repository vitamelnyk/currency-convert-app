import 'dart:convert';
import 'package:http/http.dart' as http;

class RatesService {
  Future<Map<String, dynamic>?> fetchRates() async {
    final response = await http.get(
      Uri.parse('https://open.er-api.com/v6/latest/USD'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    }

    return null;
  }
}
