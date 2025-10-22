import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:aquatour/widgets/module_scaffold.dart';
import 'package:aquatour/models/reservation.dart';
import 'package:aquatour/models/user.dart';
import 'package:aquatour/services/storage_service.dart';
import 'package:aquatour/screens/reservation_edit_screen.dart';
import 'package:aquatour/utils/permissions_helper.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> with WidgetsBindingObserver {
  final StorageService _storageService = StorageService();
  List<Reservation> _reservations = [];
  Map<int, List<Reservation>> _reservationsByEmployee = {};
  Map<int, User> _employeesMap = {};
  User? _currentUser;
  bool _isLoading = true;
  bool _canModify = false;
  Set<int> _expandedEmployees = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadReservations();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recargar cuando la app vuelve a estar activa
      _loadReservations();
    }
  }

  Future<void> _loadReservations() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = await _storageService.getCurrentUser();
      if (currentUser != null) {
        _currentUser = currentUser;
        _canModify = PermissionsHelper.canModify(currentUser.rol);
        
        debugPrint('🔍 Usuario actual: id=${currentUser.idUsuario}, rol=${currentUser.rol.name}');
        
        final reservations = currentUser.rol == UserRole.empleado
            ? await _storageService.getReservationsByEmployee(currentUser.idUsuario!)
            : await _storageService.getAllReservations();
        
        debugPrint('📋 Reservas cargadas: ${reservations.length}');
        
        // Si es admin, agrupar por empleado
        if (currentUser.rol != UserRole.empleado && reservations.isNotEmpty) {
          final allUsers = await _storageService.getAllUsers();
          _employeesMap = {};
          for (var user in allUsers) {
            if (user.idUsuario != null) {
              _employeesMap[user.idUsuario!] = user;
            }
          }
          
          debugPrint('📊 Empleados cargados: ${_employeesMap.length}');
          _employeesMap.forEach((id, user) {
            debugPrint('  - ID: $id, Nombre: ${user.nombreCompleto}');
          });
          
          _reservationsByEmployee = {};
          for (var reservation in reservations) {
            final employeeId = reservation.idEmpleado;
            debugPrint('📋 Reserva ID: ${reservation.id}, idEmpleado: $employeeId, Nombre: ${reservation.empleadoNombreCompleto}');
            
            if (!_reservationsByEmployee.containsKey(employeeId)) {
              _reservationsByEmployee[employeeId] = [];
            }
            _reservationsByEmployee[employeeId]!.add(reservation);
          }
          
          // No expandir ninguno por defecto
        }
        
        if (mounted) {
          setState(() {
            _reservations = reservations;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando reservas: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openReservationForm({Reservation? reservation}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReservationEditScreen(reservation: reservation),
      ),
    );
    if (result == true) {
      _loadReservations();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Solo empleados pueden crear reservas directamente
    final canCreateReservation = _currentUser?.rol == UserRole.empleado;
    
    return ModuleScaffold(
      title: _currentUser?.rol == UserRole.empleado ? 'Mis Reservas' : 'Reservas del Equipo',
      subtitle: _currentUser?.rol == UserRole.empleado 
          ? 'Gestiona tus reservas y tareas pendientes'
          : 'Supervisa todas las reservas del equipo',
      icon: Icons.event_available_rounded,
      actions: [
        IconButton(
          tooltip: 'Actualizar lista',
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF3D1F6E)),
          onPressed: _loadReservations,
        ),
      ],
      floatingActionButton: canCreateReservation
          ? FloatingActionButton.extended(
              onPressed: () => _openReservationForm(),
              backgroundColor: const Color(0xFFf7941e),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Nueva reserva', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reservations.isEmpty
              ? _buildEmptyState()
              : _currentUser?.rol == UserRole.empleado
                  ? _buildReservationsList()
                  : _buildGroupedReservationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay reservas registradas',
            style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera reserva usando el botón naranja',
            style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReservation(int id, int idEmpleado) async {
    // Los empleados pueden eliminar las reservas que se les muestran
    // (ya que el backend filtra por empleado)
    final canDelete = _canModify || _currentUser?.rol == UserRole.empleado;
    
    if (!canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para eliminar esta reserva'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación', style: GoogleFonts.montserrat()),
        content: Text('¿Estás seguro de eliminar esta reserva?', style: GoogleFonts.montserrat()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.montserrat()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Eliminar', style: GoogleFonts.montserrat()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _storageService.deleteReservation(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reserva eliminada exitosamente', style: GoogleFonts.montserrat()),
              backgroundColor: Colors.green,
            ),
          );
          _loadReservations();
        }
      } catch (e) {
        if (mounted) {
          // Extraer el mensaje de error del servidor
          String errorMessage = 'Error eliminando reserva';
          if (e.toString().contains('Exception:')) {
            errorMessage = e.toString().replaceAll('Exception:', '').trim();
          } else if (e.toString().contains(':')) {
            errorMessage = e.toString().split(':').last.trim();
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage, style: GoogleFonts.montserrat()),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Widget _buildReservationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reservations.length,
      itemBuilder: (context, index) {
        final reservation = _reservations[index];
        final canModifyThisReservation = _canModify || _currentUser?.rol == UserRole.empleado;
        
        return _ReservationCard(
          reservation: reservation,
          canModify: canModifyThisReservation,
          onTap: () => _openReservationForm(reservation: reservation),
          onDelete: () => _deleteReservation(reservation.id!, reservation.idEmpleado),
        );
      },
    );
  }

  Widget _buildGroupedReservationsList() {
    final sortedEmployeeIds = _reservationsByEmployee.keys.toList()
      ..sort((a, b) {
        // Obtener el nombre del primer reservation de cada empleado
        final nameA = _reservationsByEmployee[a]?.first.empleadoNombreCompleto ?? '';
        final nameB = _reservationsByEmployee[b]?.first.empleadoNombreCompleto ?? '';
        return nameA.compareTo(nameB);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedEmployeeIds.length,
      itemBuilder: (context, index) {
        final employeeId = sortedEmployeeIds[index];
        final reservations = _reservationsByEmployee[employeeId] ?? [];
        final isExpanded = _expandedEmployees.contains(employeeId);
        // Obtener el nombre del empleado del primer reservation
        final employeeName = reservations.isNotEmpty ? reservations.first.empleadoNombreCompleto : 'Empleado #$employeeId';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedEmployees.remove(employeeId);
                    } else {
                      _expandedEmployees.add(employeeId);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4C39A6).withValues(alpha: 0.1),
                        const Color(0xFF3D1F6E).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D1F6E).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF3D1F6E),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employeeName,
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F1F1F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${reservations.length} ${reservations.length == 1 ? 'reserva' : 'reservas'}',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: const Color(0xFF3D1F6E),
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                ...reservations.map((reservation) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: _ReservationCard(
                    reservation: reservation,
                    canModify: _canModify,
                    onTap: () => _openReservationForm(reservation: reservation),
                    onDelete: () => _deleteReservation(reservation.id!, reservation.idEmpleado),
                  ),
                )),
            ],
          ),
        );
      },
    );
  }
}

class _ReservationCard extends StatefulWidget {
  const _ReservationCard({
    required this.reservation,
    required this.canModify,
    required this.onTap,
    required this.onDelete,
  });

  final Reservation reservation;
  final bool canModify;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<_ReservationCard> createState() => _ReservationCardState();
}

class _ReservationCardState extends State<_ReservationCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap, // Permitir clic siempre para debugging
            borderRadius: BorderRadius.circular(12),
            child: DecoratedBox(
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D1F6E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.flight_takeoff_rounded, color: Color(0xFF3D1F6E), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Reserva #${widget.reservation.id}',
                                style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Color(widget.reservation.paymentStatus.colorValue).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.reservation.paymentStatus.displayName,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(widget.reservation.paymentStatus.colorValue),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dateFormat.format(widget.reservation.fechaInicioViaje)} - ${dateFormat.format(widget.reservation.fechaFinViaje)}',
                            style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.people_outline, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.reservation.cantidadPersonas} personas',
                                style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.attach_money, size: 14, color: Colors.grey[600]),
                              Text(
                                '\$${widget.reservation.totalPago.toStringAsFixed(2)}',
                                style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (widget.canModify) ...[
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Color(0xFF3D1F6E)),
                        onPressed: widget.onTap,
                        tooltip: 'Editar',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: widget.onDelete,
                        tooltip: 'Eliminar',
                      ),
                    ] else
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
