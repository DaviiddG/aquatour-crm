import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquatour/widgets/module_scaffold.dart';

/// Modelo de datos para representar un cliente
class ClientModel {
  final String id;
  final String nombres;
  final String apellidos;
  final String email;
  final String telefono;
  final String documento;
  final String nacionalidad;
  final String pasaporte;
  final String estadoCivil;
  final String preferenciasViaje;
  final int satisfaccion;

  const ClientModel({
    this.id = '',
    required this.nombres,
    required this.apellidos,
    required this.email,
    required this.telefono,
    required this.documento,
    required this.nacionalidad,
    required this.pasaporte,
    required this.estadoCivil,
    required this.preferenciasViaje,
    required this.satisfaccion,
  });

  /// Crea un ClientModel desde un mapa JSON
  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id']?.toString() ?? '',
      nombres: json['nombres']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? '',
      documento: json['documento']?.toString() ?? '',
      nacionalidad: json['nacionalidad']?.toString() ?? 'Perú',
      pasaporte: json['pasaporte']?.toString() ?? '',
      estadoCivil: json['estado_civil']?.toString() ?? 'Soltero/a',
      preferenciasViaje: json['preferencias_viaje']?.toString() ?? '',
      satisfaccion: json['satisfaccion']?.toInt() ?? 3,
    );
  }

  /// Convierte el ClientModel a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombres': nombres,
      'apellidos': apellidos,
      'email': email,
      'telefono': telefono,
      'documento': documento,
      'nacionalidad': nacionalidad,
      'pasaporte': pasaporte,
      'estado_civil': estadoCivil,
      'preferencias_viaje': preferenciasViaje,
      'satisfaccion': satisfaccion,
    };
  }
}

/// Pantalla para crear o editar clientes
class ClientEditScreen extends StatefulWidget {
  final ClientModel? clientData;
  final Function(ClientModel) onSave;

  const ClientEditScreen({
    Key? key,
    this.clientData,
    required this.onSave,
  }) : super(key: key);

  @override
  _ClientEditScreenState createState() => _ClientEditScreenState();
}

/// Estado de la pantalla de edición de clientes
class _ClientEditScreenState extends State<ClientEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para los campos del formulario
  late TextEditingController _nombresController;
  late TextEditingController _apellidosController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _documentoController;
  late TextEditingController _nacionalidadController;
  late TextEditingController _pasaporteController;
  late TextEditingController _preferenciasViajeController;
  
  // Estado del formulario
  String _estadoCivil = 'Soltero/a';
  int _satisfaccion = 3; // Valor por defecto para satisfacción (escala 1-5)
  
  // Lista de opciones para los selectores
  final List<String> _estadosCiviles = [
    'Soltero/a',
    'Casado/a',
    'Divorciado/a',
    'Viudo/a',
    'Unión Libre'
  ];
  
  final List<String> _nacionalidades = [
    'Perú',
    'Argentina',
    'Chile',
    'Colombia',
    'Ecuador',
    'Estados Unidos',
    'España',
    'México',
    'Brasil',
    'Otro'
  ];

  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores con datos existentes o valores por defecto
    _nombresController = TextEditingController(text: widget.clientData?.nombres ?? '');
    _apellidosController = TextEditingController(text: widget.clientData?.apellidos ?? '');
    _emailController = TextEditingController(text: widget.clientData?.email ?? '');
    _telefonoController = TextEditingController(text: widget.clientData?.telefono ?? '');
    _documentoController = TextEditingController(text: widget.clientData?.documento ?? '');
    _nacionalidadController = TextEditingController(text: widget.clientData?.nacionalidad ?? 'Perú');
    _pasaporteController = TextEditingController(text: widget.clientData?.pasaporte ?? '');
    _preferenciasViajeController = TextEditingController(text: widget.clientData?.preferenciasViaje ?? '');
    
    // Inicializar valores de estado
    _estadoCivil = widget.clientData?.estadoCivil ?? 'Soltero/a';
    _satisfaccion = widget.clientData?.satisfaccion ?? 3;
  }

  @override
  void dispose() {
    // Liberar controladores para evitar memory leaks
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _documentoController.dispose();
    _nacionalidadController.dispose();
    _pasaporteController.dispose();
    _preferenciasViajeController.dispose();
    super.dispose();
  }

  /// Guarda los datos del formulario
  Future<void> _submit() async {
    // Validar formulario - verifica que todos los campos requeridos estén llenos
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete todos los campos requeridos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Crear el modelo de cliente con los datos del formulario
      final client = ClientModel(
        id: widget.clientData?.id ?? '',
        nombres: _nombresController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        email: _emailController.text.trim(),
        telefono: _telefonoController.text.trim(),
        documento: _documentoController.text.trim(),
        nacionalidad: _nacionalidadController.text.trim(),
        pasaporte: _pasaporteController.text.trim(),
        estadoCivil: _estadoCivil,
        preferenciasViaje: _preferenciasViajeController.text.trim(),
        satisfaccion: _satisfaccion,
      );

      // Cerrar el diálogo de carga
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Guardar el cliente usando la función proporcionada por el padre
      await widget.onSave(client);
    } catch (e) {
      // Cerrar el diálogo de carga si hay un error
      if (mounted) {
        Navigator.of(context).pop();

        // Mostrar mensaje de error más específico
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      title: widget.clientData == null ? 'Nuevo Cliente' : 'Editar Cliente',
      subtitle: 'Gestión de clientes',
      icon: Icons.person_outline,
      actions: [],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submit,
        backgroundColor: const Color(0xFF3D1F6E),
        label: const Text('Guardar', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.save, color: Colors.white),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Información Personal'),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Nombres',
                controller: _nombresController,
                isRequired: true,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: 'Apellidos',
                controller: _apellidosController,
                isRequired: true,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: 'Email',
                controller: _emailController,
                isRequired: true,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: 'Teléfono',
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: 'Documento de Identidad',
                controller: _documentoController,
                isRequired: true,
              ),
              const SizedBox(height: 12),
              _buildDropdownField<String>(
                label: 'Nacionalidad',
                value: _nacionalidadController.text.isNotEmpty ? _nacionalidadController.text : 'Perú',
                items: _nacionalidades.map((nacionalidad) {
                  return DropdownMenuItem(
                    value: nacionalidad,
                    child: Text(nacionalidad),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _nacionalidadController.text = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: 'Número de Pasaporte',
                controller: _pasaporteController,
              ),
              const SizedBox(height: 12),
              _buildDropdownField<String>(
                label: 'Estado Civil',
                value: _estadoCivil,
                items: _estadosCiviles.map((estado) {
                  return DropdownMenuItem(
                    value: estado,
                    child: Text(estado),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _estadoCivil = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Preferencias de Viaje'),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Preferencias de Viaje',
                controller: _preferenciasViajeController,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _buildDropdownField<int>(
                label: 'Nivel de Satisfacción (1-5)',
                value: _satisfaccion,
                items: List.generate(5, (index) {
                  final value = index + 1;
                  return DropdownMenuItem(
                    value: value,
                    child: Text('$value ${'⭐' * value}'),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _satisfaccion = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye un título de sección
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  /// Construye un campo de texto con estilos personalizados
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF3D1F6E), width: 2.0),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.red, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.red, width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (value) {
          // Validar campos requeridos - verifica tanto null como cadena vacía
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Este campo es obligatorio';
          }
          // Validar formato de email solo si hay contenido
          if (keyboardType == TextInputType.emailAddress && value != null && value.isNotEmpty) {
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Ingrese un email válido';
            }
          }
          return null;
        },
      ),
    );
  }

  /// Construye un campo desplegable con estilos personalizados
  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRequired ? '$label *' : label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Color(0xFF3D1F6E), width: 2.0),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Colors.red, width: 1.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Colors.red, width: 2.0),
              ),
            ),
            validator: (value) {
              if (isRequired && (value == null || value.toString().isEmpty)) {
                return 'Este campo es obligatorio';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}