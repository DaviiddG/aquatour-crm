import 'package:equatable/equatable.dart';

enum ReservationStatus {
  pendiente('Pendiente'),
  confirmada('Confirmada'),
  cancelada('Cancelada');

  const ReservationStatus(this.displayName);
  final String displayName;

  static ReservationStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'confirmada':
        return ReservationStatus.confirmada;
      case 'cancelada':
        return ReservationStatus.cancelada;
      default:
        return ReservationStatus.pendiente;
    }
  }
}

enum PaymentStatus {
  pendiente('Pendiente', 0xFFFF9800), // Naranja
  parcial('Pago Parcial', 0xFF2196F3), // Azul
  pagada('Pagada', 0xFF4CAF50); // Verde

  const PaymentStatus(this.displayName, this.colorValue);
  final String displayName;
  final int colorValue;

  static PaymentStatus fromAmounts(double totalPagado, double totalReserva) {
    if (totalPagado <= 0) {
      return PaymentStatus.pendiente;
    } else if (totalPagado >= totalReserva) {
      return PaymentStatus.pagada;
    } else {
      return PaymentStatus.parcial;
    }
  }
}

class Reservation extends Equatable {
  const Reservation({
    this.id,
    this.fechaReserva,
    required this.estado,
    required this.cantidadPersonas,
    required this.totalPago,
    required this.fechaInicioViaje,
    required this.fechaFinViaje,
    required this.idCliente,
    this.idPaquete,
    this.idDestino,
    this.precioDestino,
    required this.idEmpleado,
    this.empleadoNombre,
    this.empleadoApellido,
    this.notas,
    this.totalPagado = 0,
  });

  final int? id;
  final DateTime? fechaReserva;
  final ReservationStatus estado;
  final int cantidadPersonas;
  final double totalPago;
  final DateTime fechaInicioViaje;
  final DateTime fechaFinViaje;
  final int idCliente;
  final int? idPaquete;
  final int? idDestino;
  final double? precioDestino;
  final int idEmpleado;
  final String? empleadoNombre;
  final String? empleadoApellido;
  final String? notas;
  final double totalPagado;

  // Calcula el estado de pago basado en los montos
  PaymentStatus get paymentStatus => PaymentStatus.fromAmounts(totalPagado, totalPago);
  
  // Nombre completo del empleado
  String get empleadoNombreCompleto {
    if (empleadoNombre != null && empleadoApellido != null) {
      return '$empleadoNombre $empleadoApellido';
    }
    return 'Usuario Inactivo #$idEmpleado';
  }

  Reservation copyWith({
    int? id,
    DateTime? fechaReserva,
    ReservationStatus? estado,
    int? cantidadPersonas,
    double? totalPago,
    DateTime? fechaInicioViaje,
    DateTime? fechaFinViaje,
    int? idCliente,
    int? idPaquete,
    int? idDestino,
    double? precioDestino,
    int? idEmpleado,
    String? empleadoNombre,
    String? empleadoApellido,
    String? notas,
    double? totalPagado,
  }) {
    return Reservation(
      id: id ?? this.id,
      fechaReserva: fechaReserva ?? this.fechaReserva,
      estado: estado ?? this.estado,
      cantidadPersonas: cantidadPersonas ?? this.cantidadPersonas,
      totalPago: totalPago ?? this.totalPago,
      fechaInicioViaje: fechaInicioViaje ?? this.fechaInicioViaje,
      fechaFinViaje: fechaFinViaje ?? this.fechaFinViaje,
      idCliente: idCliente ?? this.idCliente,
      idPaquete: idPaquete ?? this.idPaquete,
      idDestino: idDestino ?? this.idDestino,
      precioDestino: precioDestino ?? this.precioDestino,
      idEmpleado: idEmpleado ?? this.idEmpleado,
      empleadoNombre: empleadoNombre ?? this.empleadoNombre,
      empleadoApellido: empleadoApellido ?? this.empleadoApellido,
      notas: notas ?? this.notas,
      totalPagado: totalPagado ?? this.totalPagado,
    );
  }

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: _parseInt(map['id'] ?? map['id_reserva']),
      fechaReserva: _parseDate(map['fechaReserva'] ?? map['fecha_reserva']),
      estado: ReservationStatus.fromString(map['estado']?.toString() ?? 'pendiente'),
      cantidadPersonas: _parseInt(map['cantidadPersonas'] ?? map['cantidad_personas']) ?? 1,
      totalPago: _parseDouble(map['totalPago'] ?? map['total_pago']) ?? 0,
      fechaInicioViaje: _parseDate(map['fechaInicioViaje'] ?? map['fecha_inicio_viaje']) ?? DateTime.now(),
      fechaFinViaje: _parseDate(map['fechaFinViaje'] ?? map['fecha_fin_viaje']) ?? DateTime.now(),
      idCliente: _parseInt(map['idCliente'] ?? map['id_cliente']) ?? 0,
      idPaquete: _parseInt(map['idPaquete'] ?? map['id_paquete']),
      idDestino: _parseInt(map['idDestino'] ?? map['id_destino']),
      precioDestino: _parseDouble(map['precioDestino'] ?? map['precio_destino']),
      idEmpleado: _parseInt(map['idEmpleado'] ?? map['id_empleado']) ?? 0,
      empleadoNombre: map['empleadoNombre']?.toString(),
      empleadoApellido: map['empleadoApellido']?.toString(),
      notas: map['notas']?.toString(),
      totalPagado: _parseDouble(map['totalPagado'] ?? map['total_pagado']) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fechaReserva': fechaReserva?.toIso8601String(),
      'estado': estado.name,
      'cantidad_personas': cantidadPersonas,
      'total_pago': totalPago,
      'fecha_inicio_viaje': fechaInicioViaje.toIso8601String(),
      'fecha_fin_viaje': fechaFinViaje.toIso8601String(),
      'id_cliente': idCliente,
      'id_paquete': idPaquete,
      'id_destino': idDestino,
      'precio_destino': precioDestino,
      'id_empleado': idEmpleado,
      'notas': notas,
    };
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
    return DateTime.tryParse(value.toString());
  }

  @override
  List<Object?> get props => [
        id,
        fechaReserva,
        estado,
        cantidadPersonas,
        totalPago,
        empleadoNombre,
        empleadoApellido,
        fechaInicioViaje,
        fechaFinViaje,
        idCliente,
        idPaquete,
        idEmpleado,
        notas,
        totalPagado,
      ];
}
