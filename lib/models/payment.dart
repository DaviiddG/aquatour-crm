class Payment {
  final int? id;
  final DateTime fechaPago;
  final String metodo;
  final String? bancoEmisor;
  final String numReferencia;
  final double monto;
  final int idReserva;
  final int? idEmpleado;
  final String? nombreEmpleado;

  Payment({
    this.id,
    required this.fechaPago,
    required this.metodo,
    this.bancoEmisor,
    required this.numReferencia,
    required this.monto,
    required this.idReserva,
    this.idEmpleado,
    this.nombreEmpleado,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: _parseInt(map['id'] ?? map['id_pago']),
      fechaPago: _parseDate(map['fechaPago'] ?? map['fecha_pago']) ?? DateTime.now(),
      metodo: map['metodo']?.toString() ?? '',
      bancoEmisor: map['bancoEmisor'] ?? map['banco_emisor'],
      numReferencia: map['numReferencia']?.toString() ?? map['num_referencia']?.toString() ?? '',
      monto: _parseDouble(map['monto']) ?? 0.0,
      idReserva: _parseInt(map['idReserva'] ?? map['id_reserva']) ?? 0,
      idEmpleado: _parseInt(map['idEmpleado'] ?? map['id_empleado']),
      nombreEmpleado: map['nombreEmpleado'] ?? map['nombre_empleado'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha_pago': fechaPago.toIso8601String(),
      'metodo': metodo,
      'banco_emisor': bancoEmisor,
      'num_referencia': numReferencia,
      'monto': monto,
      'id_reserva': idReserva,
    };
  }

  Payment copyWith({
    int? id,
    DateTime? fechaPago,
    String? metodo,
    String? bancoEmisor,
    String? numReferencia,
    double? monto,
    int? idReserva,
    int? idEmpleado,
    String? nombreEmpleado,
  }) {
    return Payment(
      id: id ?? this.id,
      fechaPago: fechaPago ?? this.fechaPago,
      metodo: metodo ?? this.metodo,
      bancoEmisor: bancoEmisor ?? this.bancoEmisor,
      numReferencia: numReferencia ?? this.numReferencia,
      monto: monto ?? this.monto,
      idReserva: idReserva ?? this.idReserva,
      idEmpleado: idEmpleado ?? this.idEmpleado,
      nombreEmpleado: nombreEmpleado ?? this.nombreEmpleado,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }
}

// Métodos de pago comunes
class PaymentMethod {
  static const String transferencia = 'Transferencia';
  static const String efectivo = 'Efectivo';
  static const String tarjetaCredito = 'Tarjeta de Crédito';
  static const String tarjetaDebito = 'Tarjeta de Débito';
  static const String cheque = 'Cheque';
  
  static List<String> get all => [
    transferencia,
    efectivo,
    tarjetaCredito,
    tarjetaDebito,
    cheque,
  ];
}
