import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/contact.dart';
import '../models/user.dart';
import 'api_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final ApiService _apiService = ApiService();

  // Token de autenticación actual
  String? _authToken;
  User? _currentUser;

  // Configurar token de autenticación
  void setAuthToken(String token) {
    _authToken = token;
  }

  // Limpiar token de autenticación
  void clearAuthToken() {
    _authToken = null;
    _currentUser = null;
  }

  // Inicializar datos (ya no necesario con API, pero mantenemos para compatibilidad)
  Future<void> initializeData() async {
    try {
      print('✅ API Service inicializado - listo para conectarse con backend Python');
      // Aquí podríamos hacer alguna inicialización si es necesario
    } catch (e) {
      print('⚠️ Error inicializando API Service: $e');
    }
  }

  // ===== AUTENTICACIÓN =====

  Future<User?> login(String email, String password) async {
    print('--- 🚀 Intentando iniciar sesión ---');
    print('📧 Email: $email');

    try {
      final response = await _apiService.login(email, password);
      print('✅ Login exitoso en API');

      final token = response['access_token'] as String?;
      final userData = response['user'] as Map<String, dynamic>? ?? response as Map<String, dynamic>?;

      if (token != null) {
        _authToken = token;
      }

      if (userData != null) {
        _currentUser = User.fromMap(userData);
        print('👤 Usuario autenticado: ${_currentUser!.nombreCompleto}');
        return _currentUser;
      }

      print('❌ Respuesta de login incompleta');
      return null;
    } catch (e) {
      print('❌ Error en login: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      if (_authToken != null) {
        await _apiService.logout(_authToken);
      }
      clearAuthToken();
      print('✅ Logout exitoso');
    } catch (e) {
      print('⚠️ Error en logout: $e');
      // Aun así limpiamos el estado local
      clearAuthToken();
    }
  }

  User? get currentUser => _currentUser;

  Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    // Si tenemos token pero no usuario, podríamos verificar el token
    if (_authToken != null) {
      try {
        final response = await _apiService.verifyToken(_authToken!);
        final userData = response['user'] as Map<String, dynamic>?;
        if (userData != null) {
          _currentUser = User.fromMap(userData);
          return _currentUser;
        }
      } catch (e) {
        print('⚠️ Error verificando token: $e');
        clearAuthToken();
      }
    }

    return null;
  }

  // ===== USUARIOS =====

  Future<List<User>> getAllUsers() async {
    try {
      final usersData = await _apiService.getUsers(_authToken);
      return usersData.map((userMap) => User.fromMap(userMap as Map<String, dynamic>)).toList();
    } catch (e) {
      print('❌ Error obteniendo usuarios: $e');
      return [];
    }
  }

  Future<int> insertUser(User user) async {
    try {
      final response = await _apiService.createUser(user.toMap(), _authToken);
      final newId = response['id'] ?? response['id_usuario'];
      print('✅ Usuario creado con ID: $newId');
      return newId as int;
    } catch (e) {
      print('❌ Error creando usuario: $e');
      rethrow;
    }
  }

  Future<bool> updateUser(User user) async {
    try {
      await _apiService.updateUser(user.idUsuario!, user.toMap(), _authToken);
      print('✅ Usuario actualizado: ${user.nombreCompleto}');
      return true;
    } catch (e) {
      print('❌ Error actualizando usuario: $e');
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      await _apiService.deleteUser(id, _authToken);
      print('✅ Usuario eliminado: ID $id');
      return true;
    } catch (e) {
      print('❌ Error eliminando usuario: $e');
      return false;
    }
  }

  Future<bool> emailExists(String email, {int? excludeUserId}) async {
    try {
      final response = await _apiService.checkEmailExists(email, token: _authToken);
      return response['exists'] ?? false;
    } catch (e) {
      print('❌ Error verificando email: $e');
      return false;
    }
  }

  // ===== CONTACTOS =====

  Future<List<Contact>> getAllContacts() async {
    try {
      final contactsData = await _apiService.getContacts(_authToken);
      return contactsData.map((contactMap) => Contact.fromMap(contactMap as Map<String, dynamic>)).toList();
    } catch (e) {
      print('❌ Error obteniendo contactos: $e');
      return [];
    }
  }

  Future<int> insertContact(Contact contact) async {
    try {
      final response = await _apiService.createContact(contact.toMap(), _authToken);
      final newId = response['id'];
      print('✅ Contacto creado con ID: $newId');
      return newId as int;
    } catch (e) {
      print('❌ Error creando contacto: $e');
      rethrow;
    }
  }

  Future<bool> updateContact(Contact contact) async {
    try {
      await _apiService.updateContact(contact.id!, contact.toMap(), _authToken);
      print('✅ Contacto actualizado: ${contact.name}');
      return true;
    } catch (e) {
      print('❌ Error actualizando contacto: $e');
      return false;
    }
  }

  Future<bool> deleteContact(int id) async {
    try {
      await _apiService.deleteContact(id, _authToken);
      print('✅ Contacto eliminado: ID $id');
      return true;
    } catch (e) {
      print('❌ Error eliminando contacto: $e');
      return false;
    }
  }

  // ===== DASHBOARD Y ESTADÍSTICAS =====

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      return await _apiService.getDashboardStats(_authToken);
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      return {};
    }
  }

  // ===== INDICADORES DE DESEMPEÑO =====

  /// Obtiene métricas de rendimiento específicas para un usuario
  /// Incluye ventas completadas, reservas confirmadas y cotizaciones aceptadas
  Future<Map<String, dynamic>> getPerformanceMetrics(int userId) async {
    try {
      // En producción, esto vendría de la API
      // Por ahora, generamos datos simulados basados en el userId
      final metrics = await _generateMockPerformanceData(userId);
      print('📊 Métricas obtenidas para usuario $userId');
      return metrics;
    } catch (e) {
      print('❌ Error obteniendo métricas de desempeño: $e');
      return _getDefaultMetrics();
    }
  }

  /// Genera datos simulados de rendimiento basados en el ID del usuario
  Future<Map<String, dynamic>> _generateMockPerformanceData(int userId) async {
    // Usamos el userId como semilla para generar datos consistentes pero únicos
    final seed = userId.hashCode;

    // Ventas del último mes (completadas vs totales)
    final totalSales = (seed % 15) + 5; // 5-20 ventas
    final completedSales = (totalSales * 0.7).round(); // ~70% completadas
    final totalRevenue = completedSales * 450.0 + (totalSales - completedSales) * 150.0; // Precios simulados

    // Reservas (confirmadas vs pendientes)
    final totalReservations = (seed % 12) + 3; // 3-15 reservas
    final confirmedReservations = (totalReservations * 0.8).round(); // ~80% confirmadas

    // Cotizaciones (aceptadas vs totales)
    final totalQuotes = (seed % 10) + 2; // 2-12 cotizaciones
    final acceptedQuotes = (totalQuotes * 0.6).round(); // ~60% aceptadas

    return {
      'sales': {
        'total': totalSales,
        'completed': completedSales,
        'totalRevenue': totalRevenue,
        'averageSale': totalRevenue / totalSales,
      },
      'reservations': {
        'total': totalReservations,
        'confirmed': confirmedReservations,
        'pending': totalReservations - confirmedReservations,
      },
      'quotes': {
        'total': totalQuotes,
        'accepted': acceptedQuotes,
        'conversionRate': acceptedQuotes / totalQuotes,
      },
      'period': 'Último mes',
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Métricas por defecto en caso de error
  Map<String, dynamic> _getDefaultMetrics() {
    return {
      'sales': {
        'total': 0,
        'completed': 0,
        'totalRevenue': 0.0,
        'averageSale': 0.0,
      },
      'reservations': {
        'total': 0,
        'confirmed': 0,
        'pending': 0,
      },
      'quotes': {
        'total': 0,
        'accepted': 0,
        'conversionRate': 0.0,
      },
      'period': 'Sin datos',
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  // ===== UTILIDADES =====

  // Limpiar todos los datos locales (para compatibilidad)
  Future<void> clearAllData() async {
    try {
      clearAuthToken();
      print('🗑️ Estado local limpiado');
    } catch (e) {
      print('❌ Error limpiando datos: $e');
    }
  }

  // Verificar conectividad con la API
  Future<bool> testConnection() async {
    try {
      // Intentar hacer una petición simple (como verificar token si existe)
      if (_authToken != null) {
        await _apiService.verifyToken(_authToken!);
      } else {
        // Si no hay token, podríamos hacer un ping a un endpoint público
        // Por ahora, solo verificamos que la URL base sea accesible
        print('ℹ️ API Base URL: ${ApiService.baseUrl}');
      }
      return true;
    } catch (e) {
      print('❌ Error de conectividad con API: $e');
      return false;
    }
  }
}
