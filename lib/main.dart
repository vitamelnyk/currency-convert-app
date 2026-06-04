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
  List<String> history = [];

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
    await prefs.setStringList('history', history);
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      amountController.text = prefs.getString('amount') ?? '';
      result = prefs.getDouble('result') ?? 0.0;
      fromCurrency = prefs.getString('fromCurrency') ?? 'USD';
      toCurrency = prefs.getString('toCurrency') ?? 'EUR';
      history = prefs.getStringList('history') ?? [];
    });
  }

  Future<void> addToHistory(double amount, double convertedAmount) async {
    final record =
        '${amount.toStringAsFixed(2)} $fromCurrency → '
        '${convertedAmount.toStringAsFixed(2)} $toCurrency';

    setState(() {
      history.insert(0, record);

      if (history.length > 20) {
        history.removeLast();
      }
    });

    await saveData();
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
    addToHistory(amount, convertedAmount);
    saveData();
  }

  void swapCurrencies() {
    setState(() {
      final temp = fromCurrency;
      fromCurrency = toCurrency;
      toCurrency = temp;
    });

    convertCurrency();
    saveData();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      history.clear();
    });

    await prefs.remove('history');
  }

  @override
  Widget build(BuildContext context) {
    List<String> currencies = rates.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    const Text(
                      "Конвертер валют",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 30),

                    Text(
                      "1 $fromCurrency = ${(rates[toCurrency] / rates[fromCurrency]).toStringAsFixed(4)} $toCurrency",
                      style: const TextStyle(color: Colors.green, fontSize: 18),
                    ),

                    const SizedBox(height: 30),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Сума",
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(blurRadius: 10, color: Colors.black12),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (_) {
                                saveData();
                                convertCurrency();
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          DropdownButton<String>(
                            underline: const SizedBox(),
                            value: fromCurrency,
                            items: currencies.map((e) {
                              return DropdownMenuItem(value: e, child: Text(e));
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                fromCurrency = value!;
                              });

                              convertCurrency();
                              saveData();
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    GestureDetector(
                      onTap: swapCurrencies,
                      child: Container(
                        width: 65,
                        height: 65,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xffA6E37B),
                        ),
                        child: const Icon(Icons.swap_vert, size: 34),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Конвертовано в",
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 25,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(blurRadius: 10, color: Colors.black12),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              result.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          DropdownButton<String>(
                            underline: const SizedBox(),
                            value: toCurrency,
                            items: currencies.map((e) {
                              return DropdownMenuItem(value: e, child: Text(e));
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                toCurrency = value!;
                              });

                              convertCurrency();
                              saveData();
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          "Дані оновлено",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: fetchRates,
                        icon: const Icon(Icons.refresh),
                        label: const Text(
                          "Оновити курс",
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(blurRadius: 10, color: Colors.black12),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Історія",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: clearHistory,
                                icon: const Icon(Icons.delete),
                                label: const Text('Очистити'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.black,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          history.isEmpty
                              ? const Text("Історія порожня")
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: history.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      leading: const Icon(Icons.history),
                                      title: Text(history[index]),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
