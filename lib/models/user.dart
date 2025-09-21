enum UserRole {
  empleado('Empleado'),
  administrador('Administrador'),
  superadministrador('Superadministrador');

  const UserRole(this.displayName);
  final String displayName;
}

class User {
  final int? idUsuario;
  final String nombre;
  final String apellido;
  final String email; // Email para login
  final UserRole rol; // Rol del usuario
  final String tipoDocumento;
  final String numDocumento;
  final DateTime fechaNacimiento;
  final String genero;
  final String telefono;
  final String direccion;
  final String ciudadResidencia;
  final String paisResidencia;
  final String contrasena;
  final bool activo; // Estado del usuario
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    this.idUsuario,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.rol,
    required this.tipoDocumento,
    required this.numDocumento,
    required this.fechaNacimiento,
    required this.genero,
    required this.telefono,
    required this.direccion,
    required this.ciudadResidencia,
    required this.paisResidencia,
    required this.contrasena,
    this.activo = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convertir de Map a User
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      idUsuario: map['id_usuario'] is int ? map['id_usuario'] : int.tryParse(map['id_usuario'].toString()),
      nombre: map['nombre']?.toString() ?? '',
      apellido: map['apellido']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      rol: _parseRole(map['rol']?.toString() ?? 'empleado'),
      tipoDocumento: map['tipo_documento']?.toString() ?? '',
      numDocumento: map['num_documento']?.toString() ?? '',
      fechaNacimiento: map['fecha_nacimiento'] is DateTime 
          ? map['fecha_nacimiento'] 
          : DateTime.tryParse(map['fecha_nacimiento']?.toString() ?? '') ?? DateTime.now(),
      genero: map['genero']?.toString() ?? '',
      telefono: map['telefono']?.toString() ?? '',
      direccion: map['direccion']?.toString() ?? '',
      ciudadResidencia: map['ciudad_residencia']?.toString() ?? '',
      paisResidencia: map['pais_residencia']?.toString() ?? '',
      contrasena: map['contrasena']?.toString() ?? '',
      activo: map['activo'] == true || map['activo'] == 1 || map['activo']?.toString() == 'true',
      createdAt: map['created_at'] is DateTime 
          ? map['created_at'] 
          : DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: map['updated_at'] is DateTime 
          ? map['updated_at'] 
          : DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static UserRole _parseRole(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'administrador':
        return UserRole.administrador;
      case 'superadministrador':
        return UserRole.superadministrador;
      default:
        return UserRole.empleado;
    }
  }

  // Convertir de User a Map
  Map<String, dynamic> toMap() {
    return {
      'id_usuario': idUsuario,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'rol': rol.name,
      'tipo_documento': tipoDocumento,
      'num_documento': numDocumento,
      'fecha_nacimiento': fechaNacimiento.toIso8601String(),
      'genero': genero,
      'telefono': telefono,
      'direccion': direccion,
      'ciudad_residencia': ciudadResidencia,
      'pais_residencia': paisResidencia,
      'contrasena': contrasena,
      'activo': activo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Crear copia con cambios
  User copyWith({
    int? idUsuario,
    String? nombre,
    String? apellido,
    String? email,
    UserRole? rol,
    String? tipoDocumento,
    String? numDocumento,
    DateTime? fechaNacimiento,
    String? genero,
    String? telefono,
    String? direccion,
    String? ciudadResidencia,
    String? paisResidencia,
    String? contrasena,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      idUsuario: idUsuario ?? this.idUsuario,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      numDocumento: numDocumento ?? this.numDocumento,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      genero: genero ?? this.genero,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      ciudadResidencia: ciudadResidencia ?? this.ciudadResidencia,
      paisResidencia: paisResidencia ?? this.paisResidencia,
      contrasena: contrasena ?? this.contrasena,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Nombre completo
  String get nombreCompleto => '$nombre $apellido';

  // Edad calculada
  int get edad {
    final now = DateTime.now();
    int age = now.year - fechaNacimiento.year;
    if (now.month < fechaNacimiento.month || 
        (now.month == fechaNacimiento.month && now.day < fechaNacimiento.day)) {
      age--;
    }
    return age;
  }

  // Verificar permisos
  bool get esAdministrador => rol == UserRole.administrador || rol == UserRole.superadministrador;
  bool get esSuperAdministrador => rol == UserRole.superadministrador;
  bool get esEmpleado => rol == UserRole.empleado;

  // Permisos específicos
  bool get puedeGestionarUsuarios => esAdministrador;
  bool get puedeVerTodosLosModulos => esAdministrador;
  bool get puedeEliminarDatos => esAdministrador;
  bool get puedeConfigurarSistema => esSuperAdministrador;

  @override
  String toString() {
    return 'User{id: $idUsuario, nombre: $nombreCompleto, email: $email, rol: ${rol.displayName}}';
  }
}
