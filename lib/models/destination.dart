import 'package:equatable/equatable.dart';

class Destination extends Equatable {
  const Destination({
    this.id,
    required this.ciudad,
    required this.pais,
    this.descripcion,
    this.climaPromedio,
    this.temporadaAlta,
    this.idiomaPrincipal,
    this.moneda,
    this.precioBase,
    this.idProveedor,
  });

  final int? id;
  final String ciudad;
  final String pais;
  final String? descripcion;
  final String? climaPromedio;
  final String? temporadaAlta;
  final String? idiomaPrincipal;
  final String? moneda;
  final double? precioBase;
  final int? idProveedor;

  Destination copyWith({
    int? id,
    String? ciudad,
    String? pais,
    String? descripcion,
    String? climaPromedio,
    String? temporadaAlta,
    String? idiomaPrincipal,
    String? moneda,
    double? precioBase,
    int? idProveedor,
  }) {
    return Destination(
      id: id ?? this.id,
      ciudad: ciudad ?? this.ciudad,
      pais: pais ?? this.pais,
      descripcion: descripcion ?? this.descripcion,
      climaPromedio: climaPromedio ?? this.climaPromedio,
      temporadaAlta: temporadaAlta ?? this.temporadaAlta,
      idiomaPrincipal: idiomaPrincipal ?? this.idiomaPrincipal,
      moneda: moneda ?? this.moneda,
      precioBase: precioBase ?? this.precioBase,
      idProveedor: idProveedor ?? this.idProveedor,
    );
  }

  factory Destination.fromMap(Map<String, dynamic> map) {
    return Destination(
      id: _parseInt(map['id'] ?? map['id_destino']),
      ciudad: map['ciudad']?.toString() ?? '',
      pais: map['pais']?.toString() ?? '',
      descripcion: map['descripcion']?.toString(),
      climaPromedio: map['climaPromedio']?.toString() ?? map['clima_promedio']?.toString(),
      temporadaAlta: map['temporadaAlta']?.toString() ?? map['temporada_alta']?.toString(),
      idiomaPrincipal: map['idiomaPrincipal']?.toString() ?? map['idioma_principal']?.toString(),
      moneda: map['moneda']?.toString(),
      precioBase: _parseDouble(map['precioBase'] ?? map['precio_base']),
      idProveedor: _parseInt(map['idProveedor'] ?? map['id_proveedor']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ciudad': ciudad,
      'pais': pais,
      'descripcion': descripcion,
      'clima_promedio': climaPromedio,
      'temporada_alta': temporadaAlta,
      'idioma_principal': idiomaPrincipal,
      'moneda': moneda,
      'precio_base': precioBase,
      'id_proveedor': idProveedor,
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

  @override
  List<Object?> get props => [
        id,
        ciudad,
        pais,
        descripcion,
        climaPromedio,
        temporadaAlta,
        idiomaPrincipal,
        moneda,
        precioBase,
        idProveedor,
      ];
}
