import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Currency Converter',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CurrencyConverterPage(),
    );
  }
}

class CurrencyConverterPage extends StatefulWidget {
  const CurrencyConverterPage({super.key});

  @override
  State<CurrencyConverterPage> createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage> {
  final TextEditingController amountController = TextEditingController();

  Map<String, dynamic> rates = {};

  String fromCurrency = 'USD';
  String toCurrency = 'EUR';

  double result = 0.0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
    fetchRates();
  }

  Future<void> fetchRates() async {
    try {
      final response = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/USD'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          rates = data['rates'];
          isLoading = false;
        });

        await loadData();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('amount', amountController.text);

    await prefs.setDouble('result', result);

    await prefs.setString('fromCurrency', fromCurrency);

    await prefs.setString('toCurrency', toCurrency);
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      amountController.text = prefs.getString('amount') ?? '';

      result = prefs.getDouble('result') ?? 0.0;

      fromCurrency = prefs.getString('fromCurrency') ?? 'USD';

      toCurrency = prefs.getString('toCurrency') ?? 'EUR';
    });
  }

  void convertCurrency() {
    if (amountController.text.isEmpty) return;

    double amount = double.tryParse(amountController.text) ?? 0;

    double fromRate = rates[fromCurrency].toDouble();
    double toRate = rates[toCurrency].toDouble();

    double usdAmount = amount / fromRate;
    double convertedAmount = usdAmount * toRate;

    setState(() {
      result = convertedAmount;
    });
    saveData();
  }

  @override
  Widget build(BuildContext context) {
    List<String> currencies = rates.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Конвертер валют'), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      saveData();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Сума',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  DropdownButton<String>(
                    value: fromCurrency,
                    isExpanded: true,
                    items: currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        fromCurrency = value!;
                      });
                      saveData();
                    },
                  ),

                  const SizedBox(height: 10),

                  DropdownButton<String>(
                    value: toCurrency,
                    isExpanded: true,
                    items: currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        toCurrency = value!;
                      });
                      saveData();
                    },
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: convertCurrency,
                    child: const Text('Конвертувати'),
                  ),

                  const SizedBox(height: 30),

                  Text(
                    'Результат:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    result.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
