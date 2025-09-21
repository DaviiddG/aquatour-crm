class Contact {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String company;
  final DateTime createdAt;
  final DateTime updatedAt;

  Contact({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convertir de Map (base de datos) a Contact
  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()),
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      company: map['company']?.toString() ?? '',
      createdAt: map['created_at'] is DateTime 
          ? map['created_at'] 
          : DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: map['updated_at'] is DateTime 
          ? map['updated_at'] 
          : DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  // Convertir de Contact a Map (para guardar en base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Crear copia con cambios
  Contact copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? company,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Contact{id: $id, name: $name, email: $email, phone: $phone, company: $company}';
  }
}
