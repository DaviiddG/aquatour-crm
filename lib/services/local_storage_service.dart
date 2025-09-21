import 'dart:convert';
import 'dart:html' as html;
import '../models/contact.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _contactsKey = 'aquatour_contacts';
  static const String _quotesKey = 'aquatour_quotes';
  static const String _reservationsKey = 'aquatour_reservations';

  // Inicializar con datos de ejemplo
  Future<void> initializeData() async {
    if (html.window.localStorage[_contactsKey] == null) {
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

      await _saveContacts(sampleContacts);
      print('✅ Datos de ejemplo inicializados en localStorage');
    }
  }

  // CRUD para Contactos

  Future<List<Contact>> getAllContacts() async {
    try {
      final contactsJson = html.window.localStorage[_contactsKey];
      if (contactsJson == null) return [];

      final List<dynamic> contactsList = json.decode(contactsJson);
      return contactsList.map((json) => Contact.fromMap(json)).toList();
    } catch (e) {
      print('❌ Error obteniendo contactos: $e');
      return [];
    }
  }

  Future<int> insertContact(Contact contact) async {
    try {
      final contacts = await getAllContacts();
      
      // Generar nuevo ID
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

  Future<void> _saveContacts(List<Contact> contacts) async {
    try {
      final contactsJson = json.encode(contacts.map((c) => c.toMap()).toList());
      html.window.localStorage[_contactsKey] = contactsJson;
    } catch (e) {
      print('❌ Error guardando contactos: $e');
      rethrow;
    }
  }

  // Limpiar todos los datos
  Future<void> clearAllData() async {
    html.window.localStorage.remove(_contactsKey);
    html.window.localStorage.remove(_quotesKey);
    html.window.localStorage.remove(_reservationsKey);
    print('🗑️ Todos los datos locales eliminados');
  }
}
