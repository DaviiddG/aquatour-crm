import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../models/contact.dart';
import '../models/destination.dart';
import '../models/payment.dart';
import '../models/provider.dart';
import '../models/quote.dart';
import '../models/reservation.dart';
import '../models/tour_package.dart';
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
    try {
      final List<dynamic> clientsData;
      
      if (forEmployeeId != null) {
        clientsData = await _apiService.getClientsByUser(forEmployeeId, _authToken);
      } else {
        clientsData = await _apiService.getClients(_authToken);
      }
      
      return clientsData
          .map((clientMap) => Client.fromMap(clientMap as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo clientes: $e');
      return [];
    }
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


  // Configurar token de autenticación
  void setAuthToken(String token) {
    _authToken = token;
    _persistSession();
  }

  static Future<String?> getToken() async {
    return StorageService()._getToken();
  }

  Future<String?> _getToken() async {
    if (!_hasValidSession()) {
      return null;
    }

    if (_authToken != null) {
      _refreshLastActivity();
      return _authToken;
    }

    if (!kIsWeb) {
      return _authToken;
    }

    final storedToken = html.window.localStorage[_tokenStorageKey];
    if (storedToken != null && storedToken.isNotEmpty) {
      _authToken = storedToken;
      _refreshLastActivity();
      return storedToken;
    }

    return null;
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
      final Map<String, dynamic>? contactData =
          response['contact'] is Map<String, dynamic> ? response['contact'] as Map<String, dynamic> : null;
      final dynamic idValue = contactData?['id'] ?? response['id'];
      if (idValue == null) {
        throw Exception('La API no devolvió un ID para el contacto creado');
      }

      final int? newId = idValue is int ? idValue : int.tryParse(idValue.toString());
      if (newId == null) {
        throw Exception('ID de contacto inválido: $idValue');
      }

      print('✅ Contacto creado con ID: $newId');
      return newId;
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

  // ===== DESTINOS =====

  Future<List<Destination>> getDestinations() async {
    return getAllDestinations();
  }

  Future<List<Destination>> getAllDestinations() async {
    try {
      final destinationsData = await _apiService.getDestinations(_authToken);
      return destinationsData.map((destMap) => Destination.fromMap(destMap as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo destinos: $e');
      return [];
    }
  }

  Future<Destination> saveDestination(Destination destination) async {
    try {
      if (destination.id != null) {
        final response = await _apiService.updateDestination(destination.id!, destination.toMap(), _authToken);
        return Destination.fromMap(response['destination'] ?? response);
      } else {
        final response = await _apiService.createDestination(destination.toMap(), _authToken);
        return Destination.fromMap(response['destination'] ?? response);
      }
    } catch (e) {
      debugPrint('❌ Error guardando destino: $e');
      rethrow;
    }
  }

  Future<bool> deleteDestination(int id) async {
    try {
      await _apiService.deleteDestination(id, _authToken);
      return true;
    } catch (e) {
      debugPrint('❌ Error eliminando destino: $e');
      return false;
    }
  }

  // ===== RESERVAS =====

  Future<List<Reservation>> getAllReservations() async {
    try {
      final reservationsData = await _apiService.getReservations(_authToken);
      return reservationsData.map((resMap) => Reservation.fromMap(resMap as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo reservas: $e');
      return [];
    }
  }

  Future<List<Reservation>> getReservationsByEmployee(int idEmpleado) async {
    try {
      final reservationsData = await _apiService.getReservationsByEmployee(idEmpleado, _authToken);
      return reservationsData.map((resMap) => Reservation.fromMap(resMap as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo reservas del empleado: $e');
      return [];
    }
  }

  Future<Reservation> saveReservation(Reservation reservation) async {
    try {
      if (reservation.id != null) {
        final response = await _apiService.updateReservation(reservation.id!, reservation.toMap(), _authToken);
        return Reservation.fromMap(response['reservation'] ?? response);
      } else {
        final response = await _apiService.createReservation(reservation.toMap(), _authToken);
        return Reservation.fromMap(response['reservation'] ?? response);
      }
    } catch (e) {
      debugPrint('❌ Error guardando reserva: $e');
      rethrow;
    }
  }

  Future<void> deleteReservation(int id) async {
    try {
      await _apiService.deleteReservation(id, _authToken);
      debugPrint('✅ Reserva $id eliminada exitosamente');
    } catch (e) {
      debugPrint('❌ Error eliminando reserva: $e');
      rethrow; // Re-lanzar la excepción para que el UI pueda capturar el mensaje
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

  Future<Map<String, dynamic>> getPerformanceMetrics(int userId) async {
    try {
      // Obtener reservas, pagos y cotizaciones del empleado
      final reservations = await getReservationsByEmployee(userId);
      final payments = await getPaymentsByEmployee(userId);
      final quotes = await getQuotesByEmployee(userId);
      
      // Calcular métricas de reservas
      final totalReservations = reservations.length;
      final confirmedCount = reservations.where((r) => r.estado == ReservationStatus.confirmada).length;
      final canceledCount = reservations.where((r) => r.estado == ReservationStatus.cancelada).length;
      
      // Calcular reservas en proceso (pendientes con pagos parciales) y pagadas
      int inProcessCount = 0;
      int paidCount = 0;
      int pendingCount = 0;
      
      for (final reservation in reservations) {
        if (reservation.estado == ReservationStatus.pendiente) {
          final reservationPayments = await getPaymentsByReservation(reservation.id!);
          final totalPaid = reservationPayments.fold<double>(0.0, (sum, p) => sum + p.monto);
          
          if (totalPaid > 0 && totalPaid < reservation.totalPago) {
            inProcessCount++; // Tiene pagos parciales
          } else if (totalPaid >= reservation.totalPago) {
            paidCount++; // Completamente pagada
          } else {
            pendingCount++; // Sin pagos
          }
        } else if (reservation.estado == ReservationStatus.confirmada) {
          paidCount++; // Confirmadas = pagadas
        }
      }
      
      // Calcular ingresos REALES desde pagos (no desde reservas)
      final totalRevenue = payments.fold<double>(
        0.0,
        (sum, payment) => sum + payment.monto,
      );
      
      // Calcular ventas completadas vs en proceso
      // Una venta está completada solo si la reserva está completamente pagada
      int completedSales = 0;
      int inProcessSales = 0;
      
      // Agrupar reservas únicas que tienen pagos
      final reservationsWithPayments = <int>{};
      for (final payment in payments) {
        reservationsWithPayments.add(payment.idReserva);
      }
      
      for (final reservationId in reservationsWithPayments) {
        final reservation = reservations.firstWhere((r) => r.id == reservationId);
        final reservationPayments = await getPaymentsByReservation(reservationId);
        final totalPaid = reservationPayments.fold<double>(0.0, (sum, p) => sum + p.monto);
        
        if (totalPaid >= reservation.totalPago) {
          completedSales++; // Venta completamente pagada
        } else {
          inProcessSales++; // Venta con pago parcial
        }
      }
      
      // Calcular métricas de cotizaciones
      final totalQuotes = quotes.length;
      final acceptedQuotes = quotes.where((q) => q.estado == QuoteStatus.aceptada).length;
      final rejectedQuotes = quotes.where((q) => q.estado == QuoteStatus.rechazada).length;
      
      // Obtener clientes del empleado
      final clients = await getClients(forEmployeeId: userId);
      
      return {
        'sales': {
          'total': completedSales + inProcessSales,
          'completed': completedSales,
          'inProcess': inProcessSales,
          'totalRevenue': totalRevenue,
          'averageSale': (completedSales + inProcessSales) > 0 
              ? totalRevenue / (completedSales + inProcessSales) 
              : 0.0,
        },
        'reservations': {
          'total': totalReservations,
          'confirmed': confirmedCount,
          'pending': pendingCount,
          'inProcess': inProcessCount,
          'paid': paidCount,
          'cancelled': canceledCount,
        },
        'quotes': {
          'total': totalQuotes,
          'accepted': acceptedQuotes,
          'rejected': rejectedQuotes,
          'pending': totalQuotes - acceptedQuotes - rejectedQuotes,
        },
        'clients': {
          'total': clients.length,
        },
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error obteniendo métricas de desempeño: $e');
      return {
        'sales': {'total': 0, 'completed': 0, 'inProcess': 0, 'totalRevenue': 0.0, 'averageSale': 0.0},
        'reservations': {'total': 0, 'confirmed': 0, 'pending': 0, 'inProcess': 0, 'paid': 0, 'cancelled': 0},
        'quotes': {'total': 0, 'accepted': 0, 'rejected': 0, 'pending': 0},
        'clients': {'total': 0},
      };
    }
  }

  // ===== PAGOS =====

  Future<List<Payment>> getAllPayments() async {
    try {
      final paymentsData = await _apiService.getPayments(_authToken);
      return paymentsData.map((data) => Payment.fromMap(data)).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo pagos: $e');
      return [];
    }
  }

  Future<List<Payment>> getPaymentsByEmployee(int idEmpleado) async {
    try {
      final paymentsData = await _apiService.getPaymentsByEmployee(idEmpleado, _authToken);
      return paymentsData.map((data) => Payment.fromMap(data)).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo pagos del empleado: $e');
      return [];
    }
  }

  Future<List<Payment>> getPaymentsByReservation(int idReserva) async {
    try {
      final paymentsData = await _apiService.getPaymentsByReservation(idReserva, _authToken);
      return paymentsData.map((data) => Payment.fromMap(data)).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo pagos de la reserva: $e');
      return [];
    }
  }

  Future<Payment> savePayment(Payment payment) async {
    try {
      final paymentData = payment.toMap();
      final responseData = payment.id == null
          ? await _apiService.createPayment(paymentData, _authToken)
          : await _apiService.updatePayment(payment.id!, paymentData, _authToken);
      return Payment.fromMap(responseData);
    } catch (e) {
      debugPrint('❌ Error guardando pago: $e');
      rethrow;
    }
  }

  Future<bool> deletePayment(int id) async {
    try {
      await _apiService.deletePayment(id, _authToken);
      return true;
    } catch (e) {
      debugPrint('❌ Error eliminando pago: $e');
      return false;
    }
  }

  /// Calcula el monto restante por pagar de una reserva
  Future<double> getRemainingAmount(int idReserva) async {
    try {
      // Obtener la reserva
      final reservations = await getAllReservations();
      final reservation = reservations.firstWhere((r) => r.id == idReserva);
      
      // Obtener todos los pagos de esta reserva
      final payments = await getPaymentsByReservation(idReserva);
      
      // Sumar todos los pagos
      final totalPaid = payments.fold<double>(0.0, (sum, payment) => sum + payment.monto);
      
      // Calcular restante
      final remaining = reservation.totalPago - totalPaid;
      return remaining > 0 ? remaining : 0.0;
    } catch (e) {
      debugPrint('❌ Error calculando monto restante: $e');
      return 0.0;
    }
  }

  /// Obtiene información de saldo de una reserva
  Future<Map<String, dynamic>> getReservationBalance(int idReserva) async {
    try {
      final reservations = await getAllReservations();
      final reservation = reservations.firstWhere((r) => r.id == idReserva);
      final payments = await getPaymentsByReservation(idReserva);
      
      final totalPaid = payments.fold<double>(0.0, (sum, payment) => sum + payment.monto);
      final remaining = reservation.totalPago - totalPaid;
      
      return {
        'totalReserva': reservation.totalPago,
        'totalPagado': totalPaid,
        'montoRestante': remaining > 0 ? remaining : 0.0,
        'porcentajePagado': reservation.totalPago > 0 ? (totalPaid / reservation.totalPago * 100) : 0.0,
        'pagosRealizados': payments.length,
      };
    } catch (e) {
      debugPrint('❌ Error obteniendo balance de reserva: $e');
      return {
        'totalReserva': 0.0,
        'totalPagado': 0.0,
        'montoRestante': 0.0,
        'porcentajePagado': 0.0,
        'pagosRealizados': 0,
      };
    }
  }

  // ===== PAQUETES TURÍSTICOS =====

  Future<List<TourPackage>> getPackages() async {
    try {
      final packagesData = await _apiService.getPackages(_authToken);
      return packagesData.map((data) => TourPackage.fromMap(data)).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo paquetes: $e');
      return [];
    }
  }

  Future<TourPackage> savePackage(TourPackage package) async {
    try {
      final packageData = package.toMap();
      debugPrint('📦 Guardando paquete: ${packageData['nombre']}');
      debugPrint('📦 Destinos a guardar: ${packageData['destinos_ids']}');
      debugPrint('📦 Datos completos: $packageData');
      
      final responseData = package.id == null
          ? await _apiService.createPackage(packageData, _authToken)
          : await _apiService.updatePackage(package.id!, packageData, _authToken);
      
      debugPrint('📦 Respuesta del servidor: $responseData');
      
      return TourPackage.fromMap(responseData);
    } catch (e) {
      debugPrint('❌ Error guardando paquete: $e');
      rethrow;
    }
  }

  Future<void> deletePackage(int id) async {
    try {
      await _apiService.deletePackage(id, _authToken);
      debugPrint('✅ Paquete $id eliminado exitosamente');
    } catch (e) {
      debugPrint('❌ Error eliminando paquete: $e');
      rethrow; // Re-lanzar la excepción para que el UI pueda capturar el mensaje
    }
  }

  // ===== COTIZACIONES =====

  Future<List<Quote>> getQuotes() async {
    try {
      final quotesData = await _apiService.getQuotes(_authToken);
      return quotesData.map((data) => Quote.fromMap(data)).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo cotizaciones: $e');
      return [];
    }
  }

  Future<List<Quote>> getQuotesByEmployee(int employeeId) async {
    try {
      final quotesData = await _apiService.getQuotesByEmployee(employeeId, _authToken);
      return quotesData.map((data) => Quote.fromMap(data)).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo cotizaciones del empleado: $e');
      return [];
    }
  }

  Future<Quote> saveQuote(Quote quote) async {
    try {
      final quoteData = quote.toMap();
      final responseData = quote.id == null
          ? await _apiService.createQuote(quoteData, _authToken)
          : await _apiService.updateQuote(quote.id!, quoteData, _authToken);
      return Quote.fromMap(responseData);
    } catch (e) {
      debugPrint('❌ Error guardando cotización: $e');
      rethrow;
    }
  }

  Future<bool> deleteQuote(int id) async {
    try {
      await _apiService.deleteQuote(id, _authToken);
      return true;
    } catch (e) {
      debugPrint('❌ Error eliminando cotización: $e');
      return false;
    }
  }

  // ===== PROVEEDORES =====

  Future<List<Provider>> getProviders() async {
    try {
      final providersData = await _apiService.getProviders(_authToken);
      return providersData.map((data) => Provider.fromMap(data)).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo proveedores: $e');
      return [];
    }
  }

  Future<Provider> saveProvider(Provider provider) async {
    try {
      final providerData = provider.toMap();
      final responseData = provider.id == null
          ? await _apiService.createProvider(providerData, _authToken)
          : await _apiService.updateProvider(provider.id!, providerData, _authToken);
      return Provider.fromMap(responseData);
    } catch (e) {
      debugPrint('❌ Error guardando proveedor: $e');
      rethrow;
    }
  }

  Future<bool> deleteProvider(int id) async {
    try {
      await _apiService.deleteProvider(id, _authToken);
      return true;
    } catch (e) {
      debugPrint('❌ Error eliminando proveedor: $e');
      return false;
    }
  }

  // ===== INDICADORES DE DESEMPEÑO =====

  Future<List<Map<String, dynamic>>> getEmployeeClients(int employeeId) async {
    try {
      final clients = await getClients(forEmployeeId: employeeId);
      
      return clients
          .map((client) => {
                'id_cliente': client.id ?? 0,
                'nombre': client.nombreCompleto,
                'nacionalidad': client.pais,
                'pasaporte': client.telefono,
                'fecha_registro': client.fechaRegistro.toIso8601String(),
                'preferencias_viaje': client.interes,
                'id_empleado': client.idEmpleado,
                'satisfaccion': client.satisfaccion ?? 3,
                'estado_civil': client.estadoCivil ?? 'N/D',
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
