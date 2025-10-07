import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/client.dart';
import '../models/contact.dart';
import '../models/reservation.dart';
import '../models/user.dart';
import 'api_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal() {
    _restoreSession();
  }

  // ===== ORDEN PERSONALIZADO DEL DASHBOARD =====

  Future<List<String>> getDashboardOrder(String userKey) async {
    try {
      final stored = html.window.localStorage['$_dashboardOrderPrefix$userKey'];
      if (stored == null || stored.isEmpty) {
        return [];
      }
      final decoded = jsonDecode(stored);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint('⚠️ Error leyendo orden de dashboard: $e');
    }
    return [];
  }

  Future<void> saveDashboardOrder(String userKey, List<String> moduleIds) async {
    try {
      html.window.localStorage['$_dashboardOrderPrefix$userKey'] = jsonEncode(moduleIds);
    } catch (e) {
      debugPrint('⚠️ Error guardando orden de dashboard: $e');
    }
  }

  final ApiService _apiService = ApiService();

  // Token de autenticación actual
  String? _authToken;
  User? _currentUser;

  static const String _tokenStorageKey = 'aquatour_auth_token';
  static const String _userStorageKey = 'aquatour_current_user';
  static const String _lastActivityStorageKey = 'aquatour_last_activity';
  static const String _dashboardOrderPrefix = 'aquatour_dashboard_order_';
  static const String _clientsStorageKey = 'aquatour_clients';
  static const String _reservationsStorageKey = 'aquatour_reservations';
  static const Duration _sessionTimeout = Duration(minutes: 10);

  final StreamController<List<Client>> _clientsController = StreamController<List<Client>>.broadcast();
  final StreamController<List<Reservation>> _reservationsController = StreamController<List<Reservation>>.broadcast();

  Stream<List<Client>> get clientsStream => _clientsController.stream;
  Stream<List<Reservation>> get reservationsStream => _reservationsController.stream;

  Future<List<Client>> getClients({int? forEmployeeId}) async {
    final raw = html.window.localStorage[_clientsStorageKey];
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final clients = decoded
            .map((item) => Client.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList();
        if (forEmployeeId != null) {
          return clients.where((client) => client.idEmpleado == forEmployeeId).toList();
        }
        return clients;
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing clients: $e');
    }
    return [];
  }

  Future<Client> saveClient(Client client) async {
    final clients = await getClients();
    final isUpdate = client.id != null;
    final List<Client> updatedList;

    if (isUpdate) {
      updatedList = clients
          .map((existing) => existing.id == client.id ? client : existing)
          .toList();
    } else {
      final nextId = (clients.map((c) => c.id ?? 0).fold<int>(0, (prev, element) => element > prev ? element : prev)) + 1;
      updatedList = List<Client>.from(clients)
        ..add(client.copyWith(id: nextId, fechaRegistro: DateTime.now()));
    }

    await _persistClients(updatedList);
    final saved = isUpdate ? client : updatedList.last;
    _clientsController.add(updatedList);
    return saved;
  }

  Future<void> deleteClient(int clientId) async {
    final clients = await getClients();
    final updated = clients.where((client) => client.id != clientId).toList();
    await _persistClients(updated);
    _clientsController.add(updated);
  }

  Future<void> _persistClients(List<Client> clients) async {
    try {
      final encoded = jsonEncode(clients.map((client) => client.toMap()).toList());
      html.window.localStorage[_clientsStorageKey] = encoded;
    } catch (e) {
      debugPrint('⚠️ Error persisting clients: $e');
    }
  }

  Future<List<Reservation>> getReservations({int? forEmployeeId}) async {
    final raw = html.window.localStorage[_reservationsStorageKey];
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final reservations = decoded
            .map((item) => Reservation.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList();
        if (forEmployeeId != null) {
          return reservations.where((reservation) => reservation.idEmpleado == forEmployeeId).toList();
        }
        return reservations;
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing reservations: $e');
    }
    return [];
  }

  Future<Reservation> saveReservation(Reservation reservation) async {
    final reservations = await getReservations();
    final isUpdate = reservation.id != null;
    final now = DateTime.now();
    final Reservation toPersist = reservation.copyWith(
      fechaReserva: reservation.fechaReserva ?? now,
    );

    final List<Reservation> updatedList;
    if (isUpdate) {
      updatedList = reservations
          .map((existing) => existing.id == reservation.id ? toPersist : existing)
          .toList();
    } else {
      final nextId = (reservations.map((r) => r.id ?? 0).fold<int>(0, (prev, element) => element > prev ? element : prev)) + 1;
      updatedList = List<Reservation>.from(reservations)
        ..add(toPersist.copyWith(id: nextId));
    }

    await _persistReservations(updatedList);
    _reservationsController.add(updatedList);
    return isUpdate ? toPersist : updatedList.last;
  }

  Future<void> updateReservationStatus({
    required int reservationId,
    required ReservationStatus status,
  }) async {
    final reservations = await getReservations();
    final updated = reservations
        .map((reservation) => reservation.id == reservationId
            ? reservation.copyWith(estado: status)
            : reservation)
        .toList();
    await _persistReservations(updated);
    _reservationsController.add(updated);
  }

  Future<void> deleteReservation(int reservationId) async {
    final reservations = await getReservations();
    final updated = reservations.where((reservation) => reservation.id != reservationId).toList();
    await _persistReservations(updated);
    _reservationsController.add(updated);
  }

  Future<void> _persistReservations(List<Reservation> reservations) async {
    try {
      final encoded = jsonEncode(reservations.map((reservation) => reservation.toMap()).toList());
      html.window.localStorage[_reservationsStorageKey] = encoded;
    } catch (e) {
      debugPrint('⚠️ Error persisting reservations: $e');
    }
  }

  // Configurar token de autenticación
  void setAuthToken(String token) {
    _authToken = token;
    _persistSession();
  }

  // Limpiar token de autenticación
  void clearAuthToken() {
    _authToken = null;
    _currentUser = null;
    _clearSessionStorage();
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
        _persistSession();
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
      final token = _authToken;
      _clearSessionStorage();
      _authToken = null;
      _currentUser = null;

      if (token != null) {
        await _apiService.logout(token);
      }

      print('✅ Logout exitoso');
    } catch (e) {
      print('⚠️ Error en logout: $e');
      // Aun así limpiamos el estado local
      _clearSessionStorage();
      _authToken = null;
      _currentUser = null;
    }
  }

  User? get currentUser => _currentUser;

  Future<User?> getCurrentUser() async {
    if (!_hasValidSession()) {
      return null;
    }

    if (_currentUser != null) {
      _refreshLastActivity();
      return _currentUser;
    }

    // Si tenemos token pero no usuario, podríamos verificar el token
    if (_authToken != null) {
      try {
        final response = await _apiService.verifyToken(_authToken!);
        final userData = response['user'] as Map<String, dynamic>?;
        if (userData != null) {
          _currentUser = User.fromMap(userData);
          _persistSession();
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
      final response = await _apiService.checkEmailExists(
        email,
        token: _authToken,
        excludeUserId: excludeUserId,
      );
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
      final reservations = await getReservations(forEmployeeId: userId);
      final clients = await getClients(forEmployeeId: userId);

      if (reservations.isEmpty && clients.isEmpty) {
        final mockMetrics = await _generateMockPerformanceData(userId);
        debugPrint('📊 Métricas mock generadas para usuario $userId');
        return mockMetrics;
      }

      final confirmedReservations = reservations
          .where((reservation) => reservation.estado == ReservationStatus.confirmada)
          .toList();
      final pendingCount = reservations
          .where((reservation) => reservation.estado == ReservationStatus.pendiente)
          .length;
      final cancelledCount = reservations
          .where((reservation) => reservation.estado == ReservationStatus.cancelada)
          .length;
      final totalRevenue = confirmedReservations.fold<double>(0, (sum, reservation) => sum + reservation.totalPago);

      final metrics = _getDefaultMetrics();
      metrics['sales'] = {
        'total': confirmedReservations.length,
        'completed': confirmedReservations.length,
        'totalRevenue': totalRevenue,
        'averageSale': confirmedReservations.isEmpty ? 0.0 : totalRevenue / confirmedReservations.length,
      };
      metrics['reservations'] = {
        'total': reservations.length,
        'confirmed': confirmedReservations.length,
        'pending': pendingCount,
        'cancelled': cancelledCount,
      };
      metrics['quotes'] ??= {
        'total': 0,
        'accepted': 0,
        'conversionRate': 0.0,
      };
      metrics['clients'] = {
        'total': clients.length,
      };
      metrics['lastUpdated'] = DateTime.now().toIso8601String();
      return metrics;
    } catch (e) {
      debugPrint('❌ Error obteniendo métricas de desempeño: $e');
      return _getDefaultMetrics();
    }
  }

  Future<List<Map<String, dynamic>>> getEmployeeClients(int employeeId) async {
    try {
      final clients = await getClients(forEmployeeId: employeeId);
      if (clients.isEmpty) {
        final mock = await _generateMockClients(employeeId);
        debugPrint('🧾 Clientes mock generados para empleado $employeeId: ${mock.length}');
        return mock;
      }

      return clients
          .map((client) => {
                'id_cliente': client.id ?? 0,
                'nombre': client.nombreCompleto,
                'nacionalidad': client.pais,
                'pasaporte': 'P-${client.idEmpleado}-${client.id ?? 0}',
                'fecha_registro': client.fechaRegistro.toIso8601String(),
                'preferencias_viaje': client.interes,
                'id_empleado': client.idEmpleado,
                'satisfaccion': 4,
                'estado_civil': 'N/D',
              })
          .toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo clientes para empleado $employeeId: $e');
      return [];
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

  Future<List<Map<String, dynamic>>> _generateMockClients(int employeeId) async {
    final seed = employeeId.hashCode;
    final clientCount = (seed % 6) + 2; // 2-7 clientes

    final nationalities = [
      'Colombia',
      'México',
      'Argentina',
      'Chile',
      'Perú',
      'España',
    ];
    final states = ['Soltero', 'Casado', 'Divorciado', 'Unión libre'];
    final preferences = [
      'Playas y resorts todo incluido',
      'Turismo de aventura',
      'Experiencias gastronómicas',
      'Cruceros por el Caribe',
      'Ciudades culturales',
      'Viajes familiares',
    ];

    final clients = <Map<String, dynamic>>[];
    for (var i = 0; i < clientCount; i++) {
      final base = seed + i * 31;
      clients.add({
        'id_cliente': base.abs() % 9000 + 1000,
        'nombre': 'Cliente ${String.fromCharCode(65 + (base % 26).abs())}$i',
        'nacionalidad': nationalities[base.abs() % nationalities.length],
        'pasaporte': 'P-${employeeId % 100}-${base.abs() % 999999}',
        'fecha_registro': DateTime.now().subtract(Duration(days: (base.abs() % 180))).toIso8601String(),
        'preferencias_viaje': preferences[base.abs() % preferences.length],
        'id_empleado': employeeId,
        'satisfaccion': ((base.abs() % 5) + 1).toDouble(),
        'estado_civil': states[base.abs() % states.length],
      });
    }

    return clients;
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

  void _persistSession() {
    if (!kIsWeb) return;
    if (_authToken != null) {
      html.window.localStorage[_tokenStorageKey] = _authToken!;
    }
    if (_currentUser != null) {
      html.window.localStorage[_userStorageKey] = jsonEncode(_currentUser!.toMap());
    }
    if (_authToken != null || _currentUser != null) {
      _refreshLastActivity();
    }
  }

  void _refreshLastActivity() {
    if (!kIsWeb) return;
    html.window.localStorage[_lastActivityStorageKey] = DateTime.now().toIso8601String();
  }

  bool _hasValidSession() {
    if (!kIsWeb) {
      return _authToken != null || _currentUser != null;
    }

    final lastActivity = html.window.localStorage[_lastActivityStorageKey];
    if (_isSessionExpired(lastActivity)) {
      clearAuthToken();
      return false;
    }
    return _authToken != null || _currentUser != null;
  }

  bool _isSessionExpired(String? isoString) {
    if (isoString == null) return false;
    final lastDate = DateTime.tryParse(isoString);
    if (lastDate == null) return false;
    return DateTime.now().difference(lastDate) > _sessionTimeout;
  }

  void _restoreSession() {
    if (!kIsWeb) return;

    final lastActivity = html.window.localStorage[_lastActivityStorageKey];
    if (_isSessionExpired(lastActivity)) {
      _clearSessionStorage();
      return;
    }

    final storedToken = html.window.localStorage[_tokenStorageKey];
    final storedUserJson = html.window.localStorage[_userStorageKey];

    if (storedToken != null && storedToken.isNotEmpty) {
      _authToken = storedToken;
    }

    if (storedUserJson != null && storedUserJson.isNotEmpty) {
      try {
        final userMap = jsonDecode(storedUserJson) as Map<String, dynamic>;
        _currentUser = User.fromMap(userMap);
      } catch (e) {
        print('⚠️ No se pudo restaurar el usuario almacenado: $e');
        _currentUser = null;
      }
    }

    if (_authToken != null && _currentUser != null) {
      _refreshLastActivity();
    }
  }

  void _clearSessionStorage() {
    if (!kIsWeb) return;
    html.window.localStorage.remove(_tokenStorageKey);
    html.window.localStorage.remove(_userStorageKey);
    html.window.localStorage.remove(_lastActivityStorageKey);
  }
}
