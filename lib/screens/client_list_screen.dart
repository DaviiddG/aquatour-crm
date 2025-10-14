import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquatour/widgets/module_scaffold.dart';
import 'package:aquatour/screens/client_edit_screen.dart';
import 'package:aquatour/services/api_service.dart';
import 'package:aquatour/services/storage_service.dart';
import 'package:aquatour/models/user.dart';
import 'package:aquatour/utils/permissions_helper.dart';
import 'package:fl_chart/fl_chart.dart';

enum _ClientFormResult { created, updated, none }

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key, this.showAll = false});

  final bool showAll;

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final List<Map<String, dynamic>> _clients = [];
  bool _isLoading = true;
  String? _token;
  User? _currentUser;
  bool _canModify = false;

  double? _calculateAverageSatisfaction() {
    if (_clients.isEmpty) return null;

    double total = 0;
    int count = 0;

    for (final client in _clients) {
      final value = client['satisfaccion'];
      final num? parsed = value is num
          ? value
          : value != null
              ? num.tryParse(value.toString())
              : null;

      final double normalized = (parsed ?? 3).toDouble().clamp(1, 5);
      total += normalized;
      count++;
    }

    if (count == 0) return null;
    return total / count;
  }
  
  Map<String, int> _calculateClientDistribution() {
    final distribution = <String, int>{};
    
    for (final client in _clients) {
      String fuente = 'Sin Especificar';
      
      // Verificar si viene de un contacto
      final idContacto = client['id_contacto_origen'] ?? client['idContactoOrigen'];
      if (idContacto != null) {
        fuente = 'Contacto';
      } else {
        // Verificar fuente directa
        final tipoFuente = client['tipo_fuente_directa'] ?? client['tipoFuenteDirecta'];
        if (tipoFuente != null && tipoFuente.toString().isNotEmpty) {
          fuente = tipoFuente.toString();
        }
      }
      
      distribution[fuente] = (distribution[fuente] ?? 0) + 1;
    }
    
    return distribution;
  }

  String _buildStarString(double average) {
    final clamped = average.clamp(0, 5);
    final filled = clamped.round().clamp(0, 5).toInt();
    final buffer = StringBuffer();
    for (var i = 0; i < filled; i++) {
      buffer.write('★');
    }
    for (var i = filled; i < 5; i++) {
      buffer.write('☆');
    }
    return buffer.toString();
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    try {
      final storage = StorageService();
      // Obtener token y usuario almacenados
      _token = await StorageService.getToken();
      final currentUser = await storage.getCurrentUser();

      _currentUser = currentUser;
      
      // Verificar permisos
      if (currentUser != null) {
        _canModify = PermissionsHelper.canModify(currentUser.rol);
      }

      if (_token == null && currentUser == null) {
        // No existe sesión activa, redirigir al login
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      // Cargar clientes desde la API incluso si el token es nulo (backend no exige aún auth)
      await _loadClients();
    } catch (e) {
      print('Error inicializando datos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar los datos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadClients() async {
    try {
      final clients = await ApiService().getClients(_token);
      final filteredClients = widget.showAll
          ? clients
          : clients.where((client) {
              if (_currentUser == null) return false;
              final rawId = client['id_usuario'] ?? client['idUsuario'] ?? client['usuario_id'];
              if (rawId == null) return false;
              final int? assignedId = rawId is num ? rawId.toInt() : int.tryParse(rawId.toString());
              return assignedId == _currentUser!.idUsuario;
            }).toList();
      if (mounted) {
        setState(() {
          _clients.clear();
          _clients.addAll(filteredClients.whereType<Map<String, dynamic>>());
        });
      }
    } catch (e) {
      print('Error cargando clientes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar clientes: $e')),
        );
      }
      // Si falla la API, usar datos de ejemplo como fallback
      _clients.addAll([
        {
          'id': 1,
          'nombres': 'Juan',
          'apellidos': 'Pérez',
          'email': 'juan@example.com',
          'telefono': '987654321',
          'fechaRegistro': DateTime.now().toIso8601String(),
          'nombreAgente': 'Agente 1',
        },
      ]);
    }
  }

  Future<void> _openClientForm({Map<String, dynamic>? clientData}) async {
    final result = await Navigator.of(context).push<_ClientFormResult?>(
      MaterialPageRoute(
        builder: (context) => ClientEditScreen(
          clientData: clientData != null ? ClientModel.fromJson(clientData) : null,
          onSave: (ClientModel client) async {
            try {
              // Obtener el usuario autenticado para obtener su ID
              final currentUser = await StorageService().getCurrentUser();
              _token = await StorageService.getToken();
              
              if (currentUser == null) {
                throw Exception('Usuario no autenticado');
              }

              // Verificar permisos: Los empleados pueden editar sus propios clientes
              final isAdmin = PermissionsHelper.canModify(currentUser.rol);
              final isOwnClient = clientData != null && 
                                  (clientData['id_usuario'] == currentUser.idUsuario || 
                                   clientData['idUsuario'] == currentUser.idUsuario);
              
              if (!isAdmin && clientData != null && !isOwnClient) {
                throw Exception('No tienes permiso para modificar clientes de otros usuarios');
              }

              final clientMap = client.toJson();
              clientMap['id_usuario'] = currentUser.idUsuario;

              if (clientData == null) {
                // Crear nuevo cliente
                await ApiService().createClient(clientMap, _token);
              } else {
                // Actualizar cliente existente
                final clientId = clientData['id'] ?? 0;
                if (clientId == 0) {
                  throw Exception('ID de cliente inválido');
                }
                await ApiService().updateClient(clientId, clientMap, _token);
              }

              // Recargar lista de clientes
              await _loadClients();

              if (context.mounted) {
                Navigator.of(context).pop(
                  clientData == null ? _ClientFormResult.created : _ClientFormResult.updated,
                );
              }
            } catch (e) {
              print('Error guardando cliente: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.of(context).pop(_ClientFormResult.none);
              }
            }
          },
        ),
      ),
    );

    if (!mounted) return;

    if (result == _ClientFormResult.created || result == _ClientFormResult.updated) {
      final message = result == _ClientFormResult.created
          ? 'Cliente creado exitosamente'
          : 'Cliente actualizado exitosamente';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF3D1F6E),
        ),
      );
    }
  }

  void _deleteClient(int id) {
    if (id == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: ID de cliente inválido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: const Text('¿Estás seguro de que deseas eliminar este cliente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ApiService().deleteClient(id, _token);

                // Recargar lista de clientes
                await _loadClients();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cliente eliminado exitosamente'),
                      backgroundColor: Color(0xFF3D1F6E),
                    ),
                  );
                }
              } catch (e) {
                print('Error eliminando cliente: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeClients = _clients.length;
    final averageSatisfaction = _calculateAverageSatisfaction();
    final satisfactionValue = averageSatisfaction != null
        ? _buildStarString(averageSatisfaction)
        : 'N/D';
    final satisfactionDescription = averageSatisfaction != null
        ? 'Promedio ${averageSatisfaction.toStringAsFixed(1)} / 5'
        : 'Resultados de encuestas recientes.';

    final summaryCards = widget.showAll
        ? [
            _SummaryCard(
              icon: Icons.people_alt_rounded,
              label: 'Clientes totales',
              value: activeClients.toString(),
              description: 'Consulta métricas por asesor y ciclo de vida.',
            ),
            _SummaryCard(
              icon: Icons.location_on_rounded,
              label: 'Países de origen',
              value: _clients.map((c) => c['pais'] ?? 'N/A').toSet().length.toString(),
              description: 'Diversidad geográfica de tu cartera.',
            ),
            _SummaryCard(
              icon: Icons.sentiment_satisfied_alt_rounded,
              label: 'Satisfacción promedio',
              value: satisfactionValue,
              description: satisfactionDescription,
            ),
          ]
        : [
            _SummaryCard(
              icon: Icons.person_pin_circle_rounded,
              label: 'Clientes activos',
              value: activeClients.toString(),
              description: activeClients == 0
                  ? 'Añade nuevos prospectos para iniciar tu cartera.'
                  : '¡Excelente! Lleva ${activeClients == 1 ? '1 cliente' : '$activeClients clientes'} activos en tu cartera.',
            ),
          ];

    return ModuleScaffold(
      title: widget.showAll ? 'Clientes del equipo' : 'Clientes asignados',
      subtitle: widget.showAll
          ? 'Supervisa la cartera completa y ayuda a priorizar oportunidades.'
          : 'Gestiona tu cartera personal y registra actividades clave.',
      icon: Icons.people_outline_rounded,
      floatingActionButton: widget.showAll
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openClientForm(),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Nuevo cliente'),
              backgroundColor: const Color(0xFFf7941e),
            ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 1180;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: summaryCards
                      .map((card) => SizedBox(
                            width: isWide ? (constraints.maxWidth - 32) / 3 : double.infinity,
                            child: card,
                          ))
                      .toList(),
                ),
                if (_clients.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildDistributionChart(),
                ],
                if (_clients.isEmpty) ...[
                  const SizedBox(height: 24),
                  _buildInfoSection(),
                ] else ...[
                  const SizedBox(height: 24),
                  _buildClientList(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildClientList() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Mis Clientes',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3D1F6E),
              ),
            ),
          ),
          const Divider(height: 1),
          ..._clients.map((client) => _buildClientItem(client)),
        ],
      ),
    );
  }

  Widget _buildClientItem(Map<String, dynamic> client) {
    // Los empleados pueden editar sus propios clientes
    // El cliente tiene id_usuario que corresponde al empleado que lo creó
    final clientIdUsuario = client['idUsuario'] ?? client['id_usuario'];
    final canModifyThisClient = _canModify || 
        (_currentUser?.rol == UserRole.empleado && clientIdUsuario == _currentUser?.idUsuario);
    
    return _ClientCard(
      client: client,
      canModify: canModifyThisClient,
      onEdit: () => _openClientForm(clientData: client),
      onDelete: () => _deleteClient(client['id'] ?? 0),
    );
  }

  Widget _buildInfoSection() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.showAll ? 'Próximas funcionalidades' : 'Registra y segmenta a tus clientes',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3D1F6E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.showAll
                  ? 'Muy pronto se habilitarán filtros, dashboards comparativos y exportación de la cartera para coordinadores.'
                  : 'Cada registro quedará vinculado a tu usuario y podrás agregar notas, preferencias y nivel de interés.',
              style: GoogleFonts.montserrat(fontSize: 14, height: 1.55, color: Colors.black87),
            ),
            const SizedBox(height: 22),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D1F6E).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people_outline_rounded, color: Color(0xFF3D1F6E), size: 38),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.showAll ? 'Empieza asignando clientes a cada asesor.' : 'Aún no tienes clientes registrados.',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F1F1F),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.showAll
                        ? 'Sincroniza la base de prospectos para visualizar métricas consolidadas del equipo.'
                        : 'Registra tus primeros clientes desde el botón "Nuevo cliente" para comenzar tu cartera.',
                    style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[700], height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDistributionChart() {
    final distribution = _calculateClientDistribution();
    
    if (distribution.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Colores para cada fuente
    final colors = {
      'Contacto': const Color(0xFF3D1F6E),
      'Página Web': const Color(0xFFfdb913),
      'Redes Sociales': const Color(0xFF4CAF50),
      'Email': const Color(0xFF2196F3),
      'WhatsApp': const Color(0xFF25D366),
      'Llamada Telefónica': const Color(0xFFFF9800),
      'Referido': const Color(0xFF9C27B0),
      'Otro': const Color(0xFF607D8B),
      'Sin Especificar': Colors.grey,
    };
    
    // Iconos para cada fuente
    final icons = {
      'Contacto': Icons.person,
      'Página Web': Icons.language,
      'Redes Sociales': Icons.share,
      'Email': Icons.email,
      'WhatsApp': Icons.chat,
      'Llamada Telefónica': Icons.phone,
      'Referido': Icons.people,
      'Otro': Icons.contact_page,
      'Sin Especificar': Icons.help_outline,
    };
    
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D1F6E).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.pie_chart, color: Color(0xFF3D1F6E)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distribución de Clientes por Fuente',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3D1F6E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Análisis de origen de tus clientes',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: Row(
                children: [
                  // Gráfica de pastel
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
                        sections: distribution.entries.map((entry) {
                          final total = distribution.values.reduce((a, b) => a + b);
                          final percentage = (entry.value / total * 100).toStringAsFixed(1);
                          return PieChartSectionData(
                            color: colors[entry.key] ?? Colors.grey,
                            value: entry.value.toDouble(),
                            title: '$percentage%',
                            radius: 80,
                            titleStyle: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Leyenda
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: distribution.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: colors[entry.key] ?? Colors.grey,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  icons[entry.key] ?? Icons.help_outline,
                                  size: 18,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1F1F1F),
                                    ),
                                  ),
                                ),
                                Text(
                                  '${entry.value}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF3D1F6E),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.description,
  });

  final IconData icon;
  final String label;
  final String value;
  final String description;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3D1F6E).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xFF3D1F6E)),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6F6F6F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: GoogleFonts.montserrat(
                fontSize: 12.5,
                height: 1.5,
                color: const Color(0xFF4B4B4B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientFormSheet extends StatefulWidget {
  const _ClientFormSheet({required this.onSubmit});

  final void Function(Map<String, dynamic> data) onSubmit;

  @override
  State<_ClientFormSheet> createState() => _ClientFormSheetState();
}

class _ClientFormSheetState extends State<_ClientFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _paisController = TextEditingController();
  final _nacionalidadController = TextEditingController();
  final _observacionesController = TextEditingController();

  DateTime? _fechaNacimiento;
  String _fuente = 'Referencia';
  String _interes = 'Cotización';

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _ciudadController.dispose();
    _paisController.dispose();
    _nacionalidadController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _fechaNacimiento = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Dividir nombre completo en nombres y apellidos
    final nombreCompleto = _nombreController.text.trim();
    final partesNombre = nombreCompleto.split(' ');
    final nombres = partesNombre.first;
    final apellidos = partesNombre.length > 1 ? partesNombre.sublist(1).join(' ') : '';

    final data = <String, dynamic>{
      'nombres': nombres,
      'apellidos': apellidos,
      'email': _emailController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      'ciudad_residencia': _ciudadController.text.trim(),
      'pais_residencia': _paisController.text.trim(),
      'nacionalidad': _nacionalidadController.text.trim(),
      'fecha_nacimiento': _fechaNacimiento?.toIso8601String(),
      'estado_cliente': 'Potencial',
      'fuente_cliente': _fuente,
      'comentarios': _observacionesController.text.trim(),
    };

    widget.onSubmit(data);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, viewInsets.bottom + 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D1F6E).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_alt_1, color: Color(0xFF3D1F6E)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nuevo Cliente',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F1F1F),
                            ),
                          ),
                          Text(
                            'Completa la información del prospecto para asignarlo a tu cartera.',
                            style: GoogleFonts.montserrat(
                              fontSize: 12.5,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Información básica',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D1F6E),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El correo es obligatorio';
                          }
                          final emailReg = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!emailReg.hasMatch(value.trim())) {
                            return 'Formato inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El teléfono es obligatorio';
                          }
                          final phoneReg = RegExp(r'^\+?[0-9\s]{7,}$');
                          if (!phoneReg.hasMatch(value.trim())) {
                            return 'Formato inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ciudadController,
                        decoration: const InputDecoration(
                          labelText: 'Ciudad de residencia',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _paisController,
                        decoration: const InputDecoration(
                          labelText: 'País de residencia',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nacionalidadController,
                  decoration: const InputDecoration(
                    labelText: 'Nacionalidad',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha de nacimiento',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _fechaNacimiento != null
                                ? '${_fechaNacimiento!.day.toString().padLeft(2, '0')}/'
                                    '${_fechaNacimiento!.month.toString().padLeft(2, '0')}/'
                                    '${_fechaNacimiento!.year}'
                                : 'Selecciona una fecha',
                            style: GoogleFonts.montserrat(
                              color: _fechaNacimiento != null ? const Color(0xFF1F1F1F) : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _fuente,
                        decoration: const InputDecoration(
                          labelText: 'Fuente de contacto *',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Referencia', child: Text('Referencia')),
                          DropdownMenuItem(value: 'Redes sociales', child: Text('Redes sociales')),
                          DropdownMenuItem(value: 'Página web', child: Text('Página web')),
                          DropdownMenuItem(value: 'Feria o evento', child: Text('Feria o evento')),
                          DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _fuente = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _interes,
                  decoration: const InputDecoration(
                    labelText: 'Interés principal *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Cotización', child: Text('Cotización')),
                    DropdownMenuItem(value: 'Reserva directa', child: Text('Reserva directa')),
                    DropdownMenuItem(value: 'Información general', child: Text('Información general')),
                    DropdownMenuItem(value: 'Seguimiento post-venta', child: Text('Seguimiento post-venta')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _interes = value);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _observacionesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Notas u observaciones',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Guardar cliente'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientCard extends StatefulWidget {
  const _ClientCard({
    required this.client,
    required this.canModify,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> client;
  final bool canModify;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends State<_ClientCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered ? const Color(0xFF3D1F6E) : Colors.grey[200]!,
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: const Color(0xFF3D1F6E).withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.canModify ? widget.onEdit : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF3D1F6E).withOpacity(0.1),
                    child: Text(
                      (widget.client['nombres']?.toString() ?? '?')[0].toUpperCase(),
                      style: const TextStyle(color: Color(0xFF3D1F6E), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.client['nombres'] ?? 'N/A'} ${widget.client['apellidos'] ?? ''}',
                          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.client['email'] ?? 'Sin email',
                          style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (widget.canModify) ...[
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF3D1F6E), size: 20),
                      onPressed: widget.onEdit,
                      tooltip: 'Editar cliente',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: widget.onDelete,
                      tooltip: 'Eliminar cliente',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
