import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../models/user.dart';

// Importación condicional para web
import 'dart:html' as html show window;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _contactsKey = 'aquatour_contacts';
  static const String _usersKey = 'aquatour_users';
  static const String _currentUserKey = 'aquatour_current_user';
  
  // Lista en memoria para fallback
  List<Contact> _memoryContacts = [];
  List<User> _memoryUsers = [];

  // Usuario actual logueado
  User? _currentUser;

  // Inicializar con datos de ejemplo
  Future<void> initializeData() async {
    try {
      // Inicializar contactos
      final existingContacts = await getAllContacts();
      if (existingContacts.isEmpty) {
        final sampleContacts = [
          Contact(
            id: 1,
            name: 'Juan Pérez',
            email: 'juan.perez@email.com',
            phone: '+1234567890',
            company: 'Empresa ABC',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
            updatedAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          Contact(
            id: 2,
            name: 'María García',
            email: 'maria.garcia@email.com',
            phone: '+0987654321',
            company: 'Turismo XYZ',
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
            updatedAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
          Contact(
            id: 3,
            name: 'Carlos López',
            email: 'carlos.lopez@email.com',
            phone: '+1122334455',
            company: 'Viajes Premium',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            updatedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];

        for (final contact in sampleContacts) {
          await insertContact(contact);
        }
      }

      // Inicializar usuarios con roles
      final existingUsers = await getAllUsers();
      if (existingUsers.isEmpty) {
        final sampleUsers = [
          User(
            idUsuario: 1,
            nombre: 'Super',
            apellido: 'Admin',
            email: 'superadmin@aquatour.com',
            rol: UserRole.superadministrador,
            tipoDocumento: 'CC',
            numDocumento: '00000000',
            fechaNacimiento: DateTime(1980, 1, 1),
            genero: 'Masculino',
            telefono: '+57 300 000 0000',
            direccion: 'Oficina Principal',
            ciudadResidencia: 'Bogotá',
            paisResidencia: 'Colombia',
            contrasena: 'superadmin123',
            activo: true,
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
            updatedAt: DateTime.now().subtract(const Duration(days: 30)),
          ),
          User(
            idUsuario: 2,
            nombre: 'David',
            apellido: 'Gonzalez',
            email: 'davidg@aquatour.com',
            rol: UserRole.administrador,
            tipoDocumento: 'CC',
            numDocumento: '1017924927',
            fechaNacimiento: DateTime(2005, 9, 7), // 07-09-2005
            genero: 'Masculino',
            telefono: '3233053830',
            direccion: 'Carrera 85f #58a - 51',
            ciudadResidencia: 'Medellín',
            paisResidencia: 'Colombia',
            contrasena: 'Osquitar07',
            activo: true,
            createdAt: DateTime.now().subtract(const Duration(days: 10)),
            updatedAt: DateTime.now(),
          ),
          User(
            idUsuario: 3,
            nombre: 'Luis',
            apellido: 'Martínez',
            email: 'empleado@aquatour.com',
            rol: UserRole.empleado,
            tipoDocumento: 'CC',
            numDocumento: '87654321',
            fechaNacimiento: DateTime(1985, 8, 22),
            genero: 'Masculino',
            telefono: '+57 310 987 6543',
            direccion: 'Carrera 45 #12-34',
            ciudadResidencia: 'Medellín',
            paisResidencia: 'Colombia',
            contrasena: 'empleado123',
            activo: true,
            createdAt: DateTime.now().subtract(const Duration(days: 7)),
            updatedAt: DateTime.now().subtract(const Duration(days: 7)),
          ),
          User(
            idUsuario: 4,
            nombre: 'Carmen',
            apellido: 'Vásquez',
            email: 'carmen.vasquez@aquatour.com',
            rol: UserRole.empleado,
            tipoDocumento: 'CE',
            numDocumento: '98765432',
            fechaNacimiento: DateTime(1992, 12, 3),
            genero: 'Femenino',
            telefono: '+57 320 456 7890',
            direccion: 'Avenida 80 #23-45',
            ciudadResidencia: 'Cali',
            paisResidencia: 'Colombia',
            contrasena: 'carmen123',
            activo: true,
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
            updatedAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
        ];

        for (final user in sampleUsers) {
          await insertUser(user);
        }
      }
        
      print('✅ Datos de ejemplo inicializados');
    } catch (e) {
      print('⚠️ Error inicializando datos: $e');
    }
  }

  // Autenticación
  Future<User?> login(String email, String password) async {
    print('--- 🚀 Intentando iniciar sesión ---');
    print('📧 Email ingresado: $email');
    print('🔑 Contraseña ingresada: $password');

    try {
      final users = await getAllUsers();
      print('👥 Usuarios encontrados en localStorage: ${users.length}');
      
      for (var u in users) {
        print('  - Verificando: ${u.email} | ${u.contrasena} | Activo: ${u.activo}');
      }

      final user = users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase() && 
               u.contrasena == password && 
               u.activo,
        orElse: () {
          print('❌ Usuario no encontrado o credenciales incorrectas.');
          throw Exception('Usuario no encontrado');
        },
      );
      
      _currentUser = user;
      await _saveCurrentUser(user);
      print('✅ Login exitoso para: ${user.nombreCompleto}');
      return user;
    } catch (e) {
      print('❌ Error en login: $e');
      return null;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    if (kIsWeb) {
      html.window.localStorage.remove(_currentUserKey);
    }
  }

  User? get currentUser => _currentUser;

  Future<void> _saveCurrentUser(User user) async {
    if (kIsWeb) {
      html.window.localStorage[_currentUserKey] = json.encode(user.toMap());
    }
  }

  Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    
    if (kIsWeb) {
      final userJson = html.window.localStorage[_currentUserKey];
      if (userJson != null) {
        try {
          final userMap = json.decode(userJson) as Map<String, dynamic>;
          _currentUser = User.fromMap(userMap);
          return _currentUser;
        } catch (e) {
          print('❌ Error cargando usuario actual: $e');
        }
      }
    }
    return null;
  }

  // Guardar contactos
  Future<void> _saveContacts(List<Contact> contacts) async {
    try {
      if (kIsWeb) {
        final contactsJson = json.encode(contacts.map((c) => c.toMap()).toList());
        html.window.localStorage[_contactsKey] = contactsJson;
      } else {
        _memoryContacts = List.from(contacts);
      }
    } catch (e) {
      print('❌ Error guardando contactos: $e');
      _memoryContacts = List.from(contacts);
    }
  }

  // Guardar usuarios
  Future<void> _saveUsers(List<User> users) async {
    try {
      if (kIsWeb) {
        final usersJson = json.encode(users.map((u) => u.toMap()).toList());
        html.window.localStorage[_usersKey] = usersJson;
      } else {
        _memoryUsers = List.from(users);
      }
    } catch (e) {
      print('❌ Error guardando usuarios: $e');
      _memoryUsers = List.from(users);
    }
  }

  // CRUD para Contactos (existente)

  Future<List<Contact>> getAllContacts() async {
    try {
      if (kIsWeb) {
        final contactsJson = html.window.localStorage[_contactsKey];
        if (contactsJson == null) return [];

        final List<dynamic> contactsList = json.decode(contactsJson);
        return contactsList.map((json) => Contact.fromMap(json as Map<String, dynamic>)).toList();
      } else {
        return List.from(_memoryContacts);
      }
    } catch (e) {
      print('❌ Error obteniendo contactos: $e');
      return _memoryContacts;
    }
  }

  Future<int> insertContact(Contact contact) async {
    try {
      final contacts = await getAllContacts();
      final newId = contacts.isEmpty ? 1 : contacts.map((c) => c.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
      
      final newContact = contact.copyWith(
        id: newId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      contacts.add(newContact);
      await _saveContacts(contacts);
      return newId;
    } catch (e) {
      print('❌ Error insertando contacto: $e');
      rethrow;
    }
  }

  Future<bool> updateContact(Contact contact) async {
    try {
      final contacts = await getAllContacts();
      final index = contacts.indexWhere((c) => c.id == contact.id);
      
      if (index != -1) {
        contacts[index] = contact.copyWith(updatedAt: DateTime.now());
        await _saveContacts(contacts);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error actualizando contacto: $e');
      return false;
    }
  }

  Future<bool> deleteContact(int id) async {
    try {
      final contacts = await getAllContacts();
      contacts.removeWhere((contact) => contact.id == id);
      await _saveContacts(contacts);
      return true;
    } catch (e) {
      print('❌ Error eliminando contacto: $e');
      return false;
    }
  }

  // CRUD para Usuarios (nuevo)

  Future<List<User>> getAllUsers() async {
    try {
      if (kIsWeb) {
        final usersJson = html.window.localStorage[_usersKey];
        if (usersJson == null) return [];

        final List<dynamic> usersList = json.decode(usersJson);
        return usersList.map((json) => User.fromMap(json as Map<String, dynamic>)).toList();
      } else {
        return List.from(_memoryUsers);
      }
    } catch (e) {
      print('❌ Error obteniendo usuarios: $e');
      return _memoryUsers;
    }
  }

  Future<int> insertUser(User user) async {
    try {
      final users = await getAllUsers();
      final newId = users.isEmpty ? 1 : users.map((u) => u.idUsuario ?? 0).reduce((a, b) => a > b ? a : b) + 1;
      
      final newUser = user.copyWith(
        idUsuario: newId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      users.add(newUser);
      await _saveUsers(users);
      return newId;
    } catch (e) {
      print('❌ Error insertando usuario: $e');
      rethrow;
    }
  }

  Future<bool> updateUser(User user) async {
    try {
      final users = await getAllUsers();
      final index = users.indexWhere((u) => u.idUsuario == user.idUsuario);
      
      if (index != -1) {
        users[index] = user.copyWith(updatedAt: DateTime.now());
        await _saveUsers(users);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error actualizando usuario: $e');
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      final users = await getAllUsers();
      users.removeWhere((user) => user.idUsuario == id);
      await _saveUsers(users);
      return true;
    } catch (e) {
      print('❌ Error eliminando usuario: $e');
      return false;
    }
  }

  // Verificar si email ya existe
  Future<bool> emailExists(String email, {int? excludeUserId}) async {
    final users = await getAllUsers();
    return users.any((user) => 
      user.email.toLowerCase() == email.toLowerCase() && 
      user.idUsuario != excludeUserId
    );
  }

  // Limpiar todos los datos
  Future<void> clearAllData() async {
    try {
      if (kIsWeb) {
        html.window.localStorage.remove(_contactsKey);
        html.window.localStorage.remove(_usersKey);
        html.window.localStorage.remove(_currentUserKey);
      }
      _memoryContacts.clear();
      _memoryUsers.clear();
      _currentUser = null;
      print('🗑️ Todos los datos eliminados');
    } catch (e) {
      print('❌ Error limpiando datos: $e');
    }
  }
}
