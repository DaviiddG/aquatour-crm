class TourPackage {
  final int? id;
  final String nombre;
  final String? descripcion;
  final double precioBase;
  final int duracionDias;
  final int cupoMaximo;
  final String? serviciosIncluidos;
  final List<int> destinosIds; // Lista de IDs de destinos

  TourPackage({
    this.id,
    required this.nombre,
    this.descripcion,
    required this.precioBase,
    required this.duracionDias,
    required this.cupoMaximo,
    this.serviciosIncluidos,
    this.destinosIds = const [],
  });

  factory TourPackage.fromMap(Map<String, dynamic> map) {
    // Parsear destinos si vienen como string separado por comas
    List<int> destinos = [];
    if (map['destinos_ids'] != null) {
      if (map['destinos_ids'] is String) {
        destinos = (map['destinos_ids'] as String)
            .split(',')
            .where((s) => s.isNotEmpty)
            .map((s) => int.tryParse(s.trim()) ?? 0)
            .where((id) => id > 0)
            .toList();
      } else if (map['destinos_ids'] is List) {
        destinos = (map['destinos_ids'] as List).map((e) => int.tryParse(e.toString()) ?? 0).toList();
      }
    }

    return TourPackage(
      id: _parseInt(map['id'] ?? map['id_paquete']),
      nombre: map['nombre']?.toString() ?? '',
      descripcion: map['descripcion']?.toString(),
      precioBase: _parseDouble(map['precioBase'] ?? map['precio_base']) ?? 0.0,
      duracionDias: _parseInt(map['duracionDias'] ?? map['duracion_dias']) ?? 1,
      cupoMaximo: _parseInt(map['cupoMaximo'] ?? map['cupo_maximo']) ?? 1,
      serviciosIncluidos: map['serviciosIncluidos']?.toString() ?? map['servicios_incluidos']?.toString(),
      destinosIds: destinos,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio_base': precioBase,
      'duracion_dias': duracionDias,
      'cupo_maximo': cupoMaximo,
      'servicios_incluidos': serviciosIncluidos,
      'destinos_ids': destinosIds.join(','), // Guardar como string separado por comas
    };
  }

  TourPackage copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    double? precioBase,
    int? duracionDias,
    int? cupoMaximo,
    String? serviciosIncluidos,
    List<int>? destinosIds,
  }) {
    return TourPackage(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precioBase: precioBase ?? this.precioBase,
      duracionDias: duracionDias ?? this.duracionDias,
      cupoMaximo: cupoMaximo ?? this.cupoMaximo,
      serviciosIncluidos: serviciosIncluidos ?? this.serviciosIncluidos,
      destinosIds: destinosIds ?? this.destinosIds,
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
}
