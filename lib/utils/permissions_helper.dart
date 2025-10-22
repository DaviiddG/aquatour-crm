import '../models/user.dart';

class PermissionsHelper {
  /// Verifica si el usuario puede crear destinos
  static bool canCreateDestinations(UserRole role) {
    return role == UserRole.administrador;
  }

  /// Verifica si el usuario puede crear paquetes turísticos
  static bool canCreatePackages(UserRole role) {
    return role == UserRole.administrador;
  }

  /// Verifica si el usuario puede crear contactos
  static bool canCreateContacts(UserRole role) {
    return role == UserRole.administrador || role == UserRole.empleado;
  }

  /// Verifica si el usuario puede crear clientes
  static bool canCreateClients(UserRole role) {
    return role == UserRole.administrador || role == UserRole.empleado;
  }

  /// Verifica si el usuario puede crear cotizaciones (solo empleados)
  static bool canCreateQuotes(UserRole role) {
    return role == UserRole.empleado;
  }

  /// Verifica si el usuario puede crear reservas
  static bool canCreateReservations(UserRole role) {
    return role == UserRole.administrador || role == UserRole.empleado;
  }

  /// Verifica si el usuario puede crear pagos
  static bool canCreatePayments(UserRole role) {
    return role == UserRole.administrador || role == UserRole.empleado;
  }

  /// Verifica si el usuario puede crear proveedores
  static bool canCreateProviders(UserRole role) {
    return role == UserRole.administrador;
  }

  /// Verifica si el usuario puede editar/eliminar (por defecto, si puede ver puede editar)
  static bool canModify(UserRole role) {
    return role == UserRole.administrador;
  }

  /// Verifica si el usuario tiene permisos de solo lectura
  static bool isReadOnly(UserRole role) {
    return role == UserRole.superadministrador;
  }
}
