import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/audit_log.dart';
import '../services/audit_service.dart';
import '../widgets/module_scaffold.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AuditLog> _adminLogs = [];
  List<AuditLog> _asesorLogs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('🔍 Cargando logs de auditoría...');
      
      final allLogs = await AuditService.getAllLogs();
      debugPrint('✅ Total de logs obtenidos: ${allLogs.length}');
      
      final adminLogs = allLogs.where((log) => log.categoria == AuditCategory.administrador).toList();
      final asesorLogs = allLogs.where((log) => log.categoria == AuditCategory.asesor).toList();
      
      debugPrint('📊 Logs de administradores: ${adminLogs.length}');
      debugPrint('📊 Logs de asesores: ${asesorLogs.length}');
      
      if (allLogs.isNotEmpty) {
        debugPrint('📋 Primer log: ${allLogs.first.accion.displayName} - ${allLogs.first.nombreUsuario}');
      }
      
      setState(() {
        _adminLogs = adminLogs;
        _asesorLogs = asesorLogs;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error al cargar logs: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar logs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllLogs() async {
    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
            const SizedBox(width: 12),
            Text(
              '¿Eliminar todos los registros?',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta acción eliminará TODOS los registros de auditoría del sistema.',
              style: GoogleFonts.montserrat(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción NO se puede deshacer',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.montserrat(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Sí, eliminar todo',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await AuditService.deleteAllLogs();
        await _loadLogs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Todos los registros de auditoría han sido eliminados'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar registros: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _filterByDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _isLoading = true;
      });

      try {
        final logs = await AuditService.getLogsByDateRange(_startDate!, _endDate!);
        setState(() {
          _adminLogs = logs.where((log) => log.categoria == AuditCategory.administrador).toList();
          _asesorLogs = logs.where((log) => log.categoria == AuditCategory.asesor).toList();
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al filtrar logs: $e')),
          );
        }
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _searchQuery = '';
    });
    _loadLogs();
  }

  List<AuditLog> _filterLogs(List<AuditLog> logs) {
    if (_searchQuery.isEmpty) return logs;
    
    return logs.where((log) {
      final query = _searchQuery.toLowerCase();
      return log.nombreUsuario.toLowerCase().contains(query) ||
             log.accion.displayName.toLowerCase().contains(query) ||
             log.entidad.toLowerCase().contains(query) ||
             (log.nombreEntidad?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      title: 'Auditoría del Sistema',
      subtitle: 'Revisa todos los cambios realizados por el equipo',
      icon: Icons.history_rounded,
      actions: [
        IconButton(
          icon: const Icon(Icons.date_range),
          onPressed: _filterByDateRange,
          tooltip: 'Filtrar por fecha',
        ),
        if (_startDate != null || _searchQuery.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearFilters,
            tooltip: 'Limpiar filtros',
          ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadLogs,
          tooltip: 'Recargar',
        ),
        IconButton(
          icon: const Icon(Icons.delete_forever),
          onPressed: _deleteAllLogs,
          tooltip: 'Eliminar todos los registros',
          color: Colors.red[700],
        ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barra de búsqueda
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar por usuario, acción o entidad...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ),
                // Filtro de fecha activo
                if (_startDate != null && _endDate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.blue[50],
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Filtrado: ${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.blue[900],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Tabs
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF3D1F6E),
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: const Color(0xFF3D1F6E),
                    labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.admin_panel_settings),
                        text: 'Administradores (${_filterLogs(_adminLogs).length})',
                      ),
                      Tab(
                        icon: const Icon(Icons.people),
                        text: 'Asesores (${_filterLogs(_asesorLogs).length})',
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLogsList(_filterLogs(_adminLogs), AuditCategory.administrador),
                      _buildLogsList(_filterLogs(_asesorLogs), AuditCategory.asesor),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLogsList(List<AuditLog> logs, AuditCategory category) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay registros de auditoría',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los cambios aparecerán aquí cuando se realicen acciones',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) => _buildLogCard(logs[index]),
    );
  }

  Widget _buildLogCard(AuditLog log) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    // Determinar el color según la acción
    Color actionColor;
    IconData actionIcon;
    
    if (log.accion.name.contains('crear')) {
      actionColor = Colors.green;
      actionIcon = Icons.add_circle_outline;
    } else if (log.accion.name.contains('eliminar')) {
      actionColor = Colors.red;
      actionIcon = Icons.delete_outline;
    } else if (log.accion.name.contains('editar') || log.accion.name.contains('cambiar')) {
      actionColor = Colors.orange;
      actionIcon = Icons.edit_outlined;
    } else if (log.accion.name.contains('registrar')) {
      actionColor = Colors.blue;
      actionIcon = Icons.receipt_long;
    } else {
      actionColor = Colors.purple;
      actionIcon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: (log.detalles != null && log.detalles!.trim().isNotEmpty) ? () => _showDetailsDialog(log) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono de acción
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    actionIcon,
                    color: actionColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            log.accion.displayName,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F1F1F),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: actionColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            dateFormat.format(log.fechaHora),
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: actionColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          log.nombreUsuario,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3D1F6E),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            log.rolUsuario,
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.category_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          log.entidad,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        if (log.nombreEntidad != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '•',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              log.nombreEntidad!,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (log.detalles != null && log.detalles!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 12, color: Colors.blue[700]),
                            const SizedBox(width: 4),
                            Text(
                              'Ver detalles',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDetails(String jsonDetails) {
    try {
      final Map<String, dynamic> details = json.decode(jsonDetails);
      final buffer = StringBuffer();
      
      details.forEach((key, value) {
        // Formatear la clave (convertir snake_case a Title Case)
        final formattedKey = key
            .split('_')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
        
        // Formatear el valor
        String formattedValue = value.toString();
        
        // Si es una fecha ISO, formatearla
        if (key.toLowerCase().contains('fecha') && value.toString().contains('T')) {
          try {
            final date = DateTime.parse(value.toString());
            formattedValue = DateFormat('dd/MM/yyyy').format(date);
          } catch (e) {
            // Si falla, mantener el valor original
          }
        }
        
        buffer.writeln('• $formattedKey: $formattedValue');
      });
      
      return buffer.toString().trim();
    } catch (e) {
      // Si no es JSON válido, retornar el texto original
      return jsonDetails;
    }
  }

  void _showDetailsDialog(AuditLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Detalles del cambio',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Acción', log.accion.displayName),
              _buildDetailRow('Usuario', log.nombreUsuario),
              _buildDetailRow('Rol', log.rolUsuario),
              _buildDetailRow('Entidad', log.entidad),
              if (log.nombreEntidad != null)
                _buildDetailRow('Nombre', log.nombreEntidad!),
              _buildDetailRow(
                'Fecha y hora',
                DateFormat('dd/MM/yyyy HH:mm:ss').format(log.fechaHora),
              ),
              if (log.detalles != null) ...[
                const Divider(height: 24),
                Text(
                  'Detalles adicionales:',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDetails(log.detalles!),
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: Colors.grey[800],
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
