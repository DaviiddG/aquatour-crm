class Payment {
  final int? id;
  final DateTime fechaPago;
  final String metodo;
  final String? bancoEmisor;
  final String numReferencia;
  final double monto;
  final int? idReserva;
  final int? idCotizacion;
  final int? idEmpleado;
  final String? empleadoNombre;
  final String? empleadoApellido;

  Payment({
    this.id,
    required this.fechaPago,
    required this.metodo,
    this.bancoEmisor,
    required this.numReferencia,
    required this.monto,
    this.idReserva,
    this.idCotizacion,
    this.idEmpleado,
    this.empleadoNombre,
    this.empleadoApellido,
  });
  
  // Nombre completo del empleado
  String get empleadoNombreCompleto {
    if (empleadoNombre != null && empleadoApellido != null) {
      return '$empleadoNombre $empleadoApellido';
    }
    if (idEmpleado != null) {
      return 'Usuario Inactivo #$idEmpleado';
    }
    return 'Sin empleado';
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: _parseInt(map['id'] ?? map['id_pago']),
      fechaPago: _parseDate(map['fechaPago'] ?? map['fecha_pago']) ?? DateTime.now(),
      metodo: map['metodo']?.toString() ?? '',
      bancoEmisor: map['bancoEmisor'] ?? map['banco_emisor'],
      numReferencia: map['numReferencia']?.toString() ?? map['num_referencia']?.toString() ?? '',
      monto: _parseDouble(map['monto']) ?? 0.0,
      idReserva: _parseInt(map['idReserva'] ?? map['id_reserva']),
      idCotizacion: _parseInt(map['idCotizacion'] ?? map['id_cotizacion']),
      idEmpleado: _parseInt(map['idEmpleado'] ?? map['id_empleado']),
      empleadoNombre: map['empleadoNombre']?.toString(),
      empleadoApellido: map['empleadoApellido']?.toString(),
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
      'id_cotizacion': idCotizacion,
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
    int? idCotizacion,
    int? idEmpleado,
    String? empleadoNombre,
    String? empleadoApellido,
  }) {
    return Payment(
      id: id ?? this.id,
      fechaPago: fechaPago ?? this.fechaPago,
      metodo: metodo ?? this.metodo,
      bancoEmisor: bancoEmisor ?? this.bancoEmisor,
      numReferencia: numReferencia ?? this.numReferencia,
      monto: monto ?? this.monto,
      idReserva: idReserva ?? this.idReserva,
      idCotizacion: idCotizacion ?? this.idCotizacion,
      idEmpleado: idEmpleado ?? this.idEmpleado,
      empleadoNombre: empleadoNombre ?? this.empleadoNombre,
      empleadoApellido: empleadoApellido ?? this.empleadoApellido,
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
