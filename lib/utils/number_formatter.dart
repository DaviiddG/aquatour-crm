import 'package:intl/intl.dart';

class NumberFormatter {
  // Formateador con separador de miles (punto) y decimales (coma)
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  static final NumberFormat _decimalFormatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _numberFormatter = NumberFormat.decimalPattern('es_CO');

  /// Formatea un número como moneda sin decimales
  /// Ejemplo: 1000000 -> $1.000.000
  static String formatCurrency(double value) {
    return _currencyFormatter.format(value);
  }

  /// Formatea un número como moneda con decimales
  /// Ejemplo: 1000000.50 -> $1.000.000,50
  static String formatCurrencyWithDecimals(double value) {
    return _decimalFormatter.format(value);
  }

  /// Formatea un número sin símbolo de moneda
  /// Ejemplo: 1000000 -> 1.000.000
  static String formatNumber(double value) {
    return _numberFormatter.format(value);
  }

  /// Formatea un número con decimales sin símbolo de moneda
  /// Ejemplo: 1000000.50 -> 1.000.000,50
  static String formatNumberWithDecimals(double value, {int decimals = 2}) {
    final formatter = NumberFormat.decimalPattern('es_CO');
    formatter.minimumFractionDigits = decimals;
    formatter.maximumFractionDigits = decimals;
    return formatter.format(value);
  }
}
