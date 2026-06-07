import 'package:flutter_test/flutter_test.dart';
import 'package:currency_convert/services/currency_logic.dart';

void main() {
  group('CurrencyLogic tests', () {
    test('convert currency works correctly', () {
      final rates = {'USD': 1.0, 'EUR': 0.9};

      final result = CurrencyLogic.convert(
        amount: 100,
        rates: rates,
        from: 'USD',
        to: 'EUR',
      );

      expect(result, closeTo(90, 0.01));
    });

    test('convert returns 0 when currency missing', () {
      final rates = {'USD': 1.0};

      final result = CurrencyLogic.convert(
        amount: 100,
        rates: rates,
        from: 'USD',
        to: 'EUR',
      );

      expect(result, 0);
    });

    test('minValue works', () {
      expect(CurrencyLogic.minValue([5, 2, 10, 1]), 1);
    });

    test('maxValue works', () {
      expect(CurrencyLogic.maxValue([5, 2, 10, 1]), 10);
    });

    test('percentChange works', () {
      final result = CurrencyLogic.percentChange([100, 150]);

      expect(result, closeTo(50, 0.01));
    });

    test('history string format', () {
      final result = CurrencyLogic.buildHistory(
        amount: 10,
        from: 'USD',
        result: 9,
        to: 'EUR',
      );

      expect(result, '10.00 USD → 9.00 EUR');
    });
  });
}
