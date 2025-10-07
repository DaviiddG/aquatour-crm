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
      return _normalizeBaseUrl(Uri.base.origin);
    }

    return 'http://localhost:8080/api'; // URL por defecto para desarrollo
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
    final rawBody = response.body;
    final decoded = rawBody.isEmpty ? {} : json.decode(rawBody);

    if (status >= 400) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error'] ?? decoded['message']
          : response.reasonPhrase;
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
  Future<dynamic> _delete(String endpoint, {String? token}) async {
    try {
      final response = await http.delete(
        _buildUri(endpoint),
        headers: _authHeaders(token),
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

  Future<void> deleteClient(int id, String? token) async {
    await _delete('/clients/$id', token: token);
  }

  // ===== ESTADÍSTICAS Y DASHBOARD =====

  // Obtener estadísticas del dashboard
  Future<Map<String, dynamic>> getDashboardStats(String? token) async {
    final response = await _get('/dashboard/stats', token: token);
    return response;
  }
}
