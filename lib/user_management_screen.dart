import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquatour/models/user.dart';
import 'package:aquatour/services/storage_service.dart';
import 'package:aquatour/widgets/module_scaffold.dart';
import 'package:aquatour/user_edit_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final StorageService _storageService = StorageService();
  List<User> _users = [];
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  bool _canEditUser(User? user) {
    if (_currentUser == null) return false;

    if (user == null) {
      // Crear nuevo usuario
      return _currentUser!.esSuperAdministrador || _currentUser!.rol == UserRole.administrador;
    }

    if (_currentUser!.idUsuario == user.idUsuario) {
      return true;
    }

    if (_currentUser!.esSuperAdministrador) {
      return true;
    }

    if (_currentUser!.rol == UserRole.administrador) {
      return user.rol == UserRole.empleado;
    }

    return false;
  }

  bool _canDeleteUser(User user) {
    if (_currentUser == null) return false;

    if (_currentUser!.esSuperAdministrador) {
      return true;
    }

    if (_currentUser!.rol == UserRole.administrador) {
      return user.rol == UserRole.empleado;
    }

    return false;
  }

  Future<void> _initializeData() async {
    await _loadCurrentUser();
    await _loadUsers();
  }

  Future<void> _loadCurrentUser() async {
    _currentUser = await _storageService.getCurrentUser();
    if (mounted) {
      setState(() {}); // Actualizar el estado para reflejar los cambios
    }
  }

  Future<void> _loadUsers() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final users = await _storageService.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando usuarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openEditScreen(User user) async {
    if (!_canEditUser(user)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes editar usuarios con un rol igual o superior al tuyo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserEditScreen(
          user: user,
          currentUser: _currentUser,
          storageService: _storageService,
          onUpdated: () async {
            await _loadUsers();
          },
        ),
      ),
    );
  }

  Future<void> _showUserDialog({User? userToEdit}) async {
    if (_currentUser?.puedeGestionarUsuarios != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para gestionar usuarios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_canEditUser(userToEdit)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes editar usuarios con un rol igual o superior al tuyo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final isEditing = userToEdit != null;
    final formKey = GlobalKey<FormState>();
    
    final nombreController = TextEditingController(text: userToEdit?.nombre ?? '');
    final apellidoController = TextEditingController(text: userToEdit?.apellido ?? '');
    final emailController = TextEditingController(text: userToEdit?.email ?? '');
    final numDocumentoController = TextEditingController(text: userToEdit?.numDocumento ?? '');
    final telefonoController = TextEditingController(text: userToEdit?.telefono ?? '');
    final direccionController = TextEditingController(text: userToEdit?.direccion ?? '');
    final ciudadController = TextEditingController(text: userToEdit?.ciudadResidencia ?? '');
    final paisController = TextEditingController(text: userToEdit?.paisResidencia ?? '');
    final contrasenaController = TextEditingController();
    
    String tipoDocumento = userToEdit?.tipoDocumento ?? 'CC';
    String genero = userToEdit?.genero ?? 'Masculino';
    UserRole rol = userToEdit?.rol ?? UserRole.empleado;
    bool activo = userToEdit?.activo ?? true;
    DateTime fechaNacimiento = userToEdit?.fechaNacimiento ?? DateTime.now().subtract(const Duration(days: 365 * 25));

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar Usuario' : 'Agregar Usuario'),
              content: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 500,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Email y Rol
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email (Login) *',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email es obligatorio';
                                  }
                                  final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                  if (!emailRegExp.hasMatch(value)) {
                                    return 'Formato de email no válido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: DropdownButtonFormField<UserRole>(
                                isExpanded: true,
                                value: rol,
                                decoration: const InputDecoration(
                                  labelText: 'Rol *',
                                  border: OutlineInputBorder(),
                                ),
                                items: UserRole.values.map((UserRole role) => 
                                  DropdownMenuItem<UserRole>(
                                    value: role,
                                    child: Text(
                                      role.displayName,
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ).toList(),
                                onChanged: (UserRole? value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      rol = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Nombre y Apellido
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: nombreController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) => value!.isEmpty ? 'Nombre es obligatorio' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: apellidoController,
                                decoration: const InputDecoration(
                                  labelText: 'Apellido *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) => value!.isEmpty ? 'Apellido es obligatorio' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Tipo y Número de Documento
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: DropdownButtonFormField<String>(
                                value: tipoDocumento,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo Doc.',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'CC', child: Text('CC')),
                                  DropdownMenuItem(value: 'CE', child: Text('CE')),
                                  DropdownMenuItem(value: 'TI', child: Text('TI')),
                                  DropdownMenuItem(value: 'PP', child: Text('PP')),
                                ],
                                onChanged: (value) {
                                  setDialogState(() {
                                    tipoDocumento = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: numDocumentoController,
                                decoration: const InputDecoration(
                                  labelText: 'Número de Documento *',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Este campo es obligatorio';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Solo se permiten números';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Fecha de Nacimiento y Género
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: fechaNacimiento,
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setDialogState(() {
                                      fechaNacimiento = date;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Fecha de Nacimiento *',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    '${fechaNacimiento.day}/${fechaNacimiento.month}/${fechaNacimiento.year}',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: genero,
                                decoration: const InputDecoration(
                                  labelText: 'Género',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                                  DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
                                  DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                                ],
                                onChanged: (value) {
                                  setDialogState(() {
                                    genero = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Teléfono y Estado
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: telefonoController,
                                decoration: const InputDecoration(
                                  labelText: 'Teléfono *',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Este campo es obligatorio';
                                  }
                                  final phoneRegExp = RegExp(r'^\+?[0-9\s]+$');
                                  if (!phoneRegExp.hasMatch(value)) {
                                    return 'Formato no válido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Row(
                                children: [
                                  const Text('Activo'),
                                  const SizedBox(width: 10),
                                  Switch(
                                    value: activo,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        activo = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Dirección
                        TextFormField(
                          controller: direccionController,
                          decoration: const InputDecoration(
                            labelText: 'Dirección *',
                            border: OutlineInputBorder(),
                          ),
                           validator: (value) => value!.isEmpty ? 'Dirección es obligatoria' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        // Ciudad y País
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: ciudadController,
                                decoration: const InputDecoration(
                                  labelText: 'Ciudad *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) => value!.isEmpty ? 'Ciudad es obligatoria' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: paisController,
                                decoration: const InputDecoration(
                                  labelText: 'País *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) => value!.isEmpty ? 'País es obligatorio' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Contraseña
                        TextFormField(
                          controller: contrasenaController,
                          decoration: InputDecoration(
                            labelText: isEditing ? 'Nueva Contraseña (opcional)' : 'Contraseña *',
                            border: const OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (!isEditing && (value == null || value.isEmpty)) {
                              return 'Contraseña es obligatoria';
                            }
                            if (value != null && value.isNotEmpty && value.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text(isEditing ? 'Actualizar' : 'Guardar'),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor corrige los errores en el formulario'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    final emailExists = await _storageService.emailExists(
                      emailController.text, 
                      excludeUserId: userToEdit?.idUsuario,
                    );
                    
                    if (emailExists) {
                      if(mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Este email ya está en uso'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }
                    
                    final userData = User(
                      idUsuario: userToEdit?.idUsuario,
                      nombre: nombreController.text,
                      apellido: apellidoController.text,
                      email: emailController.text,
                      rol: rol,
                      tipoDocumento: tipoDocumento,
                      numDocumento: numDocumentoController.text,
                      fechaNacimiento: fechaNacimiento,
                      genero: genero,
                      telefono: telefonoController.text,
                      direccion: direccionController.text,
                      ciudadResidencia: ciudadController.text,
                      paisResidencia: paisController.text,
                      contrasena: isEditing && contrasenaController.text.isEmpty 
                          ? userToEdit!.contrasena 
                          : contrasenaController.text,
                      activo: activo,
                      createdAt: userToEdit?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    try {
                      if (isEditing) {
                        await _storageService.updateUser(userData);
                      } else {
                        await _storageService.insertUser(userData);
                      }
                      
                      if(mounted) Navigator.of(context).pop();
                      await _loadUsers();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEditing 
                                ? 'Usuario actualizado exitosamente' 
                                : 'Usuario agregado exitosamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error ${isEditing ? 'actualizando' : 'agregando'} usuario: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canManage = _currentUser?.puedeGestionarUsuarios == true;

    return ModuleScaffold(
      title: 'Gestión de usuarios',
      subtitle: 'Administra credenciales, roles y estado del equipo',
      icon: Icons.admin_panel_settings_rounded,
      actions: [
        IconButton(
          tooltip: 'Actualizar lista',
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF3D1F6E)),
          onPressed: _loadUsers,
        ),
      ],
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showUserDialog(),
              backgroundColor: const Color(0xFFf7941e),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuevo usuario'),
            )
          : null,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? _EmptyUsersState(onCreate: canManage ? () => _showUserDialog() : null)
              : _UserBoard(
                  currentUser: _currentUser,
                  users: _users,
                  roleColorResolver: _getRoleColor,
                  canEdit: _canEditUser,
                  canDelete: _canDeleteUser,
                  onEdit: (user) => _openEditScreen(user),
                  onDelete: (user) => _deleteUser(user),
                ),
    );
  }

  Future<void> _deleteUser(User user) async {
    if (_currentUser?.puedeGestionarUsuarios != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para eliminar usuarios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentUser?.idUsuario == user.idUsuario) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes eliminarte a ti mismo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_canDeleteUser(user)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes eliminar usuarios con un rol igual o superior al tuyo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que quieres eliminar a ${user.nombreCompleto}?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true && user.idUsuario != null) {
      try {
        await _storageService.deleteUser(user.idUsuario!);
        await _loadUsers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error eliminando usuario: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superadministrador:
        return const Color(0xFF3D1F6E);
      case UserRole.administrador:
        return const Color(0xFFfdb913);
      case UserRole.empleado:
        return const Color(0xFF4B4B4B);
    }
  }
}

class _UserBoard extends StatelessWidget {
  const _UserBoard({
    required this.currentUser,
    required this.users,
    required this.roleColorResolver,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  final User? currentUser;
  final List<User> users;
  final Color Function(UserRole) roleColorResolver;
  final bool Function(User?) canEdit;
  final bool Function(User) canDelete;
  final void Function(User) onEdit;
  final void Function(User) onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1280
            ? 3
            : constraints.maxWidth >= 900
                ? 2
                : 1;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CurrentUserBanner(currentUser: currentUser, totalUsers: users.length),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: crossAxisCount == 1 ? 16 / 9 : 18 / 10,
                ),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _UserCard(
                    user: user,
                    roleColor: roleColorResolver(user.rol),
                    canEdit: canEdit(user),
                    canDelete: canDelete(user),
                    onEdit: () => onEdit(user),
                    onDelete: () => onDelete(user),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.roleColor,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  final User user;
  final Color roleColor;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasEditAction = canEdit && onEdit != null;
    final hasDeleteAction = canDelete && onDelete != null;
    final actionButtons = <Widget>[
      if (hasEditAction)
        IconButton(
          tooltip: 'Editar usuario',
          icon: const Icon(Icons.edit_rounded, color: Color(0xFF2C53A4)),
          onPressed: onEdit,
        ),
      if (hasDeleteAction)
        IconButton(
          tooltip: 'Eliminar usuario',
          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFB3261E)),
          onPressed: onDelete,
        ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: roleColor.withOpacity(0.12),
                  child: Text(
                    user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: roleColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nombreCompleto,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F1F1F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF6F6F6F)),
                      ),
                    ],
                  ),
                ),
                _UserRoleBadge(role: user.rol, color: roleColor),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _InfoChip(icon: Icons.perm_identity_rounded, label: user.numDocumento),
                _InfoChip(icon: Icons.phone_rounded, label: user.telefono),
                _InfoChip(icon: Icons.location_city_rounded, label: user.ciudadResidencia),
                _InfoChip(icon: Icons.flag_rounded, label: user.paisResidencia),
                _InfoChip(icon: Icons.cake_rounded, label: '${user.edad} años'),
                _InfoChip(icon: Icons.badge_rounded, label: user.tipoDocumento),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  user.activo ? 'Activo' : 'Inactivo',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    color: user.activo ? const Color(0xFF1B8D5E) : const Color(0xFFB3261E),
                  ),
                ),
                actionButtons.isEmpty
                    ? const SizedBox.shrink()
                    : Row(children: actionButtons),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentUserBanner extends StatelessWidget {
  const _CurrentUserBanner({required this.currentUser, required this.totalUsers});

  final User? currentUser;
  final int totalUsers;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D1F6E), Color(0xFF2C53A4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C53A4).withOpacity(0.24),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUser!.nombreCompleto,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tu rol: ${currentUser!.rol.displayName} • Usuarios registrados: $totalUsers',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyUsersState extends StatelessWidget {
  const _EmptyUsersState({this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF3D1F6E).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group_add_rounded, size: 56, color: Color(0xFF3D1F6E)),
          ),
          const SizedBox(height: 18),
          Text(
            'Aún no hay usuarios registrados',
            style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea el primer usuario para comenzar a gestionar accesos y permisos.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF6F6F6F)),
          ),
          const SizedBox(height: 20),
          if (onCreate != null)
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar usuario'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFf7941e),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6F6F6F)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF4B4B4B)),
          ),
        ],
      ),
    );
  }
}

class _UserRoleBadge extends StatelessWidget {
  const _UserRoleBadge({required this.role, required this.color});

  final UserRole role;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.displayName,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
