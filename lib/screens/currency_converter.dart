import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../models/rate_point.dart';
import '../enums/period.dart';
import '../services/storage_services.dart';
import '../services/history_services.dart';

class CurrencyConverterPage extends StatefulWidget {
  const CurrencyConverterPage({super.key});

  @override
  State<CurrencyConverterPage> createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage> {
  final TextEditingController amountController = TextEditingController();
  final StorageService storageService = StorageService();

  Map<String, dynamic> rates = {};
  List<String> history = [];

  String fromCurrency = 'USD';
  String toCurrency = 'EUR';

  double result = 0.0;
  bool isLoading = true;

  List<RatePoint> points = [];
  Period selectedPeriod = Period.d30;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    await loadData();
    await fetchRates();
    await fetchHistory();
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
        await fetchHistory();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchHistory() async {
    final result = await fetchHistoryData(
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      selectedPeriod: selectedPeriod,
    );

    setState(() {
      points = result;
    });
  }

  Future<void> loadData() async {
    final data = await storageService.loadData();

    setState(() {
      amountController.text = data['amount'];
      result = data['result'];
      fromCurrency = data['fromCurrency'];
      toCurrency = data['toCurrency'];
      history = List<String>.from(data['history']);
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

    await storageService.saveData(
      amount: amountController.text,
      result: result,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      history: history,
    );
  }

  void convertCurrency() {
    if (amountController.text.isEmpty) return;

    double amount = double.tryParse(amountController.text) ?? 0;

    if (!rates.containsKey(fromCurrency) || !rates.containsKey(toCurrency)) {
      return;
    }

    double fromRate = (rates[fromCurrency] as num).toDouble();
    double toRate = (rates[toCurrency] as num).toDouble();

    double usdAmount = amount / fromRate;
    double convertedAmount = usdAmount * toRate;

    setState(() {
      result = convertedAmount;
    });
    addToHistory(amount, convertedAmount);
    storageService.saveData(
      amount: amountController.text,
      result: result,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      history: history,
    );
  }

  void swapCurrencies() {
    setState(() {
      final temp = fromCurrency;
      fromCurrency = toCurrency;
      toCurrency = temp;
    });

    convertCurrency();
    fetchHistory();

    storageService.saveData(
      amount: amountController.text,
      result: result,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      history: history,
    );
  }

  Future<void> clearHistory() async {
    setState(() {
      history.clear();
    });

    await storageService.clearHistory();
  }

  double get minRate {
    if (points.isEmpty) return 0;
    return points.map((e) => e.value).reduce((a, b) => a < b ? a : b);
  }

  double get maxRate {
    if (points.isEmpty) return 0;
    return points.map((e) => e.value).reduce((a, b) => a > b ? a : b);
  }

  double get changePercent {
    if (points.length < 2) return 0;

    return ((points.last.value - points.first.value) / points.first.value) *
        100;
  }

  List<FlSpot> get chartSpots {
    return points.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();
  }

  Widget periodButton(String text, Period period) {
    bool selected = selectedPeriod == period;

    return GestureDetector(
      onTap: () async {
        setState(() {
          selectedPeriod = period;
        });

        await fetchHistory();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.green.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(color: selected ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> currencies = rates.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xffEDEFF3),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),

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
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 18,
                          ),
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
                                    storageService.saveData(
                                      amount: amountController.text,
                                      result: result,
                                      fromCurrency: fromCurrency,
                                      toCurrency: toCurrency,
                                      history: history,
                                    );
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
                                  return DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    fromCurrency = value!;
                                  });

                                  convertCurrency();
                                  fetchHistory();
                                  storageService.saveData(
                                    amount: amountController.text,
                                    result: result,
                                    fromCurrency: fromCurrency,
                                    toCurrency: toCurrency,
                                    history: history,
                                  );
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
                                  return DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    toCurrency = value!;
                                  });
                                  convertCurrency();
                                  fetchHistory();
                                  storageService.saveData(
                                    amount: amountController.text,
                                    result: result,
                                    fromCurrency: fromCurrency,
                                    toCurrency: toCurrency,
                                    history: history,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.grey.shade600,
                            ),
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
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "1 $fromCurrency = "
                                "${(rates[toCurrency] / rates[fromCurrency]).toStringAsFixed(4)} "
                                "$toCurrency",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                "${changePercent.toStringAsFixed(2)}%",
                                style: TextStyle(
                                  color: changePercent >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),

                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  periodButton("7 днів", Period.d7),
                                  periodButton("30 днів", Period.d30),
                                  periodButton("90 днів", Period.d90),
                                ],
                              ),

                              const SizedBox(height: 20),

                              SizedBox(
                                height: 250,
                                child: points.isEmpty
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : LineChart(
                                        LineChartData(
                                          minY: minRate,
                                          maxY: maxRate,
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: chartSpots,
                                              isCurved: true,
                                              color: Colors.green,
                                              dotData: FlDotData(show: false),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ],
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      physics:
                                          const NeverScrollableScrollPhysics(),
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
              ),
            ),
    );
  }
}
