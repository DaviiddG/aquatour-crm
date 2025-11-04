class AccessLog {
  final int? id;
  final int idUsuario;
  final String nombreUsuario;
  final String rolUsuario;
  final DateTime fechaHoraIngreso;
  final DateTime? fechaHoraSalida;
  final String? duracionSesion; // En formato "2h 30m"
  final String ipAddress;
  final String? navegador;
  final String? sistemaOperativo;

  AccessLog({
    this.id,
    required this.idUsuario,
    required this.nombreUsuario,
    required this.rolUsuario,
    required this.fechaHoraIngreso,
    this.fechaHoraSalida,
    this.duracionSesion,
    required this.ipAddress,
    this.navegador,
    this.sistemaOperativo,
  });

  factory AccessLog.fromMap(Map<String, dynamic> map) {
    return AccessLog(
      id: map['id_log'] ?? map['id'],
      idUsuario: map['id_usuario'],
      nombreUsuario: map['nombre_usuario'] ?? '',
      rolUsuario: map['rol_usuario'] ?? '',
      fechaHoraIngreso: DateTime.parse(map['fecha_hora_ingreso']),
      fechaHoraSalida: map['fecha_hora_salida'] != null 
          ? DateTime.parse(map['fecha_hora_salida'])
          : null,
      duracionSesion: map['duracion_sesion'],
      ipAddress: map['ip_address'] ?? '',
      navegador: map['navegador'],
      sistemaOperativo: map['sistema_operativo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id_log': id,
      'id_usuario': idUsuario,
      'nombre_usuario': nombreUsuario,
      'rol_usuario': rolUsuario,
      'fecha_hora_ingreso': fechaHoraIngreso.toIso8601String(),
      if (fechaHoraSalida != null) 'fecha_hora_salida': fechaHoraSalida!.toIso8601String(),
      if (duracionSesion != null) 'duracion_sesion': duracionSesion,
      'ip_address': ipAddress,
      if (navegador != null) 'navegador': navegador,
      if (sistemaOperativo != null) 'sistema_operativo': sistemaOperativo,
    };
  }

  // Calcular duración de sesión
  String? calcularDuracion() {
    if (fechaHoraSalida == null) return 'En sesión';
    
    final duration = fechaHoraSalida!.difference(fechaHoraIngreso);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
