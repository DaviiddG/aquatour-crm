enum ProviderStatus {
  activo,
  inactivo;

  String get displayName {
    switch (this) {
      case ProviderStatus.activo:
        return 'Activo';
      case ProviderStatus.inactivo:
        return 'Inactivo';
    }
  }
}

class Provider {
  final int? id;
  final String nombre;
  final String tipoProveedor;
  final String telefono;
  final String correo;
  final ProviderStatus estado;

  Provider({
    this.id,
    required this.nombre,
    required this.tipoProveedor,
    required this.telefono,
    required this.correo,
    this.estado = ProviderStatus.activo,
  });

  factory Provider.fromMap(Map<String, dynamic> map) {
    ProviderStatus status = ProviderStatus.activo;
    final estadoStr = map['estado']?.toString().toLowerCase();
    if (estadoStr == 'inactivo') {
      status = ProviderStatus.inactivo;
    }

    return Provider(
      id: _parseInt(map['id'] ?? map['id_proveedor']),
      nombre: map['nombre']?.toString() ?? '',
      tipoProveedor: map['tipoProveedor'] ?? map['tipo_proveedor'] ?? '',
      telefono: map['telefono']?.toString() ?? '',
      correo: map['correo']?.toString() ?? '',
      estado: status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo_proveedor': tipoProveedor,
      'telefono': telefono,
      'correo': correo,
      'estado': estado.name,
    };
  }

  Provider copyWith({
    int? id,
    String? nombre,
    String? tipoProveedor,
    String? telefono,
    String? correo,
    ProviderStatus? estado,
  }) {
    return Provider(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipoProveedor: tipoProveedor ?? this.tipoProveedor,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      estado: estado ?? this.estado,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
