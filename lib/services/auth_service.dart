import 'package:aquatour/services/local_storage_service.dart';
import 'package:aquatour/models/user.dart';

class AuthService {
  final LocalStorageService _storage = LocalStorageService();

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
      return await _storage.getUserId();
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
      final user = await _storage.getUserByEmail(email);
      if (user != null && user.contrasena == password) {
        await _storage.saveCurrentUser(user.idUsuario.toString());
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error durante el login: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _storage.clearCurrentUser();
    } catch (e) {
      print('❌ Error durante el logout: $e');
    }
  }
}
