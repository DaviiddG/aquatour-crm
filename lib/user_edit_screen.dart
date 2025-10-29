import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquatour/models/user.dart';
import 'package:aquatour/services/storage_service.dart';
import 'package:aquatour/widgets/module_scaffold.dart';
import 'package:aquatour/utils/password_validator.dart';

class UserEditScreen extends StatefulWidget {
  const UserEditScreen({
    super.key,
    required this.user,
    required this.storageService,
    required this.onUpdated,
    this.currentUser,
  });

  final User user;
  final User? currentUser;
  final StorageService storageService;
  final Future<void> Function() onUpdated;

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _direccionController;
  late final TextEditingController _ciudadController;
  late final TextEditingController _paisController;
  late final TextEditingController _emailController;
  late final TextEditingController _numDocumentoController;
  late final TextEditingController _passwordController;

  late UserRole _rol;
  late String _tipoDocumento;
  late String _genero;
  late DateTime _fechaNacimiento;
  late bool _activo;
  late final String _originalEmail;

  bool _isSaving = false;

  static const List<String> _documentTypes = ['CC', 'CE', 'TI', 'PP'];
  static const List<String> _genders = ['Masculino', 'Femenino', 'Otro'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _nombreController = TextEditingController(text: widget.user.nombre);
    _apellidoController = TextEditingController(text: widget.user.apellido);
    _telefonoController = TextEditingController(text: widget.user.telefono);
    _direccionController = TextEditingController(text: widget.user.direccion);
    _ciudadController = TextEditingController(text: widget.user.ciudadResidencia);
    _paisController = TextEditingController(text: widget.user.paisResidencia);
    _emailController = TextEditingController(text: widget.user.email);
    _numDocumentoController =
        TextEditingController(text: widget.user.numDocumento);
    _passwordController = TextEditingController();

    _rol = widget.user.rol;
    _tipoDocumento = _documentTypes.contains(widget.user.tipoDocumento)
        ? widget.user.tipoDocumento
        : 'CC';
    _genero = _genders.contains(widget.user.genero)
        ? widget.user.genero
        : 'Otro';
    _fechaNacimiento = widget.user.fechaNacimiento;
    _activo = widget.user.activo;
    _originalEmail = widget.user.email;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _paisController.dispose();
    _emailController.dispose();
    _numDocumentoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canEditRole => widget.currentUser?.esSuperAdministrador ?? false;

  bool get _emailChanged =>
      _emailController.text.trim().toLowerCase() !=
      _originalEmail.trim().toLowerCase();

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisa los campos marcados antes de continuar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_emailChanged) {
      final exists = await widget.storageService.emailExists(
        _emailController.text.trim(),
        excludeUserId: widget.user.idUsuario,
      );
      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El correo ingresado ya está en uso.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    setState(() => _isSaving = true);

    final updatedUser = widget.user.copyWith(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      telefono: _telefonoController.text.trim(),
      direccion: _direccionController.text.trim(),
      ciudadResidencia: _ciudadController.text.trim(),
      paisResidencia: _paisController.text.trim(),
      email: _emailController.text.trim(),
      numDocumento: _numDocumentoController.text.trim(),
      tipoDocumento: _tipoDocumento,
      genero: _genero,
      fechaNacimiento: _fechaNacimiento,
      rol: _rol,
      activo: _activo,
      contrasena: _passwordController.text.isEmpty
          ? widget.user.contrasena
          : _passwordController.text,
      updatedAt: DateTime.now(),
    );

    try {
      final success = await widget.storageService.updateUser(updatedUser);
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (success) {
        await widget.onUpdated();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario actualizado correctamente.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No fue posible actualizar el usuario.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error actualizando usuario: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      title: 'Editar usuario',
      subtitle: widget.user.nombreCompleto,
      icon: Icons.manage_accounts_rounded,
      actions: [
        TextButton.icon(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
          label: const Text('Cerrar'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: const Color(0xFF3D1F6E),
                  labelColor: const Color(0xFF3D1F6E),
                  unselectedLabelColor: Colors.grey,
                  labelStyle: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Perfil'),
                    Tab(text: 'Identificación'),
                    Tab(text: 'Contacto'),
                    Tab(text: 'Credenciales'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPerfilTab(),
                  _buildIdentificacionTab(),
                  _buildContactoTab(),
                  _buildCredencialesTab(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              children: [
                OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveChanges,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_isSaving ? 'Guardando...' : 'Guardar cambios'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfilTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Información de perfil'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre *',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Ingresa el nombre.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _apellidoController,
            decoration: const InputDecoration(
              labelText: 'Apellido *',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Ingresa el apellido.' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<UserRole>(
            initialValue: _rol,
            decoration: const InputDecoration(
              labelText: 'Rol',
              border: OutlineInputBorder(),
            ),
            items: UserRole.values
                .map(
                  (role) => DropdownMenuItem<UserRole>(
                    value: role,
                    child: Text(role.displayName),
                  ),
                )
                .toList(),
            onChanged: _canEditRole
                ? (value) {
                    if (value != null) {
                      setState(() => _rol = value);
                    }
                  }
                : null,
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            value: _activo,
            title: const Text('Usuario activo'),
            contentPadding: EdgeInsets.zero,
            onChanged: (value) => setState(() => _activo = value),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentificacionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Documentos e identificación'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _tipoDocumento,
            decoration: const InputDecoration(
              labelText: 'Tipo de documento',
              border: OutlineInputBorder(),
            ),
            items: _documentTypes
                .map(
                  (value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _tipoDocumento = value);
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _numDocumentoController,
            decoration: const InputDecoration(
              labelText: 'Número de documento *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa el número de documento.';
              }
              if (int.tryParse(value) == null) {
                return 'Solo se permiten números.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _fechaNacimiento,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _fechaNacimiento = date);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha de nacimiento *',
                border: OutlineInputBorder(),
              ),
              child: Text(
                '${_fechaNacimiento.day.toString().padLeft(2, '0')}/'
                '${_fechaNacimiento.month.toString().padLeft(2, '0')}/'
                '${_fechaNacimiento.year}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _genero,
            decoration: const InputDecoration(
              labelText: 'Género',
              border: OutlineInputBorder(),
            ),
            items: _genders
                .map(
                  (value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _genero = value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Datos de contacto'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _telefonoController,
            decoration: const InputDecoration(
              labelText: 'Teléfono *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa el teléfono.';
              }
              final phoneRegExp = RegExp(r'^\+?[0-9\s]+$');
              if (!phoneRegExp.hasMatch(value)) {
                return 'Formato de teléfono no válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _direccionController,
            decoration: const InputDecoration(
              labelText: 'Dirección *',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Ingresa la dirección.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ciudadController,
            decoration: const InputDecoration(
              labelText: 'Ciudad *',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Ingresa la ciudad.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _paisController,
            decoration: const InputDecoration(
              labelText: 'País *',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Ingresa el país.' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCredencialesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Credenciales de acceso'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa el correo electrónico.';
              }
              final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegExp.hasMatch(value)) {
                return 'Formato de correo no válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: widget.user.idUsuario == null 
                  ? 'Contraseña *' 
                  : 'Nueva contraseña (opcional)',
              border: const OutlineInputBorder(),
              helperText: widget.user.idUsuario == null
                  ? PasswordValidator.getHelpText()
                  : 'Deja vacío si deseas mantener la contraseña actual.',
              helperMaxLines: 6,
            ),
            obscureText: true,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              // Si es un usuario nuevo, la contraseña es REQUERIDA y debe ser fuerte
              if (widget.user.idUsuario == null) {
                return PasswordValidator.validate(value, isRequired: true);
              }
              // Si es edición, la contraseña es OPCIONAL pero si se ingresa debe ser fuerte
              if (value != null && value.isNotEmpty) {
                return PasswordValidator.validate(value, isRequired: false);
              }
              return null;
            },
          ),
          // Indicador de fortaleza de contraseña
          const SizedBox(height: 12),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _passwordController,
            builder: (context, value, child) {
              print('🔍 Password value: "${value.text}" (length: ${value.text.length})');
              if (value.text.isEmpty) {
                print('❌ Password is empty, returning shrink');
                return const SizedBox.shrink();
              }
              final strength = PasswordValidator.getStrength(value.text);
              print('✅ Building indicator with strength: $strength');
              return _buildPasswordStrengthIndicator(strength, value.text);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(int strength, String password) {
    print('🎨 Building indicator widget for password: "$password", strength: $strength');
    
    // Determinar color y texto según fortaleza
    Color barColor;
    String strengthText;
    double progress;

    switch (strength) {
      case 0:
      case 1:
        barColor = Colors.red;
        strengthText = 'Muy débil';
        progress = 0.2;
        break;
      case 2:
        barColor = Colors.orange;
        strengthText = 'Débil';
        progress = 0.4;
        break;
      case 3:
        barColor = Colors.yellow.shade700;
        strengthText = 'Aceptable';
        progress = 0.6;
        break;
      case 4:
        barColor = Colors.lightGreen;
        strengthText = 'Fuerte';
        progress = 0.8;
        break;
      case 5:
        barColor = Colors.green;
        strengthText = 'Muy fuerte';
        progress = 1.0;
        break;
      default:
        barColor = Colors.grey;
        strengthText = '';
        progress = 0.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              strengthText,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: barColor,
              ),
            ),
          ],
        ),
        if (strength < 5) ...[
          const SizedBox(height: 4),
          Text(
            _getPasswordStrengthHint(password),
            style: GoogleFonts.montserrat(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  String _getPasswordStrengthHint(String password) {
    
    if (password.length < 8) {
      return 'Agrega más caracteres (mínimo 8)';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Agrega al menos una letra mayúscula';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Agrega al menos una letra minúscula';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Agrega al menos un número';
    }
    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return 'Agrega al menos un carácter especial (!@#\$%^&*...)';
    }
    
    return '';
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF3D1F6E),
      ),
    );
  }
}
