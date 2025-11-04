enum AuditAction {
  // Acciones de usuarios
  crearUsuario('Crear usuario'),
  editarUsuario('Editar usuario'),
  eliminarUsuario('Eliminar usuario'),
  cambiarContrasena('Cambiar contraseña'),
  
  // Acciones de clientes
  crearCliente('Crear cliente'),
  editarCliente('Editar cliente'),
  eliminarCliente('Eliminar cliente'),
  
  // Acciones de cotizaciones
  crearCotizacion('Crear cotización'),
  editarCotizacion('Editar cotización'),
  eliminarCotizacion('Eliminar cotización'),
  
  // Acciones de reservas
  crearReserva('Crear reserva'),
  editarReserva('Editar reserva'),
  eliminarReserva('Eliminar reserva'),
  
  // Acciones de pagos
  registrarPago('Registrar pago'),
  editarPago('Editar pago'),
  eliminarPago('Eliminar pago'),
  
  // Acciones de paquetes
  crearPaquete('Crear paquete'),
  editarPaquete('Editar paquete'),
  eliminarPaquete('Eliminar paquete'),
  
  // Acciones de destinos
  crearDestino('Crear destino'),
  editarDestino('Editar destino'),
  eliminarDestino('Eliminar destino'),
  
  // Acciones de contactos
  crearContacto('Crear contacto'),
  editarContacto('Editar contacto'),
  eliminarContacto('Eliminar contacto'),
  
  // Acciones de proveedores
  crearProveedor('Crear proveedor'),
  editarProveedor('Editar proveedor'),
  eliminarProveedor('Eliminar proveedor');

  const AuditAction(this.displayName);
  final String displayName;
}

enum AuditCategory {
  administrador('Administrador'),
  asesor('Asesor');

  const AuditCategory(this.displayName);
  final String displayName;
}

class AuditLog {
  final int? idLog;
  final int idUsuario;
  final String nombreUsuario; // Nombre completo del usuario que realizó la acción
  final String rolUsuario; // Rol del usuario (administrador/empleado)
  final AuditAction accion;
  final AuditCategory categoria;
  final String entidad; // Tipo de entidad afectada (Usuario, Cliente, Cotización, etc.)
  final int? idEntidad; // ID de la entidad afectada
  final String? nombreEntidad; // Nombre o identificador de la entidad
  final String? detalles; // Detalles adicionales del cambio (JSON)
  final DateTime fechaHora;

  AuditLog({
    this.idLog,
    required this.idUsuario,
    required this.nombreUsuario,
    required this.rolUsuario,
    required this.accion,
    required this.categoria,
    required this.entidad,
    this.idEntidad,
    this.nombreEntidad,
    this.detalles,
    required this.fechaHora,
  });

  // Convertir de Map a AuditLog
  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      idLog: map['id_log'] as int?,
      idUsuario: map['id_usuario'] as int,
      nombreUsuario: map['nombre_usuario'] as String,
      rolUsuario: map['rol_usuario'] as String,
      accion: AuditAction.values.firstWhere(
        (e) => e.name == map['accion'],
        orElse: () => AuditAction.crearUsuario,
      ),
      categoria: AuditCategory.values.firstWhere(
        (e) => e.name == map['categoria'],
        orElse: () => AuditCategory.asesor,
      ),
      entidad: map['entidad'] as String,
      idEntidad: map['id_entidad'] as int?,
      nombreEntidad: map['nombre_entidad'] as String?,
      detalles: map['detalles'] as String?,
      fechaHora: DateTime.parse(map['fecha_hora'] as String),
    );
  }

  // Convertir de AuditLog a Map
  Map<String, dynamic> toMap() {
    return {
      'id_log': idLog,
      'id_usuario': idUsuario,
      'nombre_usuario': nombreUsuario,
      'rol_usuario': rolUsuario,
      'accion': accion.name,
      'categoria': categoria.name,
      'entidad': entidad,
      'id_entidad': idEntidad,
      'nombre_entidad': nombreEntidad,
      'detalles': detalles,
      'fecha_hora': fechaHora.toIso8601String(),
    };
  }

  // Crear copia con modificaciones
  AuditLog copyWith({
    int? idLog,
    int? idUsuario,
    String? nombreUsuario,
    String? rolUsuario,
    AuditAction? accion,
    AuditCategory? categoria,
    String? entidad,
    int? idEntidad,
    String? nombreEntidad,
    String? detalles,
    DateTime? fechaHora,
  }) {
    return AuditLog(
      idLog: idLog ?? this.idLog,
      idUsuario: idUsuario ?? this.idUsuario,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      rolUsuario: rolUsuario ?? this.rolUsuario,
      accion: accion ?? this.accion,
      categoria: categoria ?? this.categoria,
      entidad: entidad ?? this.entidad,
      idEntidad: idEntidad ?? this.idEntidad,
      nombreEntidad: nombreEntidad ?? this.nombreEntidad,
      detalles: detalles ?? this.detalles,
      fechaHora: fechaHora ?? this.fechaHora,
    );
  }
}
