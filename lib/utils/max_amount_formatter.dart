import 'package:flutter/services.dart';

/// Formatter que limita el monto máximo que se puede ingresar
class MaxAmountFormatter extends TextInputFormatter {
  final double maxAmount;

  MaxAmountFormatter(this.maxAmount);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remover puntos para obtener el número real
    final cleanText = newValue.text.replaceAll('.', '');
    final numericValue = int.tryParse(cleanText);

    if (numericValue == null) {
      return oldValue;
    }

    // Si el valor excede el máximo, mantener el valor anterior
    if (numericValue > maxAmount) {
      return oldValue;
    }

    return newValue;
  }
}
