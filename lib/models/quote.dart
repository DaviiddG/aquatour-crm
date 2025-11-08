import 'companion.dart';

enum QuoteStatus {
  pendiente,
  aceptada,
  rechazada,
  vencida;

  String get displayName {
    switch (this) {
      case QuoteStatus.pendiente:
        return 'Pendiente';
      case QuoteStatus.aceptada:
        return 'Aceptada';
      case QuoteStatus.rechazada:
        return 'Rechazada';
      case QuoteStatus.vencida:
        return 'Vencida';
    }
  }
}

class Quote {
  final int? id;
  final DateTime fechaInicioViaje;
  final DateTime fechaFinViaje;
  final double precioEstimado;
  final int? idPaquete;
  final int? idDestino;
  final double? precioDestino;
  final int idCliente;
  final int idEmpleado;
  final String? empleadoNombre;
  final String? empleadoApellido;
  final QuoteStatus estado;
  final List<Companion> acompanantes;

  Quote({
    this.id,
    required this.fechaInicioViaje,
    required this.fechaFinViaje,
    required this.precioEstimado,
    this.idPaquete,
    this.idDestino,
    this.precioDestino,
    required this.idCliente,
    required this.idEmpleado,
    this.empleadoNombre,
    this.empleadoApellido,
    this.estado = QuoteStatus.pendiente,
    this.acompanantes = const [],
  });
  
  String get empleadoNombreCompleto {
    if (empleadoNombre != null && empleadoApellido != null) {
      return '$empleadoNombre $empleadoApellido';
    }
    return 'Usuario Inactivo #$idEmpleado';
  }

  factory Quote.fromMap(Map<String, dynamic> map) {
    QuoteStatus status = QuoteStatus.pendiente;
    final estadoStr = map['estado']?.toString().toLowerCase();
    if (estadoStr != null) {
      switch (estadoStr) {
        case 'aceptada':
          status = QuoteStatus.aceptada;
          break;
        case 'rechazada':
          status = QuoteStatus.rechazada;
          break;
        case 'vencida':
          status = QuoteStatus.vencida;
          break;
        default:
          status = QuoteStatus.pendiente;
      }
    }

    // Parsear acompañantes si existen
    List<Companion> companions = [];
    if (map['acompanantes'] != null) {
      if (map['acompanantes'] is List) {
        companions = (map['acompanantes'] as List)
            .map((c) => Companion.fromMap(c as Map<String, dynamic>))
            .toList();
      }
    }

    return Quote(
      id: _parseInt(map['id'] ?? map['id_cotizacion']),
      fechaInicioViaje: _parseDate(map['fechaInicioViaje'] ?? map['fecha_inicio_viaje']),
      fechaFinViaje: _parseDate(map['fechaFinViaje'] ?? map['fecha_fin_viaje']),
      precioEstimado: _parseDouble(map['precioEstimado'] ?? map['precio_estimado']) ?? 0.0,
      idPaquete: _parseInt(map['idPaquete'] ?? map['id_paquete']),
      idDestino: _parseInt(map['idDestino'] ?? map['id_destino']),
      precioDestino: _parseDouble(map['precioDestino'] ?? map['precio_destino']),
      idCliente: _parseInt(map['idCliente'] ?? map['id_cliente']) ?? 0,
      idEmpleado: _parseInt(map['idEmpleado'] ?? map['id_empleado']) ?? 0,
      empleadoNombre: map['empleadoNombre']?.toString(),
      empleadoApellido: map['empleadoApellido']?.toString(),
      estado: status,
      acompanantes: companions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha_inicio_viaje': fechaInicioViaje.toIso8601String().split('T')[0],
      'fecha_fin_viaje': fechaFinViaje.toIso8601String().split('T')[0],
      'precio_estimado': precioEstimado,
      'id_paquete': idPaquete,
      'id_destino': idDestino,
      'precio_destino': precioDestino,
      'id_cliente': idCliente,
      'id_empleado': idEmpleado,
      'estado': estado.name,
      'acompanantes': acompanantes.map((c) => c.toMap()).toList(),
    };
  }

  Quote copyWith({
    int? id,
    DateTime? fechaInicioViaje,
    DateTime? fechaFinViaje,
    double? precioEstimado,
    int? idPaquete,
    int? idDestino,
    double? precioDestino,
    int? idCliente,
    int? idEmpleado,
    String? empleadoNombre,
    String? empleadoApellido,
    QuoteStatus? estado,
    List<Companion>? acompanantes,
  }) {
    return Quote(
      id: id ?? this.id,
      fechaInicioViaje: fechaInicioViaje ?? this.fechaInicioViaje,
      fechaFinViaje: fechaFinViaje ?? this.fechaFinViaje,
      precioEstimado: precioEstimado ?? this.precioEstimado,
      idPaquete: idPaquete ?? this.idPaquete,
      idDestino: idDestino ?? this.idDestino,
      precioDestino: precioDestino ?? this.precioDestino,
      idCliente: idCliente ?? this.idCliente,
      idEmpleado: idEmpleado ?? this.idEmpleado,
      empleadoNombre: empleadoNombre ?? this.empleadoNombre,
      empleadoApellido: empleadoApellido ?? this.empleadoApellido,
      estado: estado ?? this.estado,
      acompanantes: acompanantes ?? this.acompanantes,
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

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}
