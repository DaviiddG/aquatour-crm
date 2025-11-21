import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/storage_service.dart';
import '../utils/number_formatter.dart';
import '../models/user.dart';
import '../widgets/module_scaffold.dart';

class PerformanceIndicatorsScreen extends StatefulWidget {
  const PerformanceIndicatorsScreen({super.key});

  @override
  State<PerformanceIndicatorsScreen> createState() => _PerformanceIndicatorsScreenState();
}

class _PerformanceIndicatorsScreenState extends State<PerformanceIndicatorsScreen> {
  final StorageService _storageService = StorageService();
  Map<String, dynamic> _metrics = {};
  bool _isLoading = true;
  bool _clientsLoading = false;
  User? _currentUser;
  List<User> _teamMembers = [];
  int? _selectedUserId;
  List<Map<String, dynamic>> _clients = [];

  @override
  void initState() {
    super.initState();
    _initializeView();
  }

  Widget _buildChartsGrid(bool isWide) {
    final chartCards = [
      _buildSalesChart(),
      _buildReservationsChart(),
      _buildQuotesChart(),
    ];

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: chartCards[0]),
          const SizedBox(width: 18),
          Expanded(child: chartCards[1]),
          const SizedBox(width: 18),
          Expanded(child: chartCards[2]),
        ],
      );
    }

    return Column(
      children: [
        chartCards[0],
        const SizedBox(height: 18),
        chartCards[1],
        const SizedBox(height: 18),
        chartCards[2],
      ],
    );
  }

  bool get _isManagerView => _currentUser?.esAdministrador ?? false;

  Future<void> _initializeView() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = await _storageService.getCurrentUser();
      _currentUser = currentUser;

      if (currentUser == null) {
        _metrics = {};
        _clients = [];
        setState(() => _isLoading = false);
        return;
      }

      if (_isManagerView) {
        final users = await _storageService.getAllUsers();
        _teamMembers = users.where((user) => user.rol == UserRole.empleado).toList()
          ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
        // Iniciar con vista general por defecto
        _selectedUserId = -1;
      } else {
        _selectedUserId = currentUser.idUsuario;
      }

      if (_selectedUserId != null) {
        await Future.wait([
          _loadPerformanceData(_selectedUserId!),
          _loadClients(_selectedUserId!),
        ]);
      } else {
        _metrics = {};
        _clients = [];
      }
    } catch (e) {
      print('❌ Error inicializando indicadores: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadPerformanceData(int userId) async {
    try {
      final metrics = userId == -1
          ? await _storageService.getGlobalPerformanceMetrics()
          : await _storageService.getPerformanceMetrics(userId);
      if (mounted) {
        setState(() {
          _metrics = metrics;
        });
      }
    } catch (e) {
      print('Error cargando métricas: $e');
    }
  }

  Future<void> _loadClients(int userId) async {
    setState(() => _clientsLoading = true);
    try {
      // Si es vista general, obtener todos los clientes
      final clients = userId == -1
          ? await _storageService.getClients()
          : await _storageService.getClients(forEmployeeId: userId);
      
      // Obtener información de los asesores si es vista general
      Map<int, String> employeeNames = {};
      if (userId == -1) {
        for (var employee in _teamMembers) {
          if (employee.idUsuario != null) {
            employeeNames[employee.idUsuario!] = employee.nombreCompleto;
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _clients = clients.map((c) {
            String? employeeName;
            if (userId == -1 && c.idEmpleado != null) {
              employeeName = employeeNames[c.idEmpleado];
            }
            
            return {
              'id': c.id,
              'nombre': c.nombreCompleto,
              'email': c.email,
              'telefono': c.telefono,
              'nacionalidad': c.pais,
              'estado_civil': c.estadoCivil,
              'preferencias_viaje': c.interes,
              'fecha_registro': c.fechaRegistro.toString(),
              'satisfaccion': c.satisfaccion,
              'asesor': employeeName,
              'id_empleado': c.idEmpleado,
            };
          }).toList();
          _clientsLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando clientes: $e');
      if (mounted) setState(() => _clientsLoading = false);
    }
  }

  Future<void> _onEmployeeChanged(int userId) async {
    setState(() {
      _selectedUserId = userId;
      _isLoading = true;
    });

    await Future.wait([
      _loadPerformanceData(userId),
      _loadClients(userId),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      title: 'Indicadores de desempeño',
      subtitle: 'Visualiza métricas clave y compara el rendimiento del equipo',
      icon: Icons.analytics_rounded,
      actions: [
        IconButton(
          tooltip: 'Actualizar métricas',
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF3D1F6E)),
          onPressed: _selectedUserId == null ? null : () => _onEmployeeChanged(_selectedUserId!),
        ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_metrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No hay datos disponibles',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1180;
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isManagerView) ...[
                  _buildEmployeeSelector(),
                  const SizedBox(height: 18),
                ],
                _buildSummaryBanner(_selectedEmployeeName),
                const SizedBox(height: 24),
                Text(
                  'Análisis de rendimiento',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(height: 14),
                _buildChartsGrid(isWide),
                const SizedBox(height: 24),
                _buildDetailedMetrics(),
                const SizedBox(height: 24),
                _buildClientsSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  String? get _selectedEmployeeName {
    if (_selectedUserId == null) return null;
    if (_selectedUserId == -1) return 'Vista General del Equipo';
    if (_isManagerView) {
      try {
        return _teamMembers
            .firstWhere((user) => user.idUsuario == _selectedUserId)
            .nombreCompleto;
      } catch (_) {
        return null;
      }
    }
    return _currentUser?.nombreCompleto;
  }

  Widget _buildSummaryBanner(String? employeeName) {
    final sales = _metrics['sales'] ?? {};
    final reservations = _metrics['reservations'] ?? {};
    final quotes = _metrics['quotes'] ?? {};
    final clients = _metrics['clients'] ?? {};

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C39A6), Color(0xFF2C53A4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C53A4).withOpacity(0.22),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employeeName ?? 'Rendimiento general',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Resumen mensual de ventas, reservas, cotizaciones y clientes',
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
            const SizedBox(height: 18),
            Row(
              children: [
                _buildSummaryItem(
                  'Ventas',
                  '${sales['completed'] ?? 0} de ${sales['total'] ?? 0}',
                  Icons.attach_money,
                  subtitle: 'completadas',
                ),
                _buildSummaryItem(
                  'Reservas',
                  '${reservations['paid'] ?? 0} de ${reservations['total'] ?? 0}',
                  Icons.event_available_rounded,
                  subtitle: 'pagadas',
                ),
                _buildSummaryItem(
                  'Cotizaciones',
                  '${quotes['paid'] ?? 0} de ${quotes['total'] ?? 0}',
                  Icons.request_quote_rounded,
                  subtitle: 'pagadas',
                ),
                _buildSummaryItem(
                  'Clientes',
                  '${clients['total'] ?? _clients.length}',
                  Icons.people_rounded,
                  subtitle: 'registrados',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeSelector() {
    return DropdownButtonFormField<int>(
      value: _selectedUserId,
      decoration: InputDecoration(
        labelText: 'Selecciona un asesor',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        // Opción de Vista General
        DropdownMenuItem<int>(
          value: -1,
          child: Row(
            children: [
              const Icon(Icons.dashboard, size: 18, color: Color(0xFF3D1F6E)),
              const SizedBox(width: 8),
              Text(
                'Vista General (Todos los asesores)',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        // Separador
        const DropdownMenuItem<int>(
          value: null,
          enabled: false,
          child: Divider(),
        ),
        // Lista de asesores individuales
        ..._teamMembers.map(
          (user) => DropdownMenuItem<int>(
            value: user.idUsuario,
            child: Text(user.nombreCompleto),
          ),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          _onEmployeeChanged(value);
        }
      },
    );
  }

  Widget _buildClientsSection() {
    // Determinar el título según el contexto
    String title;
    if (_selectedUserId == -1) {
      title = 'Todos los Clientes Registrados';
    } else if (_isManagerView) {
      title = 'Clientes del Asesor';
    } else {
      title = 'Tus Clientes Asignados';
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_outline, color: Color(0xFF3D1F6E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3D1F6E),
                    ),
                  ),
                ),
                if (_clients.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D1F6E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_clients.length} cliente${_clients.length != 1 ? 's' : ''}',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D1F6E),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_clientsLoading)
              const Center(child: CircularProgressIndicator())
            else if (_clients.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3D1F6E).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isManagerView
                      ? 'El asesor seleccionado aún no registra clientes.'
                      : 'Aún no has registrado clientes. Usa el módulo Clientes para comenzar.',
                  style: GoogleFonts.montserrat(fontSize: 13, color: Colors.black87),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _clients.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final client = _clients[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF4C39A6).withOpacity(0.15),
                      child: Text(
                        client['nombre']?.toString().substring(0, 1) ?? '?',
                        style: const TextStyle(color: Color(0xFF3D1F6E)),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            client['nombre']?.toString() ?? 'Sin nombre',
                            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                        if (client['asesor'] != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3D1F6E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person, size: 12, color: Color(0xFF3D1F6E)),
                                const SizedBox(width: 4),
                                Text(
                                  client['asesor'].toString(),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3D1F6E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.public, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              client['nacionalidad'] ?? 'N/A',
                              style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[700]),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.favorite_border, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              client['estado_civil'] ?? 'N/A',
                              style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.interests, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                client['preferencias_viaje']?.toString() ?? 'Sin preferencias',
                                style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[700]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              client['fecha_registro']?.toString().substring(0, 10) ?? 'N/D',
                              style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.star, size: 12, color: Colors.amber[700]),
                            const SizedBox(width: 4),
                            Text(
                              '${client['satisfaccion'] ?? 'N/D'}/5',
                              style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${client['id'] ?? ''}',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, {String? subtitle}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            Text(
              subtitle,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
    final sales = _metrics['sales'] ?? {};
    final completed = (sales['completed'] ?? 0).toDouble();
    final inProcess = (sales['inProcess'] ?? 0).toDouble();
    final total = completed + inProcess;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rendimiento de Ventas',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D1F6E),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: total == 0
                  ? Center(
                      child: Text(
                        'Sin ventas',
                        style: GoogleFonts.montserrat(color: Colors.grey),
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (total * 1.2).ceilToDouble(),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.toInt()}',
                                GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return Text('Completadas', style: GoogleFonts.montserrat(fontSize: 11));
                                  case 1:
                                    return Text('En Proceso', style: GoogleFonts.montserrat(fontSize: 11));
                                  default:
                                    return const Text('');
                                }
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: GoogleFonts.montserrat(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: completed,
                                color: const Color(0xFFfdb913),
                                width: 40,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: inProcess,
                                color: const Color(0xFF4C39A6),
                                width: 40,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Completadas', const Color(0xFFfdb913)),
                _buildLegendItem('En Proceso', const Color(0xFF4C39A6)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationsChart() {
    final reservations = _metrics['reservations'] ?? {};
    final pending = (reservations['pending'] ?? 0).toDouble();
    final inProcess = (reservations['inProcess'] ?? 0).toDouble();
    final paid = (reservations['paid'] ?? 0).toDouble();
    final cancelled = (reservations['cancelled'] ?? 0).toDouble();

    final sections = <PieChartSectionData>[];
    
    if (paid > 0) {
      sections.add(PieChartSectionData(
        value: paid,
        title: '${paid.toInt()}',
        color: const Color(0xFF4CAF50),
        radius: 65,
        titleStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }
    
    if (inProcess > 0) {
      sections.add(PieChartSectionData(
        value: inProcess,
        title: '${inProcess.toInt()}',
        color: const Color(0xFF2196F3),
        radius: 65,
        titleStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }
    
    if (pending > 0) {
      sections.add(PieChartSectionData(
        value: pending,
        title: '${pending.toInt()}',
        color: const Color(0xFFFF9800),
        radius: 65,
        titleStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }
    
    if (cancelled > 0) {
      sections.add(PieChartSectionData(
        value: cancelled,
        title: '${cancelled.toInt()}',
        color: const Color(0xFFF44336),
        radius: 65,
        titleStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado de Reservas',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D1F6E),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: sections.isEmpty
                  ? Center(
                      child: Text(
                        'Sin reservas',
                        style: GoogleFonts.montserrat(color: Colors.grey),
                      ),
                    )
                  : PieChart(
                      PieChartData(
                        sections: sections,
                        sectionsSpace: 3,
                        centerSpaceRadius: 45,
                        borderData: FlBorderData(show: false),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildLegendItem('Pagadas', const Color(0xFF4CAF50)),
                _buildLegendItem('En Proceso', const Color(0xFF2196F3)),
                _buildLegendItem('Pendientes', const Color(0xFFFF9800)),
                _buildLegendItem('Canceladas', const Color(0xFFF44336)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotesChart() {
    final quotes = _metrics['quotes'] ?? {};
    final paid = (quotes['paid'] ?? 0).toDouble();
    final partialPaid = (quotes['partialPaid'] ?? 0).toDouble();
    final pending = (quotes['pending'] ?? 0).toDouble();
    final total = paid + partialPaid + pending;
    final maxValue = [paid, partialPaid, pending].reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado de Cotizaciones',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D1F6E),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: total == 0
                  ? Center(
                      child: Text(
                        'Sin cotizaciones',
                        style: GoogleFonts.montserrat(color: Colors.grey),
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (maxValue * 1.2).ceilToDouble(),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              String label = '';
                              switch (group.x) {
                                case 0:
                                  label = 'Pagadas';
                                  break;
                                case 1:
                                  label = 'Pago Parcial';
                                  break;
                                case 2:
                                  label = 'Pendientes';
                                  break;
                              }
                              final percentage = total > 0 ? (rod.toY / total * 100).toStringAsFixed(1) : '0';
                              return BarTooltipItem(
                                '$label\n${rod.toY.toInt()} ($percentage%)',
                                GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text('Pagadas', style: GoogleFonts.montserrat(fontSize: 11)),
                                    );
                                  case 1:
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text('Pago Parcial', style: GoogleFonts.montserrat(fontSize: 11)),
                                    );
                                  case 2:
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text('Pendientes', style: GoogleFonts.montserrat(fontSize: 11)),
                                    );
                                  default:
                                    return const Text('');
                                }
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: GoogleFonts.montserrat(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: paid,
                                color: const Color(0xFF4CAF50),
                                width: 40,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: partialPaid,
                                color: const Color(0xFFFF9800),
                                width: 40,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 2,
                            barRods: [
                              BarChartRodData(
                                toY: pending,
                                color: Colors.grey,
                                width: 40,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 250),
                    ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildLegendItem('Pagadas', const Color(0xFF4CAF50)),
                _buildLegendItem('Pago Parcial', const Color(0xFFFF9800)),
                _buildLegendItem('Pendientes', Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  String _getCurrentPeriod() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    final monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    return '${startOfMonth.day} de ${monthNames[now.month - 1]} - ${endOfMonth.day} de ${monthNames[now.month - 1]} ${now.year}';
  }

  Widget _buildDetailedMetrics() {
    final sales = _metrics['sales'] ?? {};
    final reservations = _metrics['reservations'] ?? {};
    final quotes = _metrics['quotes'] ?? {};

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métricas Detalladas',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D1F6E),
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Ventas Totales',
              NumberFormatter.formatCurrency(sales['completedSalesAmount'] ?? 0),
              Icons.shopping_cart,
              subtitle: 'Completamente pagadas',
            ),
            _buildMetricRow(
              'Dinero Total Movido',
              NumberFormatter.formatCurrency(sales['totalRevenue'] ?? 0),
              Icons.attach_money,
              subtitle: 'Incluye pagos parciales',
            ),
            _buildMetricRow(
              'Reservas Totales',
              '${reservations['total'] ?? 0}',
              Icons.event_available_rounded,
            ),
            _buildMetricRow(
              'Cotizaciones Totales',
              '${quotes['total'] ?? 0}',
              Icons.request_quote_rounded,
            ),
            const Divider(),
            Text(
              'Período: ${_getCurrentPeriod()}',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF3D1F6E)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3D1F6E),
            ),
          ),
        ],
      ),
    );
  }
}
