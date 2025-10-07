import 'package:aquatour/models/user.dart';
import 'package:aquatour/services/storage_service.dart';

class AuthService {
  final StorageService _storage = StorageService();

  Future<UserRole> getCurrentUserRole() async {
    try {
      final currentUser = await _storage.getCurrentUser();
      if (currentUser != null) {
        return currentUser.rol;
      }
      return UserRole.empleado;
    } catch (e) {
      print('❌ Error obteniendo rol del usuario actual: $e');
      return UserRole.empleado;
    }
  }

  Future<String?> getCurrentUserId() async {
    try {
      final currentUser = await _storage.getCurrentUser();
      final id = currentUser?.idUsuario;
      return id?.toString();
    } catch (e) {
      print('❌ Error obteniendo ID del usuario actual: $e');
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final userId = await getCurrentUserId();
      return userId != null && userId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final user = await _storage.login(email, password);
      return user != null;
    } catch (e) {
      print('❌ Error durante el login: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _storage.logout();
    } catch (e) {
      print('❌ Error durante el logout: $e');
    }
  }
}
