import 'package:equatable/equatable.dart';

class Client extends Equatable {
  const Client({
    this.id,
    required this.nombreCompleto,
    required this.email,
    required this.telefono,
    required this.ciudad,
    required this.pais,
    this.fechaNacimiento,
    required this.fuente,
    required this.interes,
    this.observaciones,
    required this.fechaRegistro,
    required this.idEmpleado,
    this.satisfaccion,
    this.estadoCivil,
    this.idContactoOrigen,
    this.tipoFuenteDirecta,
  });

  final int? id;
  final String nombreCompleto;
  final String email;
  final String telefono;
  final String ciudad;
  final String pais;
  final DateTime? fechaNacimiento;
  final String fuente;
  final String interes;
  final String? observaciones;
  final DateTime fechaRegistro;
  final int idEmpleado;
  final int? satisfaccion;
  final String? estadoCivil;
  final int? idContactoOrigen; // ID del contacto si viene de un contacto
  final String? tipoFuenteDirecta; // Tipo de fuente si no viene de contacto (Web, Redes, Email, WhatsApp)

  Client copyWith({
    int? id,
    String? nombreCompleto,
    String? email,
    String? telefono,
    String? ciudad,
    String? pais,
    DateTime? fechaNacimiento,
    String? fuente,
    String? interes,
    String? observaciones,
    DateTime? fechaRegistro,
    int? idEmpleado,
    int? satisfaccion,
    String? estadoCivil,
    int? idContactoOrigen,
    String? tipoFuenteDirecta,
  }) {
    return Client(
      id: id ?? this.id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      ciudad: ciudad ?? this.ciudad,
      pais: pais ?? this.pais,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      fuente: fuente ?? this.fuente,
      interes: interes ?? this.interes,
      observaciones: observaciones ?? this.observaciones,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      idEmpleado: idEmpleado ?? this.idEmpleado,
      satisfaccion: satisfaccion ?? this.satisfaccion,
      estadoCivil: estadoCivil ?? this.estadoCivil,
      idContactoOrigen: idContactoOrigen ?? this.idContactoOrigen,
      tipoFuenteDirecta: tipoFuenteDirecta ?? this.tipoFuenteDirecta,
    );
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: _parseInt(map['id'] ?? map['id_cliente']),
      nombreCompleto: map['nombreCompleto']?.toString() ?? map['nombre']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      telefono: map['telefono']?.toString() ?? '',
      ciudad: map['ciudad']?.toString() ?? '',
      pais: map['pais']?.toString() ?? map['nacionalidad']?.toString() ?? '',
      fechaNacimiento: _parseDate(map['fechaNacimiento'] ?? map['fecha_nacimiento']),
      fuente: map['fuente']?.toString() ?? 'Referencia',
      interes: map['interes']?.toString() ?? map['preferencias_viaje']?.toString() ?? 'Cotización',
      observaciones: map['observaciones']?.toString(),
      fechaRegistro: _parseDate(map['fechaRegistro'] ?? map['fecha_registro']) ?? DateTime.now(),
      idEmpleado: _parseInt(map['idEmpleado'] ?? map['id_empleado'] ?? map['id_usuario']) ?? 0,
      satisfaccion: _parseInt(map['satisfaccion']),
      estadoCivil: map['estadoCivil']?.toString() ?? map['estado_civil']?.toString(),
      idContactoOrigen: _parseInt(map['idContactoOrigen'] ?? map['id_contacto_origen']),
      tipoFuenteDirecta: map['tipoFuenteDirecta']?.toString() ?? map['tipo_fuente_directa']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombreCompleto': nombreCompleto,
      'email': email,
      'telefono': telefono,
      'ciudad': ciudad,
      'pais': pais,
      'fechaNacimiento': fechaNacimiento?.toIso8601String(),
      'fuente': fuente,
      'interes': interes,
      'observaciones': observaciones,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'id_empleado': idEmpleado,
      'id_contacto_origen': idContactoOrigen,
      'tipo_fuente_directa': tipoFuenteDirecta,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  @override
  List<Object?> get props => [
        id,
        nombreCompleto,
        email,
        telefono,
        ciudad,
        pais,
        fechaNacimiento,
        fuente,
        interes,
        observaciones,
        fechaRegistro,
        idEmpleado,
        satisfaccion,
        estadoCivil,
        idContactoOrigen,
        tipoFuenteDirecta,
      ];
}
