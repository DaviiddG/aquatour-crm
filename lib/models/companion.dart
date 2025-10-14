/// Modelo para representar un acompañante en una cotización
class Companion {
  final int? id;
  final String nombres;
  final String apellidos;
  final String? documento;
  final String? nacionalidad;
  final DateTime? fechaNacimiento;
  final bool esMenor;
  final int? idCotizacion;

  Companion({
    this.id,
    required this.nombres,
    required this.apellidos,
    this.documento,
    this.nacionalidad,
    this.fechaNacimiento,
    this.esMenor = false,
    this.idCotizacion,
  });

  /// Calcula la edad basándose en la fecha de nacimiento
  int? get edad {
    if (fechaNacimiento == null) return null;
    final now = DateTime.now();
    int age = now.year - fechaNacimiento!.year;
    if (now.month < fechaNacimiento!.month ||
        (now.month == fechaNacimiento!.month && now.day < fechaNacimiento!.day)) {
      age--;
    }
    return age;
  }

  /// Nombre completo del acompañante
  String get nombreCompleto => '$nombres $apellidos'.trim();

  factory Companion.fromMap(Map<String, dynamic> map) {
    return Companion(
      id: _parseInt(map['id'] ?? map['id_acompanante']),
      nombres: map['nombres']?.toString() ?? '',
      apellidos: map['apellidos']?.toString() ?? '',
      documento: map['documento']?.toString(),
      nacionalidad: map['nacionalidad']?.toString(),
      fechaNacimiento: _parseDate(map['fecha_nacimiento'] ?? map['fechaNacimiento']),
      esMenor: _parseBool(map['es_menor'] ?? map['esMenor']) ?? false,
      idCotizacion: _parseInt(map['id_cotizacion'] ?? map['idCotizacion']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nombres': nombres,
      'apellidos': apellidos,
      'documento': documento,
      'nacionalidad': nacionalidad,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String().split('T')[0],
      'es_menor': esMenor,
      if (idCotizacion != null) 'id_cotizacion': idCotizacion,
    };
  }

  Companion copyWith({
    int? id,
    String? nombres,
    String? apellidos,
    String? documento,
    String? nacionalidad,
    DateTime? fechaNacimiento,
    bool? esMenor,
    int? idCotizacion,
  }) {
    return Companion(
      id: id ?? this.id,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      documento: documento ?? this.documento,
      nacionalidad: nacionalidad ?? this.nacionalidad,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      esMenor: esMenor ?? this.esMenor,
      idCotizacion: idCotizacion ?? this.idCotizacion,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return null;
  }

  @override
  String toString() {
    return 'Companion{id: $id, nombreCompleto: $nombreCompleto, esMenor: $esMenor, edad: $edad}';
  }
}
