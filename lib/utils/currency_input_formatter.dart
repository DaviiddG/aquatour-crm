import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formateador de entrada para campos de moneda
/// Formatea números con separador de miles (punto) mientras el usuario escribe
/// Ejemplo: 5000000 → 5.000.000
class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,##0', 'es_CO');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Si el campo está vacío, permitir
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remover todos los caracteres que no sean dígitos
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Si no hay dígitos, retornar vacío
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Convertir a número y formatear
    final number = int.tryParse(digitsOnly);
    if (number == null) {
      return oldValue;
    }

    // Formatear con separador de miles (punto)
    String formatted = _formatter.format(number);

    // Calcular la nueva posición del cursor
    int cursorPosition = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }

  /// Convierte el texto formateado a un número double
  static double? parseFormattedValue(String formattedText) {
    if (formattedText.isEmpty) return null;
    
    // Remover puntos de miles
    String digitsOnly = formattedText.replaceAll('.', '');
    
    return double.tryParse(digitsOnly);
  }
}
