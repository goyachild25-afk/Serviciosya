/// Validador de cédula de identidad dominicana.
///
/// Algoritmo Luhn adaptado por la Junta Central Electoral (JCE):
///   Los primeros 10 dígitos se multiplican alternadamente por 1 y 2. Cada
///   producto se descompone en dígitos individuales que se suman, y todo el
///   agregado se suma. El dígito verificador es lo que falte a la próxima
///   decena.
///
/// Formatos aceptados:
///   'XXX-XXXXXXX-X'   (guiones)
///   'XXXXXXXXXXX'     (solo dígitos, 11 caracteres)
class CedulaValidator {
  CedulaValidator._();

  /// Devuelve true si la cédula tiene el formato correcto y el dígito
  /// verificador es válido. No consulta la base de la JCE — no hay una API
  /// pública, así que esto solo previene errores de tipeo y cédulas
  /// obviamente inventadas.
  static bool isValid(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 11) return false;

    // Todo ceros o repetidos → falso obvio
    if (RegExp(r'^(\d)\1+$').hasMatch(digits)) return false;

    // Los primeros 3 dígitos indican la oficialía (001-999). 000 no existe.
    final oficialia = int.tryParse(digits.substring(0, 3)) ?? 0;
    if (oficialia == 0) return false;

    // Algoritmo Luhn variante JCE
    final weights = [1, 2, 1, 2, 1, 2, 1, 2, 1, 2];
    var sum = 0;
    for (var i = 0; i < 10; i++) {
      var product = int.parse(digits[i]) * weights[i];
      if (product >= 10) product = (product ~/ 10) + (product % 10);
      sum += product;
    }
    final expected = (10 - (sum % 10)) % 10;
    final provided = int.parse(digits[10]);
    return expected == provided;
  }

  /// Formatea a XXX-XXXXXXX-X. Si el input no tiene 11 dígitos, lo devuelve
  /// sin tocar (para no interrumpir la edición).
  static String format(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 11) return input;
    return '${digits.substring(0, 3)}-${digits.substring(3, 10)}-${digits.substring(10)}';
  }

  /// Mensaje amigable para el usuario. null si la cédula es válida.
  static String? errorMessage(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'Ingresa tu número de cédula';
    if (digits.length < 11) return 'La cédula debe tener 11 dígitos';
    if (digits.length > 11) return 'La cédula no puede tener más de 11 dígitos';
    if (RegExp(r'^(\d)\1+$').hasMatch(digits)) {
      return 'Número de cédula inválido';
    }
    final oficialia = int.tryParse(digits.substring(0, 3)) ?? 0;
    if (oficialia == 0) return 'Número de cédula inválido';
    if (!isValid(input)) return 'Número de cédula inválido (verifica el último dígito)';
    return null;
  }
}
