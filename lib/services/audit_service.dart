import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/audit_log.dart';
import '../models/user.dart';

class AuditService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://app-6aaf68d8-72ab-47f4-bad2-13d5ab31d374.cleverapps.io/api',
  );

  // Registrar una acción de auditoría
  static Future<void> logAction({
    required User usuario,
    required AuditAction accion,
    required String entidad,
    int? idEntidad,
    String? nombreEntidad,
    Map<String, dynamic>? detalles,
  }) async {
    try {
      // Determinar la categoría según el rol
      final categoria = usuario.rol == UserRole.administrador || 
                       usuario.rol == UserRole.superadministrador
          ? AuditCategory.administrador
          : AuditCategory.asesor;

      final log = AuditLog(
        idUsuario: usuario.idUsuario!,
        nombreUsuario: '${usuario.nombre} ${usuario.apellido}',
        rolUsuario: usuario.rol.displayName,
        accion: accion,
        categoria: categoria,
        entidad: entidad,
        idEntidad: idEntidad,
        nombreEntidad: nombreEntidad,
        detalles: detalles != null ? jsonEncode(detalles) : null,
        fechaHora: DateTime.now(),
      );

      final response = await http.post(
        Uri.parse('$baseUrl/audit-logs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(log.toMap()),
      );

      if (response.statusCode != 201) {
        print('Error al registrar log de auditoría: ${response.body}');
      }
    } catch (e) {
      print('Error al registrar log de auditoría: $e');
    }
  }

  // Obtener todos los logs de auditoría (solo superadministrador)
  static Future<List<AuditLog>> getAllLogs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/audit-logs'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AuditLog.fromMap(json)).toList();
      } else {
        throw Exception('Error al obtener logs: ${response.body}');
      }
    } catch (e) {
      print('Error al obtener logs de auditoría: $e');
      return [];
    }
  }

  // Obtener logs por categoría
  static Future<List<AuditLog>> getLogsByCategory(AuditCategory categoria) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/audit-logs/category/${categoria.name}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AuditLog.fromMap(json)).toList();
      } else {
        throw Exception('Error al obtener logs: ${response.body}');
      }
    } catch (e) {
      print('Error al obtener logs por categoría: $e');
      return [];
    }
  }

  // Obtener logs por usuario
  static Future<List<AuditLog>> getLogsByUser(int idUsuario) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/audit-logs/user/$idUsuario'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AuditLog.fromMap(json)).toList();
      } else {
        throw Exception('Error al obtener logs: ${response.body}');
      }
    } catch (e) {
      print('Error al obtener logs por usuario: $e');
      return [];
    }
  }

  // Obtener logs por rango de fechas
  static Future<List<AuditLog>> getLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/audit-logs/date-range?start=${startDate.toIso8601String()}&end=${endDate.toIso8601String()}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AuditLog.fromMap(json)).toList();
      } else {
        throw Exception('Error al obtener logs: ${response.body}');
      }
    } catch (e) {
      print('Error al obtener logs por rango de fechas: $e');
      return [];
    }
  }

  // Obtener estadísticas de auditoría
  static Future<Map<String, dynamic>> getAuditStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/audit-logs/stats'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener estadísticas: ${response.body}');
      }
    } catch (e) {
      print('Error al obtener estadísticas de auditoría: $e');
      return {};
    }
  }

  // Eliminar todos los logs de auditoría (solo superadministrador)
  static Future<void> deleteAllLogs() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/audit-logs'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar logs: ${response.body}');
      }
    } catch (e) {
      print('Error al eliminar logs de auditoría: $e');
      throw e;
    }
  }
}
