import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/contact.dart';
import '../models/user.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _dartDefineBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const String _remoteFallbackUrl = 'https://app-6aaf68d8-72ab-47f4-bad2-13d5ab31d374.cleverapps.io/api';

  static bool get _isLocalHost {
    if (!kIsWeb) return false;
    final host = Uri.base.host;
    return host == 'localhost' || host == '127.0.0.1' || host.startsWith('192.168.') || host.startsWith('10.');
  }

  // Base URL para la API - configurable desde .env
  static String get _baseUrl {
    if (_dartDefineBaseUrl.isNotEmpty) {
      return _normalizeBaseUrl(_dartDefineBaseUrl);
    }

    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return _normalizeBaseUrl(envUrl);
    }

    if (kIsWeb) {
      if (_isLocalHost) {
        return _normalizeBaseUrl(Uri.base.origin);
      }
      return _normalizeBaseUrl(_remoteFallbackUrl);
    }

    return _normalizeBaseUrl(_remoteFallbackUrl); // Fallback para builds nativos
  }

  static String get baseUrl => _baseUrl;

  static String _normalizeBaseUrl(String rawUrl) {
    if (rawUrl.isEmpty) return rawUrl;

    try {
      final uri = Uri.parse(rawUrl);
      final segments = List<String>.from(uri.pathSegments.where((segment) => segment.isNotEmpty));
      if (segments.isEmpty || segments.last.toLowerCase() != 'api') {
        segments.add('api');
      }

      final normalized = uri.replace(pathSegments: segments).toString();
      return normalized.endsWith('/') ? normalized.substring(0, normalized.length - 1) : normalized;
    } catch (_) {
      // En caso de URL inválida, regresamos el valor original para no romper la app
      return rawUrl;
    }
  }

  // Headers comunes
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Headers con autenticación (para futuras implementaciones)
  Map<String, String> _authHeaders(String? token) {
    final headers = Map<String, String>.from(_headers);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _buildUri(String endpoint) {
    final normalized = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$_baseUrl$normalized');
  }

  dynamic _parseResponse(http.Response response) {
    final status = response.statusCode;
    final rawBody = utf8.decode(response.bodyBytes);
    dynamic decoded;

    if (rawBody.isEmpty) {
      decoded = {};
    } else {
      try {
        decoded = json.decode(rawBody);
      } on FormatException {
        final snippet = rawBody.length > 160 ? '${rawBody.substring(0, 160)}…' : rawBody;
        debugPrint('⚠️ Respuesta no JSON (${response.request?.url} - status $status): $snippet');
        throw Exception('La API devolvió una respuesta inesperada (status $status). Verifica la URL base y el servidor.');
      }
    }

    if (status >= 400) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error'] ?? decoded['message']
          : response.reasonPhrase;
      debugPrint('❌ Error HTTP $status: $message');
      debugPrint('❌ Respuesta completa: $decoded');
      throw Exception(message ?? 'Error $status en la solicitud');
    }

    if (decoded is Map<String, dynamic> && decoded.containsKey('ok') && decoded['ok'] == false) {
      final message = decoded['error'] ?? decoded['message'] ?? 'Operación no completada';
      throw Exception(message);
    }

    return decoded;
  }

  // Método genérico para hacer peticiones GET
  Future<dynamic> _get(String endpoint, {String? token}) async {
    try {
      final response = await http.get(
        _buildUri(endpoint),
        headers: _authHeaders(token),
      );
      return _parseResponse(response);
    } catch (e) {
      print('❌ Error en GET $endpoint: $e');
      rethrow;
    }
  }

  // Método genérico para hacer peticiones POST
  Future<dynamic> _post(String endpoint, dynamic data, {String? token}) async {
    try {
      final response = await http.post(
        _buildUri(endpoint),
        headers: _authHeaders(token),
        body: json.encode(data),
      );
      return _parseResponse(response);
    } catch (e) {
      print('❌ Error en POST $endpoint: $e');
      rethrow;
    }
  }

  // Método genérico para hacer peticiones PUT
  Future<dynamic> _put(String endpoint, dynamic data, {String? token}) async {
    try {
      final response = await http.put(
        _buildUri(endpoint),
        headers: _authHeaders(token),
        body: json.encode(data),
      );
      return _parseResponse(response);
    } catch (e) {
      print('❌ Error en PUT $endpoint: $e');
      rethrow;
    }
  }

  // Método genérico para hacer peticiones DELETE
  Future<dynamic> _delete(String endpoint, {String? token, Map<String, dynamic>? body}) async {
    try {
      final headers = _authHeaders(token);
      final response = await http.delete(
        _buildUri(endpoint),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _parseResponse(response);
    } catch (e) {
      print('❌ Error en DELETE $endpoint: $e');
      rethrow;
    }
  }

  // ===== AUTENTICACIÓN =====

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    return response;
  }

  // Logout
  Future<void> logout(String? token) async {
    await _post('/auth/logout', {}, token: token);
  }

  // Verificar token
  Future<Map<String, dynamic>> verifyToken(String token) async {
    final response = await _get('/auth/verify', token: token);
    return response;
  }

  Future<Map<String, dynamic>> health() async {
    final response = await _get('/health');
    return response is Map<String, dynamic> ? response : {'status': response};
  }

  // ===== USUARIOS =====

  // Obtener todos los usuarios
  Future<List<dynamic>> getUsers(String? token) async {
    final response = await _get('/users', token: token);
    if (response is Map<String, dynamic> && response['users'] is List<dynamic>) {
      return response['users'] as List<dynamic>;
    }
    if (response is List<dynamic>) return response;
    return [];
  }

  // Obtener usuario por ID
  Future<Map<String, dynamic>> getUser(int id, String? token) async {
    final response = await _get('/users/$id', token: token);
    if (response is Map<String, dynamic> && response['user'] is Map<String, dynamic>) {
      return response['user'] as Map<String, dynamic>;
    }
    return response as Map<String, dynamic>;
  }

  // Crear usuario
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData, String? token) async {
    final response = await _post('/users', userData, token: token);
    if (response is Map<String, dynamic> && response['user'] is Map<String, dynamic>) {
      return response['user'] as Map<String, dynamic>;
    }
    return response as Map<String, dynamic>;
  }

  // Actualizar usuario
  Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> userData, String? token) async {
    final response = await _put('/users/$id', userData, token: token);
    if (response is Map<String, dynamic> && response['user'] is Map<String, dynamic>) {
      return response['user'] as Map<String, dynamic>;
    }
    return response as Map<String, dynamic>;
  }

  // Eliminar usuario
  Future<void> deleteUser(int id, String? token) async {
    await _delete('/users/$id', token: token);
  }

  // Verificar si email existe
  Future<Map<String, dynamic>> checkEmailExists(String email, {String? token, int? excludeUserId}) async {
    final sanitizedEmail = Uri.encodeComponent(email);
    final query = excludeUserId != null ? '?exclude=$excludeUserId' : '';
    final response = await _get('/users/check-email/$sanitizedEmail$query', token: token);
    return response;
  }

  // Verificar si documento existe
  Future<Map<String, dynamic>> checkDocumentExists(String numDocumento, {String? token, int? excludeUserId}) async {
    final sanitizedDoc = Uri.encodeComponent(numDocumento);
    final query = excludeUserId != null ? '?exclude=$excludeUserId' : '';
    final response = await _get('/users/check-document/$sanitizedDoc$query', token: token);
    return response;
  }

  // Verificar si teléfono existe
  Future<Map<String, dynamic>> checkPhoneExists(String telefono, {String? token, int? excludeUserId}) async {
    final sanitizedPhone = Uri.encodeComponent(telefono);
    final query = excludeUserId != null ? '?exclude=$excludeUserId' : '';
    final response = await _get('/users/check-phone/$sanitizedPhone$query', token: token);
    return response;
  }

  // ===== CONTACTOS =====

  // Obtener todos los contactos
  Future<List<dynamic>> getContacts(String? token) async {
    final response = await _get('/contacts', token: token);
    return response['contacts'] ?? response;
  }

  // Obtener contacto por ID
  Future<Map<String, dynamic>> getContact(int id, String? token) async {
    final response = await _get('/contacts/$id', token: token);
    return response;
  }

  // Crear contacto
  Future<Map<String, dynamic>> createContact(Map<String, dynamic> contactData, String? token) async {
    final response = await _post('/contacts', contactData, token: token);
    return response;
  }

  // Actualizar contacto
  Future<Map<String, dynamic>> updateContact(int id, Map<String, dynamic> contactData, String? token) async {
    final response = await _put('/contacts/$id', contactData, token: token);
    return response;
  }

  // Eliminar contacto
  Future<void> deleteContact(int id, String? token) async {
    await _delete('/contacts/$id', token: token);
  }

  // ===== CLIENTES =====

  Future<List<dynamic>> getClients(String? token) async {
    final response = await _get('/clients', token: token);
    if (response is Map<String, dynamic> && response['clients'] is List<dynamic>) {
      return response['clients'] as List<dynamic>;
    }
    if (response is List<dynamic>) return response;
    return [];
  }

  Future<Map<String, dynamic>> getClient(int id, String? token) async {
    final response = await _get('/clients/$id', token: token);
    if (response is Map<String, dynamic> && response['client'] is Map<String, dynamic>) {
      return response['client'] as Map<String, dynamic>;
    }
    return response as Map<String, dynamic>;
  }

  Future<List<dynamic>> getClientsByUser(int userId, String? token) async {
    final response = await _get('/clients/user/$userId', token: token);
    if (response is Map<String, dynamic> && response['clients'] is List<dynamic>) {
      return response['clients'] as List<dynamic>;
    }
    if (response is List<dynamic>) return response;
    return [];
  }

  Future<Map<String, dynamic>> createClient(Map<String, dynamic> clientData, String? token) async {
    final response = await _post('/clients', clientData, token: token);
    if (response is Map<String, dynamic> && response['client'] is Map<String, dynamic>) {
      return response['client'] as Map<String, dynamic>;
    }
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateClient(int id, Map<String, dynamic> clientData, String? token) async {
    final response = await _put('/clients/$id', clientData, token: token);
    if (response is Map<String, dynamic> && response['client'] is Map<String, dynamic>) {
      return response['client'] as Map<String, dynamic>;
    }
    return response as Map<String, dynamic>;
  }

  Future<void> deleteClient(int id, String? token, [Map<String, dynamic>? auditData]) async {
    String endpoint = '/clients/$id';
    
    // Si hay datos de auditoría, agregarlos como query parameters
    if (auditData != null && auditData['audit'] != null) {
      final audit = auditData['audit'] as Map<String, dynamic>;
      final queryParams = {
        'id_usuario': audit['id_usuario'].toString(),
        'nombre_usuario': audit['nombre_usuario'].toString(),
        'rol_usuario': audit['rol_usuario'].toString(),
        'categoria': audit['categoria'].toString(),
      };
      
      final uri = Uri.parse('$baseUrl$endpoint');
      final uriWithParams = uri.replace(queryParameters: queryParams);
      endpoint = uriWithParams.toString().replaceFirst(baseUrl, '');
    }
    
    await _delete(endpoint, token: token);
  }

  // ===== DESTINOS =====

  Future<List<dynamic>> getDestinations(String? token) async {
    final response = await _get('/destinations', token: token);
    if (response is Map<String, dynamic> && response['destinations'] is List<dynamic>) {
      return response['destinations'] as List<dynamic>;
    }
    if (response is List<dynamic>) return response;
    return [];
  }

  Future<Map<String, dynamic>> getDestination(int id, String? token) async {
    final response = await _get('/destinations/$id', token: token);
    return response;
  }

  Future<Map<String, dynamic>> createDestination(Map<String, dynamic> destinationData, String? token) async {
    final response = await _post('/destinations', destinationData, token: token);
    return response;
  }

  Future<Map<String, dynamic>> updateDestination(int id, Map<String, dynamic> destinationData, String? token) async {
    final response = await _put('/destinations/$id', destinationData, token: token);
    return response;
  }

  Future<void> deleteDestination(int id, String? token) async {
    await _delete('/destinations/$id', token: token);
  }

  // ===== RESERVAS =====

  Future<List<dynamic>> getReservations(String? token) async {
    final response = await _get('/reservations', token: token);
    if (response is Map<String, dynamic> && response['reservations'] is List<dynamic>) {
      return response['reservations'] as List<dynamic>;
    }
    if (response is List<dynamic>) return response;
    return [];
  }

  Future<List<dynamic>> getReservationsByEmployee(int idEmpleado, String? token) async {
    final response = await _get('/reservations/employee/$idEmpleado', token: token);
    if (response is Map<String, dynamic> && response['reservations'] is List<dynamic>) {
      return response['reservations'] as List<dynamic>;
    }
    if (response is List<dynamic>) return response;
    return [];
  }

  Future<Map<String, dynamic>> createReservation(Map<String, dynamic> reservationData, String? token) async {
    final response = await _post('/reservations', reservationData, token: token);
    return response;
  }

  Future<Map<String, dynamic>> updateReservation(int id, Map<String, dynamic> reservationData, String? token) async {
    final response = await _put('/reservations/$id', reservationData, token: token);
    return response;
  }

  Future<void> deleteReservation(int id, String? token) async {
    await _delete('/reservations/$id', token: token);
  }

  // ===== PAGOS =====

  Future<List<dynamic>> getPayments(String? token) async {
    final response = await _get('/payments', token: token);
    if (response is List<dynamic>) return response;
    return [];
  }

  Future<List<dynamic>> getPaymentsByEmployee(int idEmpleado, String? token) async {
    final response = await _get('/payments/employee/$idEmpleado', token: token);
    if (response is List<dynamic>) return response;
    return [];
  }

  Future<List<dynamic>> getPaymentsByReservation(int idReserva, String? token) async {
    final response = await _get('/payments/reservation/$idReserva', token: token);
    if (response is List<dynamic>) return response;
    return [];
  }

  Future<Map<String, dynamic>> createPayment(Map<String, dynamic> paymentData, String? token) async {
    final response = await _post('/payments', paymentData, token: token);
    return response;
  }

  Future<Map<String, dynamic>> updatePayment(int id, Map<String, dynamic> paymentData, String? token) async {
    final response = await _put('/payments/$id', paymentData, token: token);
    return response;
  }

  Future<void> deletePayment(int id, String? token) async {
    await _delete('/payments/$id', token: token);
  }

  // ===== PAQUETES TURÍSTICOS =====

  Future<List<dynamic>> getPackages(String? token) async {
    final response = await _get('/packages', token: token);
    if (response is List<dynamic>) return response;
    return [];
  }

  Future<Map<String, dynamic>> getPackageById(int id, String? token) async {
    final response = await _get('/packages/$id', token: token);
    return response;
  }

  Future<Map<String, dynamic>> createPackage(Map<String, dynamic> packageData, String? token) async {
    final response = await _post('/packages', packageData, token: token);
    return response;
  }

  Future<Map<String, dynamic>> updatePackage(int id, Map<String, dynamic> packageData, String? token) async {
    final response = await _put('/packages/$id', packageData, token: token);
    return response;
  }

  Future<void> deletePackage(int id, String? token) async {
    await _delete('/packages/$id', token: token);
  }

  // ===== COTIZACIONES =====

  Future<List<dynamic>> getQuotes(String? token) async {
    final response = await _get('/quotes', token: token);
    if (response is List<dynamic>) return response;
    return [];
  }

  Future<List<dynamic>> getQuotesByEmployee(int employeeId, String? token) async {
    final response = await _get('/quotes/employee/$employeeId', token: token);
    if (response is List<dynamic>) return response;
    return [];
  }

  Future<Map<String, dynamic>> getQuoteById(int id, String? token) async {
    final response = await _get('/quotes/$id', token: token);
    return response;
  }

  Future<Map<String, dynamic>> createQuote(Map<String, dynamic> quoteData, String? token) async {
    final response = await _post('/quotes', quoteData, token: token);
    return response;
  }

  Future<Map<String, dynamic>> updateQuote(int id, Map<String, dynamic> quoteData, String? token) async {
    final response = await _put('/quotes/$id', quoteData, token: token);
    return response;
  }

  Future<void> deleteQuote(int id, String? token) async {
    await _delete('/quotes/$id', token: token);
  }

  // ===== PROVEEDORES =====

  Future<List<dynamic>> getProviders(String? token) async {
    final response = await _get('/providers', token: token);
    if (response is List<dynamic>) return response;
    return [];
  }

  Future<Map<String, dynamic>> getProviderById(int id, String? token) async {
    final response = await _get('/providers/$id', token: token);
    return response;
  }

  Future<Map<String, dynamic>> createProvider(Map<String, dynamic> providerData, String? token) async {
    final response = await _post('/providers', providerData, token: token);
    return response;
  }

  Future<Map<String, dynamic>> updateProvider(int id, Map<String, dynamic> providerData, String? token) async {
    final response = await _put('/providers/$id', providerData, token: token);
    return response;
  }

  Future<void> deleteProvider(int id, String? token) async {
    await _delete('/providers/$id', token: token);
  }

  // ===== ESTADÍSTICAS Y DASHBOARD =====

  // Obtener estadísticas del dashboard
  Future<Map<String, dynamic>> getDashboardStats(String? token) async {
    final response = await _get('/dashboard/stats', token: token);
    return response;
  }

  // ===== SISTEMA =====

  // Limpiar todo el CRM (solo superadministrador)
  Future<void> clearCRM(String? token, Map<String, dynamic> auditData) async {
    String endpoint = '/system/clear-all';
    
    // Agregar datos de auditoría como query parameters
    if (auditData['audit'] != null) {
      final audit = auditData['audit'] as Map<String, dynamic>;
      final queryParams = {
        'id_usuario': audit['id_usuario'].toString(),
        'nombre_usuario': audit['nombre_usuario'].toString(),
        'rol_usuario': audit['rol_usuario'].toString(),
        'categoria': audit['categoria'].toString(),
      };
      
      final uri = Uri.parse('$baseUrl$endpoint');
      final uriWithParams = uri.replace(queryParameters: queryParams);
      endpoint = uriWithParams.toString().replaceFirst(baseUrl, '');
    }
    
    await _delete(endpoint, token: token);
  }
}
