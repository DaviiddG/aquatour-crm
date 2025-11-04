import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/access_log.dart';
import '../models/user.dart';

class AccessLogService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://app-6aaf68d8-72ab-47f4-bad2-13d5ab31d374.cleverapps.io/api',
  );

  // Registrar ingreso al sistema
  static Future<int?> logLogin({
    required User usuario,
    required String ipAddress,
    String? navegador,
    String? sistemaOperativo,
  }) async {
    try {
      final log = AccessLog(
        idUsuario: usuario.idUsuario!,
        nombreUsuario: '${usuario.nombre} ${usuario.apellido}',
        rolUsuario: usuario.rol.displayName,
        fechaHoraIngreso: DateTime.now(),
        ipAddress: ipAddress,
        navegador: navegador,
        sistemaOperativo: sistemaOperativo,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/access-logs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(log.toMap()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id_log'];
      }
      return null;
    } catch (e) {
      print('Error al registrar ingreso: $e');
      return null;
    }
  }

  // Registrar salida del sistema
  static Future<void> logLogout(int logId) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/access-logs/$logId/logout'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Error al registrar salida: $e');
    }
  }

  // Obtener todos los logs de acceso
  static Future<List<AccessLog>> getAllAccessLogs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/access-logs'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AccessLog.fromMap(json)).toList();
      } else {
        throw Exception('Error al obtener logs: ${response.body}');
      }
    } catch (e) {
      print('Error al obtener logs de acceso: $e');
      return [];
    }
  }

  // Obtener logs por usuario
  static Future<List<AccessLog>> getAccessLogsByUser(int idUsuario) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/access-logs/user/$idUsuario'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AccessLog.fromMap(json)).toList();
      } else {
        throw Exception('Error al obtener logs: ${response.body}');
      }
    } catch (e) {
      print('Error al obtener logs por usuario: $e');
      return [];
    }
  }

  // Obtener logs por rango de fechas
  static Future<List<AccessLog>> getAccessLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/access-logs/date-range?start=${startDate.toIso8601String()}&end=${endDate.toIso8601String()}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AccessLog.fromMap(json)).toList();
      } else {
        throw Exception('Error al obtener logs: ${response.body}');
      }
    } catch (e) {
      print('Error al obtener logs por rango de fechas: $e');
      return [];
    }
  }
}
