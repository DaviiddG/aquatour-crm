import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../widgets/unsaved_changes_dialog.dart';

class UserEditScreen extends StatefulWidget {
  final User? user;

  const UserEditScreen({super.key, this.user});

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();

  late TextEditingController _emailController;
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _numDocumentoController;
  late TextEditingController _telefonoController;
  late TextEditingController _direccionController;
  late TextEditingController _ciudadController;
  late TextEditingController _paisController;
  late TextEditingController _contrasenaController;

  late String _tipoDocumento;
  late String _genero;
  late UserRole _rol;
  late bool _activo;
  late DateTime _fechaNacimiento;

  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String? _documentError;
  bool _isCheckingDocument = false;
  String? _phoneError;
  bool _isCheckingPhone = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _nombreController = TextEditingController(text: widget.user?.nombre ?? '');
    _apellidoController = TextEditingController(text: widget.user?.apellido ?? '');
    _numDocumentoController = TextEditingController(text: widget.user?.numDocumento ?? '');
    _telefonoController = TextEditingController(text: widget.user?.telefono ?? '');
    _direccionController = TextEditingController(text: widget.user?.direccion ?? '');
    _ciudadController = TextEditingController(text: widget.user?.ciudadResidencia ?? '');
    _paisController = TextEditingController(text: widget.user?.paisResidencia ?? '');
    _contrasenaController = TextEditingController();

    _tipoDocumento = widget.user?.tipoDocumento ?? 'CC';
    _genero = widget.user?.genero ?? 'Masculino';
    _rol = widget.user?.rol ?? UserRole.empleado;
    _activo = widget.user?.activo ?? true;
    _fechaNacimiento = widget.user?.fechaNacimiento ?? DateTime.now().subtract(const Duration(days: 365 * 25));

    // Agregar listeners
    _emailController.addListener(_markAsChanged);
    _nombreController.addListener(_markAsChanged);
    _apellidoController.addListener(_markAsChanged);
    _numDocumentoController.addListener(_onDocumentChanged);
    _telefonoController.addListener(_onPhoneChanged);
    _direccionController.addListener(_markAsChanged);
    _ciudadController.addListener(_markAsChanged);
    _paisController.addListener(_markAsChanged);
    _contrasenaController.addListener(_markAsChanged);
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _onDocumentChanged() {
    _markAsChanged();
    _checkDocumentExists();
  }

  Future<void> _checkDocumentExists() async {
    final doc = _numDocumentoController.text.trim();
    if (doc.isEmpty) {
      setState(() {
        _documentError = null;
        _isCheckingDocument = false;
      });
      return;
    }

    setState(() => _isCheckingDocument = true);

    try {
      final result = await _storageService.documentExists(
        doc,
        excludeUserId: widget.user?.idUsuario,
      );

      if (mounted) {
        setState(() {
          if (result['exists'] == true) {
            final user = result['user'];
            if (user != null) {
              _documentError = 'Este documento ya está registrado para ${user['nombre']} ${user['apellido']}';
            } else {
              _documentError = 'Este documento ya está registrado en el sistema';
            }
          } else {
            _documentError = null;
          }
          _isCheckingDocument = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _documentError = null;
          _isCheckingDocument = false;
        });
      }
    }
  }

  void _onPhoneChanged() {
    _markAsChanged();
    _checkPhoneExists();
  }

  Future<void> _checkPhoneExists() async {
    final phone = _telefonoController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _phoneError = null;
        _isCheckingPhone = false;
      });
      return;
    }

    setState(() => _isCheckingPhone = true);

    try {
      final result = await _storageService.phoneExists(
        phone,
        excludeUserId: widget.user?.idUsuario,
      );

      if (mounted) {
        setState(() {
          if (result['exists'] == true) {
            final user = result['user'];
            if (user != null) {
              _phoneError = 'Este teléfono ya está registrado para ${user['nombre']} ${user['apellido']}';
            } else {
              _phoneError = 'Este teléfono ya está registrado en el sistema';
            }
          } else {
            _phoneError = null;
          }
          _isCheckingPhone = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phoneError = null;
          _isCheckingPhone = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _numDocumentoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _paisController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar que no haya error de documento
    if (_documentError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_documentError!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar que no haya error de teléfono
    if (_phoneError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_phoneError!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = User(
        idUsuario: widget.user?.idUsuario,
        email: _emailController.text.trim(),
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        numDocumento: _numDocumentoController.text.trim(),
        tipoDocumento: _tipoDocumento,
        telefono: _telefonoController.text.trim(),
        direccion: _direccionController.text.trim(),
        ciudadResidencia: _ciudadController.text.trim(),
        paisResidencia: _paisController.text.trim(),
        genero: _genero,
        fechaNacimiento: _fechaNacimiento,
        rol: _rol,
        contrasena: widget.user != null && _contrasenaController.text.isEmpty
            ? widget.user!.contrasena
            : _contrasenaController.text,
        activo: _activo,
        createdAt: widget.user?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.user == null) {
        await _storageService.insertUser(user);
      } else {
        await _storageService.updateUser(user);
      }

      setState(() => _hasUnsavedChanges = false);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario guardado exitosamente'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error guardando usuario: $e';
        if (e.toString().contains('documento ya está registrado')) {
          errorMessage = 'El número de documento ya está registrado en el sistema';
        } else if (e.toString().contains('email ya está registrado')) {
          errorMessage = 'El email ya está registrado en el sistema';
        } else if (e.toString().contains('teléfono ya está registrado')) {
          errorMessage = 'El número de teléfono ya está registrado en el sistema';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    
    final shouldPop = await showUnsavedChangesDialog(
      context,
      onSave: _saveUser,
    );
    
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF3D1F6E)),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.of(context).pop();
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Editar Usuario' : 'Nuevo Usuario',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 18, color: const Color(0xFF1F1F1F)),
              ),
              Text(
                'Gestión de credenciales y permisos',
                style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: Colors.grey[200], height: 1),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSection(
                title: 'Información de Acceso',
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email (Login) *',
                      labelStyle: GoogleFonts.montserrat(fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.email, size: 20),
                    ),
                    style: GoogleFonts.montserrat(fontSize: 14),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'El email es obligatorio';
                      if (!value!.contains('@')) return 'Email inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contrasenaController,
                    decoration: InputDecoration(
                      labelText: isEditing ? 'Nueva Contraseña (dejar vacío para mantener)' : 'Contraseña *',
                      labelStyle: GoogleFonts.montserrat(fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.lock, size: 20),
                    ),
                    style: GoogleFonts.montserrat(fontSize: 14),
                    obscureText: true,
                    validator: (value) {
                      if (!isEditing && (value?.isEmpty ?? true)) {
                        return 'La contraseña es obligatoria';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UserRole>(
                    value: _rol,
                    decoration: InputDecoration(
                      labelText: 'Rol *',
                      labelStyle: GoogleFonts.montserrat(fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.admin_panel_settings, size: 20),
                    ),
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.displayName, style: GoogleFonts.montserrat(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _rol = value!);
                      _markAsChanged();
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Estado:', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Switch(
                        value: _activo,
                        onChanged: (value) {
                          setState(() => _activo = value);
                          _markAsChanged();
                        },
                        activeColor: const Color(0xFF1B8D5E),
                      ),
                      Text(
                        _activo ? 'Activo' : 'Inactivo',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _activo ? const Color(0xFF1B8D5E) : const Color(0xFFB3261E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Información Personal',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre *',
                            labelStyle: GoogleFonts.montserrat(fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.person, size: 20),
                          ),
                          style: GoogleFonts.montserrat(fontSize: 14),
                          validator: (value) => value?.isEmpty ?? true ? 'El nombre es obligatorio' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _apellidoController,
                          decoration: InputDecoration(
                            labelText: 'Apellido *',
                            labelStyle: GoogleFonts.montserrat(fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.person_outline, size: 20),
                          ),
                          style: GoogleFonts.montserrat(fontSize: 14),
                          validator: (value) => value?.isEmpty ?? true ? 'El apellido es obligatorio' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _tipoDocumento,
                          decoration: InputDecoration(
                            labelText: 'Tipo Doc',
                            labelStyle: GoogleFonts.montserrat(fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: ['CC', 'CE', 'PA', 'TI'].map((tipo) {
                            return DropdownMenuItem(
                              value: tipo,
                              child: Text(tipo, style: GoogleFonts.montserrat(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _tipoDocumento = value!);
                            _markAsChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _numDocumentoController,
                              decoration: InputDecoration(
                                labelText: 'Número de Documento *',
                                labelStyle: GoogleFonts.montserrat(fontSize: 13),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: _documentError != null ? Colors.red : Colors.grey,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: _documentError != null ? Colors.red : Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: _documentError != null ? Colors.red : const Color(0xFF3D1F6E),
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(Icons.badge, size: 20),
                                suffixIcon: _isCheckingDocument
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                    : _documentError != null
                                        ? const Icon(Icons.error, color: Colors.red, size: 20)
                                        : _numDocumentoController.text.isNotEmpty
                                            ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                                            : null,
                              ),
                              style: GoogleFonts.montserrat(fontSize: 14),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) => value?.isEmpty ?? true ? 'El documento es obligatorio' : null,
                            ),
                            if (_documentError != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _documentError!,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _telefonoController,
                        decoration: InputDecoration(
                          labelText: 'Teléfono *',
                          labelStyle: GoogleFonts.montserrat(fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _phoneError != null ? Colors.red : Colors.grey,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _phoneError != null ? Colors.red : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _phoneError != null ? Colors.red : const Color(0xFF3D1F6E),
                              width: 2,
                            ),
                          ),
                          prefixIcon: const Icon(Icons.phone, size: 20),
                          suffixIcon: _isCheckingPhone
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : _phoneError != null
                                  ? const Icon(Icons.error, color: Colors.red, size: 20)
                                  : _telefonoController.text.isNotEmpty
                                      ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                                      : null,
                        ),
                        style: GoogleFonts.montserrat(fontSize: 14),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        validator: (value) => value?.isEmpty ?? true ? 'El teléfono es obligatorio' : null,
                      ),
                      if (_phoneError != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _phoneError!,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _genero,
                    decoration: InputDecoration(
                      labelText: 'Género',
                      labelStyle: GoogleFonts.montserrat(fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.wc, size: 20),
                    ),
                    items: ['Masculino', 'Femenino', 'Otro'].map((genero) {
                      return DropdownMenuItem(
                        value: genero,
                        child: Text(genero, style: GoogleFonts.montserrat(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _genero = value!);
                      _markAsChanged();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Ubicación',
                children: [
                  TextFormField(
                    controller: _direccionController,
                    decoration: InputDecoration(
                      labelText: 'Dirección',
                      labelStyle: GoogleFonts.montserrat(fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.home, size: 20),
                    ),
                    style: GoogleFonts.montserrat(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ciudadController,
                          decoration: InputDecoration(
                            labelText: 'Ciudad',
                            labelStyle: GoogleFonts.montserrat(fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.location_city, size: 20),
                          ),
                          style: GoogleFonts.montserrat(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _paisController,
                          decoration: InputDecoration(
                            labelText: 'País',
                            labelStyle: GoogleFonts.montserrat(fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.flag, size: 20),
                          ),
                          style: GoogleFonts.montserrat(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D1F6E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(
                    _isSaving ? 'Guardando...' : (isEditing ? 'Actualizar' : 'Crear Usuario'),
                    style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF3D1F6E)),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}
