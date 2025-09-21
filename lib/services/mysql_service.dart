import 'dart:async';
import 'package:mysql1/mysql1.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/contact.dart';

class MySQLService {
  static final MySQLService _instance = MySQLService._internal();
  factory MySQLService() => _instance;
  MySQLService._internal();

  MySqlConnection? _connection;

  // Configuración de conexión usando las variables correctas de Clever Cloud
  ConnectionSettings get _settings => ConnectionSettings(
    host: dotenv.env['MYSQL_ADDON_HOST'] ?? 'localhost',
    port: int.parse(dotenv.env['MYSQL_ADDON_PORT'] ?? '3306'),
    user: dotenv.env['MYSQL_ADDON_USER'] ?? 'root',
    password: dotenv.env['MYSQL_ADDON_PASSWORD'] ?? '',
    db: dotenv.env['MYSQL_ADDON_DB'] ?? 'aquatour',
  );

  // Conectar a la base de datos
  Future<MySqlConnection> _getConnection() async {
    if (_connection == null || _connection!.isClosed) {
      try {
        _connection = await MySqlConnection.connect(_settings);
        print('✅ Conectado a MySQL en Clever Cloud');
        print('🔗 Host: ${dotenv.env['MYSQL_ADDON_HOST']}');
        print('🗄️ Base de datos: ${dotenv.env['MYSQL_ADDON_DB']}');
      } catch (e) {
        print('❌ Error conectando a MySQL: $e');
        print('🔧 Verificando configuración...');
        print('   Host: ${dotenv.env['MYSQL_ADDON_HOST']}');
        print('   Puerto: ${dotenv.env['MYSQL_ADDON_PORT']}');
        print('   Usuario: ${dotenv.env['MYSQL_ADDON_USER']}');
        print('   Base de datos: ${dotenv.env['MYSQL_ADDON_DB']}');
        rethrow;
      }
    }
    return _connection!;
  }

  // Inicializar tablas si no existen
  Future<void> initializeTables() async {
    try {
      final conn = await _getConnection();
      
      // Crear tabla de contactos
      await conn.query('''
        CREATE TABLE IF NOT EXISTS contacts (
          id INT AUTO_INCREMENT PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          email VARCHAR(255) NOT NULL,
          phone VARCHAR(50) NOT NULL,
          company VARCHAR(255) NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
      ''');

      // Crear tabla de cotizaciones
      await conn.query('''
        CREATE TABLE IF NOT EXISTS quotes (
          id INT AUTO_INCREMENT PRIMARY KEY,
          client_name VARCHAR(255) NOT NULL,
          service VARCHAR(255) NOT NULL,
          amount DECIMAL(10,2) NOT NULL,
          status ENUM('Pendiente', 'Aprobada', 'Rechazada') DEFAULT 'Pendiente',
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
      ''');

      // Crear tabla de reservas
      await conn.query('''
        CREATE TABLE IF NOT EXISTS reservations (
          id INT AUTO_INCREMENT PRIMARY KEY,
          client_name VARCHAR(255) NOT NULL,
          service VARCHAR(255) NOT NULL,
          reservation_date DATE NOT NULL,
          status ENUM('Confirmada', 'Pendiente', 'Cancelada') DEFAULT 'Pendiente',
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
      ''');

      print('✅ Tablas inicializadas correctamente');
      
      // Insertar datos de ejemplo si no existen
      await _insertSampleData(conn);
      
    } catch (e) {
      print('❌ Error inicializando tablas: $e');
      // No relanzar el error para que la app pueda continuar
    }
  }

  // Insertar datos de ejemplo
  Future<void> _insertSampleData(MySqlConnection conn) async {
    try {
      // Verificar si ya hay datos
      var result = await conn.query('SELECT COUNT(*) as count FROM contacts');
      var count = result.first['count'];
      
      if (count == 0) {
        // Insertar contactos de ejemplo
        await conn.query('''
          INSERT INTO contacts (name, email, phone, company) VALUES
          ('Juan Pérez', 'juan.perez@email.com', '+1234567890', 'Empresa ABC'),
          ('María García', 'maria.garcia@email.com', '+0987654321', 'Turismo XYZ'),
          ('Carlos López', 'carlos.lopez@email.com', '+1122334455', 'Viajes Premium')
        ''');

        // Insertar cotizaciones de ejemplo
        await conn.query('''
          INSERT INTO quotes (client_name, service, amount, status) VALUES
          ('Juan Pérez', 'Tour Caribe 3 días', 1500.00, 'Pendiente'),
          ('María García', 'Excursión Montaña', 800.00, 'Aprobada'),
          ('Carlos López', 'Paquete Playa 5 días', 2200.00, 'Pendiente')
        ''');

        print('✅ Datos de ejemplo insertados');
      }
    } catch (e) {
      print('⚠️ Error insertando datos de ejemplo: $e');
    }
  }

  // CRUD para Contactos
  
  Future<List<Contact>> getAllContacts() async {
    try {
      final conn = await _getConnection();
      var results = await conn.query('SELECT * FROM contacts ORDER BY created_at DESC');
      
      return results.map((row) => Contact(
        id: row['id'],
        name: row['name'],
        email: row['email'],
        phone: row['phone'],
        company: row['company'],
        createdAt: row['created_at'],
        updatedAt: row['updated_at'],
      )).toList();
    } catch (e) {
      print('❌ Error obteniendo contactos: $e');
      return [];
    }
  }

  Future<int> insertContact(Contact contact) async {
    try {
      final conn = await _getConnection();
      var result = await conn.query(
        'INSERT INTO contacts (name, email, phone, company) VALUES (?, ?, ?, ?)',
        [contact.name, contact.email, contact.phone, contact.company]
      );
      
      return result.insertId!;
    } catch (e) {
      print('❌ Error insertando contacto: $e');
      rethrow;
    }
  }

  Future<bool> updateContact(Contact contact) async {
    try {
      final conn = await _getConnection();
      await conn.query(
        'UPDATE contacts SET name = ?, email = ?, phone = ?, company = ? WHERE id = ?',
        [contact.name, contact.email, contact.phone, contact.company, contact.id]
      );
      
      return true;
    } catch (e) {
      print('❌ Error actualizando contacto: $e');
      return false;
    }
  }

  Future<bool> deleteContact(int id) async {
    try {
      final conn = await _getConnection();
      await conn.query('DELETE FROM contacts WHERE id = ?', [id]);
      return true;
    } catch (e) {
      print('❌ Error eliminando contacto: $e');
      return false;
    }
  }

  // Cerrar conexión
  Future<void> close() async {
    if (_connection != null && !_connection!.isClosed) {
      await _connection!.close();
      print('🔌 Conexión MySQL cerrada');
    }
  }
}
