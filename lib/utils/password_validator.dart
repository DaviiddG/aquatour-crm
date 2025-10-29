/// Validador de contraseñas fuertes para Aquatour CRM
class PasswordValidator {
  /// Valida que la contraseña cumpla con los requisitos de seguridad
  /// 
  /// Requisitos:
  /// - Mínimo 8 caracteres
  /// - Al menos 1 letra mayúscula
  /// - Al menos 1 letra minúscula
  /// - Al menos 1 número
  /// - Al menos 1 carácter especial
  static String? validate(String? value, {bool isRequired = true}) {
    // Si no es requerida y está vacía, es válida
    if (!isRequired && (value == null || value.isEmpty)) {
      return null;
    }

    // Si es requerida y está vacía, error
    if (isRequired && (value == null || value.isEmpty)) {
      return 'La contraseña es requerida';
    }

    final password = value!;

    // Verificar longitud mínima
    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    // Verificar letra mayúscula
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Debe contener al menos una letra mayúscula';
    }

    // Verificar letra minúscula
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Debe contener al menos una letra minúscula';
    }

    // Verificar número
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Debe contener al menos un número';
    }

    // Verificar carácter especial
    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return r'Debe contener al menos un carácter especial (!@#$%^&*(),.?":{}|<>)';
    }

    return null; // Contraseña válida
  }

  /// Obtiene el nivel de fortaleza de la contraseña (0-5)
  static int getStrength(String password) {
    int strength = 0;

    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) strength++;

    return strength;
  }

  /// Obtiene el mensaje de fortaleza de la contraseña
  static String getStrengthMessage(String password) {
    final strength = getStrength(password);

    switch (strength) {
      case 0:
      case 1:
        return 'Muy débil';
      case 2:
        return 'Débil';
      case 3:
        return 'Aceptable';
      case 4:
        return 'Fuerte';
      case 5:
        return 'Muy fuerte';
      default:
        return '';
    }
  }

  /// Obtiene el texto de ayuda con los requisitos
  static String getHelpText() {
    return 'Requisitos:\n'
        '• Mínimo 8 caracteres\n'
        '• Al menos 1 mayúscula\n'
        '• Al menos 1 minúscula\n'
        '• Al menos 1 número\n'
        '• Al menos 1 carácter especial (!@#\$%^&*(),.?":{}|<>)';
  }
}
