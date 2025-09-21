import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquatour/models/user.dart';
import 'package:aquatour/services/storage_service.dart';

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
        return const Color(0xFF3D1F6E); // Morado oscuro de Aquatour
      case UserRole.administrador:
        return const Color(0xFFfdb913); // Amarillo de Aquatour
      case UserRole.empleado:
        return Colors.grey; // Gris para empleados
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: const Color(0xFF3D1F6E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _users.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay usuarios registrados',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Agrega el primer usuario usando el botón +',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ExpansionTile(
                        leading: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor: _getRoleColor(user.rol),
                              child: Text(
                                user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!user.activo)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 8),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          user.nombreCompleto,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(user.rol),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    user.rol.displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${user.tipoDocumento}: ${user.numDocumento} • ${user.edad} años'),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_currentUser?.puedeGestionarUsuarios == true)
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  _showUserDialog(userToEdit: user);
                                },
                              ),
                            if (_currentUser?.puedeGestionarUsuarios == true && 
                                _currentUser?.idUsuario != user.idUsuario)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _deleteUser(user);
                                },
                              ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(height: 20),
                                _buildInfoRow('Teléfono:', user.telefono),
                                _buildInfoRow('Género:', user.genero),
                                _buildInfoRow('Fecha de Nacimiento:', 
                                    '${user.fechaNacimiento.day}/${user.fechaNacimiento.month}/${user.fechaNacimiento.year}'),
                                _buildInfoRow('Dirección:', user.direccion),
                                _buildInfoRow('Ciudad:', user.ciudadResidencia),
                                _buildInfoRow('País:', user.paisResidencia),
                                _buildInfoRow('Estado:', user.activo ? 'Activo' : 'Inactivo'),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFfdb913).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Registrado: ${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF3D1F6E),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: _currentUser?.puedeGestionarUsuarios == true
          ? FloatingActionButton(
              onPressed: () => _showUserDialog(),
              backgroundColor: const Color(0xFFfdb913),
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}