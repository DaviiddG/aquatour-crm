import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:aquatour/models/reservation.dart';
import 'package:aquatour/models/client.dart';
import 'package:aquatour/models/tour_package.dart';
import 'package:aquatour/models/destination.dart';
import 'package:aquatour/services/storage_service.dart';
import 'package:aquatour/services/audit_service.dart';
import 'package:aquatour/models/audit_log.dart';
import 'package:aquatour/utils/number_formatter.dart';
import 'package:aquatour/widgets/unsaved_changes_dialog.dart';

class ReservationEditScreen extends StatefulWidget {
  final Reservation? reservation;

  const ReservationEditScreen({super.key, this.reservation});

  @override
  State<ReservationEditScreen> createState() => _ReservationEditScreenState();
}

class _ReservationEditScreenState extends State<ReservationEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();

  List<Client> _clients = [];
  List<TourPackage> _packages = [];
  List<Destination> _destinations = [];
  int? _selectedClientId;
  int? _selectedPackageId;
  int? _selectedDestinationId;
  bool _isPackage = true; // true = paquete, false = destino
  bool _isAdmin = false;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  late TextEditingController _precioDestinoController;
  
  late TextEditingController _cantidadPersonasController;
  late TextEditingController _totalPagoController;
  late TextEditingController _notasController;

  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.reservation?.idCliente;
    _selectedPackageId = widget.reservation?.idPaquete;
    _selectedDestinationId = widget.reservation?.idDestino;
    _isPackage = widget.reservation?.idPaquete != null;
    _fechaInicio = widget.reservation?.fechaInicioViaje;
    _fechaFin = widget.reservation?.fechaFinViaje;
    
    _cantidadPersonasController = TextEditingController(
      text: widget.reservation?.cantidadPersonas.toString() ?? '1',
    );
    _totalPagoController = TextEditingController(
      text: widget.reservation?.totalPago.toString() ?? '',
    );
    _precioDestinoController = TextEditingController(
      text: widget.reservation?.precioDestino?.toString() ?? '',
    );
    _notasController = TextEditingController(
      text: widget.reservation?.notas ?? '',
    );
    
    _cantidadPersonasController.addListener(_onQuantityChanged);
    _totalPagoController.addListener(_markAsChanged);
    _precioDestinoController.addListener(_onDestinationPriceChanged);
    _notasController.addListener(_markAsChanged);
    
    _loadData();
  }
  
  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      final currentUser = await _storageService.getCurrentUser();
      if (currentUser != null) {
        _isAdmin = currentUser.esAdministrador;
        
        List<Client> clients;
        
        // Si es admin editando, cargar TODOS los clientes para poder ver el cliente aunque el empleado ya no exista
        if (_isAdmin && widget.reservation != null) {
          debugPrint('🔍 Admin editando reserva - Cargando TODOS los clientes');
          clients = await _storageService.getClients(); // Sin filtro de empleado
        } else {
          // Si es empleado o admin creando nueva, cargar solo sus clientes
          debugPrint('🔍 Cargando clientes para empleado ID: ${currentUser.idUsuario}');
          clients = await _storageService.getClients(forEmployeeId: currentUser.idUsuario);
        }
        
        final packages = await _storageService.getPackages();
        final destinations = await _storageService.getAllDestinations();
        if (mounted) {
          setState(() {
            _clients = clients;
            _packages = packages;
            _destinations = destinations;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onQuantityChanged() {
    _markAsChanged();
    if (_isPackage && _selectedPackageId != null) {
      // Recalcular para paquetes
      try {
        final package = _packages.firstWhere((p) => p.id == _selectedPackageId);
        final quantity = int.parse(_cantidadPersonasController.text);
        final totalPrice = package.precioBase * quantity;
        _totalPagoController.text = totalPrice.toString();
      } catch (e) {
        debugPrint('Error calculando precio: $e');
      }
    } else if (!_isPackage && _selectedDestinationId != null && _precioDestinoController.text.isNotEmpty) {
      // Recalcular para destinos
      try {
        final precioDestino = double.parse(_precioDestinoController.text);
        final quantity = int.parse(_cantidadPersonasController.text);
        final totalPrice = precioDestino * quantity;
        _totalPagoController.text = totalPrice.toString();
      } catch (e) {
        debugPrint('Error calculando precio destino: $e');
      }
    }
  }

  void _recalculatePrice() {
    if (_selectedPackageId != null && _cantidadPersonasController.text.isNotEmpty) {
      try {
        final package = _packages.firstWhere((p) => p.id == _selectedPackageId);
        final quantity = int.parse(_cantidadPersonasController.text);
        final totalPrice = package.precioBase * quantity;
        _totalPagoController.text = totalPrice.toString();
      } catch (e) {
        debugPrint('Error calculando precio: $e');
      }
    }
  }

  void _onPackageSelected(int? packageId) {
    setState(() {
      _selectedPackageId = packageId;
      if (packageId != null) {
        final package = _packages.firstWhere((p) => p.id == packageId);
        // Auto-calcular precio y fechas sugeridas
        _recalculatePrice();
        if (_fechaInicio != null) {
          _fechaFin = _fechaInicio!.add(Duration(days: package.duracionDias));
        }
      }
    });
    _markAsChanged();
  }

  void _onDestinationPriceChanged() {
    _markAsChanged();
    if (!_isPackage && _selectedDestinationId != null && _precioDestinoController.text.isNotEmpty) {
      try {
        final precioDestino = double.parse(_precioDestinoController.text);
        final quantity = int.parse(_cantidadPersonasController.text);
        final totalPrice = precioDestino * quantity;
        _totalPagoController.text = totalPrice.toString();
      } catch (e) {
        debugPrint('Error calculando precio destino: $e');
      }
    }
  }

  @override
  void dispose() {
    _cantidadPersonasController.dispose();
    _totalPagoController.dispose();
    _precioDestinoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    // Obtener duración mínima del paquete si está seleccionado
    int? minDuration;
    if (_selectedPackageId != null) {
      final package = _packages.firstWhere((p) => p.id == _selectedPackageId);
      minDuration = package.duracionDias;
    }

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDateRange: _fechaInicio != null && _fechaFin != null
          ? DateTimeRange(start: _fechaInicio!, end: _fechaFin!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF3D1F6E)),
          ),
          child: child!,
        );
      },
      helpText: minDuration != null 
          ? 'Selecciona fechas (mínimo $minDuration días)' 
          : 'Selecciona las fechas del viaje',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      saveText: 'Guardar',
      errorFormatText: 'Formato incorrecto',
      errorInvalidText: 'Fecha inválida',
      errorInvalidRangeText: 'Rango inválido',
      fieldStartHintText: 'Fecha inicio',
      fieldEndHintText: 'Fecha fin',
      fieldStartLabelText: 'Inicio',
      fieldEndLabelText: 'Fin',
    );

    if (picked != null) {
      // Validar que no sean fechas pasadas
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (picked.start.isBefore(today)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No puedes seleccionar fechas pasadas'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Validar duración exacta si hay paquete seleccionado
      if (minDuration != null) {
        final selectedDuration = picked.end.difference(picked.start).inDays + 1;
        if (selectedDuration != minDuration) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'El paquete turístico requiere exactamente $minDuration días.\n'
                  'Has seleccionado $selectedDuration días.\n'
                  'Por favor, ajusta las fechas.',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }
      
      setState(() {
        _fechaInicio = picked.start;
        _fechaFin = picked.end;
      });
      _markAsChanged();
    }
  }

  Future<void> _saveReservation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un cliente'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona las fechas del viaje'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = await _storageService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }
      
      if (currentUser.idUsuario == null) {
        throw Exception('ID de usuario no disponible');
      }

      // Parsear precios removiendo separadores de miles
      final precioDestinoText = _precioDestinoController.text.trim().replaceAll('.', '').replaceAll(',', '');
      final totalPagoText = _totalPagoController.text.trim().replaceAll('.', '').replaceAll(',', '');
      
      debugPrint('🔍 Valores antes de guardar:');
      debugPrint('  - Precio destino: "${_precioDestinoController.text}" -> "$precioDestinoText"');
      debugPrint('  - Total pago: "${_totalPagoController.text}" -> "$totalPagoText"');
      debugPrint('  - Cantidad: ${_cantidadPersonasController.text}');
      
      // Validar que el total no esté vacío
      if (totalPagoText.isEmpty || double.tryParse(totalPagoText) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('El precio total es inválido: "$totalPagoText"'),
            backgroundColor: Colors.red,
          ),
        );
        throw Exception('El precio total es inválido: "$totalPagoText"');
      }
      
      print('🔍 ANTES DE CREAR RESERVA:');
      print('  - _isPackage: $_isPackage');
      print('  - _selectedPackageId: $_selectedPackageId');
      print('  - _selectedDestinationId: $_selectedDestinationId');
      print('  - precioDestinoText: "$precioDestinoText"');
      
      final reservation = Reservation(
        id: widget.reservation?.id,
        estado: ReservationStatus.pendiente,
        cantidadPersonas: int.parse(_cantidadPersonasController.text),
        totalPago: double.parse(totalPagoText),
        fechaInicioViaje: _fechaInicio!,
        fechaFinViaje: _fechaFin!,
        idCliente: _selectedClientId!,
        idPaquete: _isPackage ? _selectedPackageId : null,
        idDestino: !_isPackage ? _selectedDestinationId : null,
        precioDestino: !_isPackage && precioDestinoText.isNotEmpty 
            ? double.parse(precioDestinoText) 
            : null,
        idEmpleado: currentUser.idUsuario!,
        notas: _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
      );

      print('🔍 RESERVA CREADA:');
      print('  - idPaquete: ${reservation.idPaquete}');
      print('  - idDestino: ${reservation.idDestino}');
      print('  - precioDestino: ${reservation.precioDestino}');

      await _storageService.saveReservation(reservation);
      
      // Registrar en auditoría
      await AuditService.logAction(
        usuario: currentUser,
        accion: widget.reservation == null ? AuditAction.crearReserva : AuditAction.editarReserva,
        entidad: 'Reserva',
        idEntidad: reservation.id,
        nombreEntidad: reservation.id != null ? 'Reserva #${reservation.id}' : 'Nueva reserva',
        detalles: {
          'cliente_id': _selectedClientId.toString(),
          'total': _totalPagoController.text,
          'personas': _cantidadPersonasController.text,
        },
      );
      
      setState(() => _hasUnsavedChanges = false);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva guardada exitosamente'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.reservation != null;

    return UnsavedChangesHandler(
      hasUnsavedChanges: _hasUnsavedChanges,
      onSave: _saveReservation,
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3D1F6E)),
          onPressed: () async {
            if (_hasUnsavedChanges) {
              final result = await showUnsavedChangesDialog(
                context,
                onSave: _saveReservation,
              );
              if (result == true && mounted) {
                Navigator.of(context).pop();
              }
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Editar Reserva' : 'Nueva Reserva',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 18, color: const Color(0xFF1F1F1F)),
            ),
            Text(
              'Gestión de reservas',
              style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF6F6F6F)),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildSection(
                    title: 'Cliente',
                    children: [
                      DropdownButtonFormField<int>(
                        value: _selectedClientId,
                        decoration: InputDecoration(
                          labelText: 'Cliente *',
                          labelStyle: GoogleFonts.montserrat(fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF3D1F6E), width: 1.5),
                          ),
                          filled: _isAdmin && widget.reservation != null,
                          fillColor: _isAdmin && widget.reservation != null ? Colors.grey[100] : null,
                        ),
                        items: _clients.map((client) {
                          return DropdownMenuItem<int>(
                            value: client.id,
                            child: Text(client.nombreCompleto, style: GoogleFonts.montserrat(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (_isAdmin && widget.reservation != null) ? null : (value) {
                          setState(() => _selectedClientId = value);
                          _markAsChanged();
                        },
                        validator: (value) => value == null ? 'Selecciona un cliente' : null,
                        disabledHint: _selectedClientId != null && _clients.isNotEmpty
                            ? Text(
                                _clients.firstWhere((c) => c.id == _selectedClientId).nombreCompleto,
                                style: GoogleFonts.montserrat(fontSize: 14, color: Colors.black87),
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Tipo de Reserva',
                    children: [
                      // Selector de tipo: Paquete o Destino
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: Text('Paquete Turístico', style: GoogleFonts.montserrat(fontSize: 14)),
                              value: true,
                              groupValue: _isPackage,
                              onChanged: (value) {
                                setState(() {
                                  _isPackage = value!;
                                  _selectedPackageId = null;
                                  _selectedDestinationId = null;
                                  _precioDestinoController.clear();
                                  _totalPagoController.clear();
                                  // Limpiar fechas al cambiar tipo de reserva
                                  _fechaInicio = null;
                                  _fechaFin = null;
                                });
                                _markAsChanged();
                              },
                              activeColor: const Color(0xFF3D1F6E),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: Text('Destino Personalizado', style: GoogleFonts.montserrat(fontSize: 14)),
                              value: false,
                              groupValue: _isPackage,
                              onChanged: (value) {
                                setState(() {
                                  _isPackage = value!;
                                  _selectedPackageId = null;
                                  _selectedDestinationId = null;
                                  _precioDestinoController.clear();
                                  _totalPagoController.clear();
                                  // Limpiar fechas al cambiar tipo de reserva
                                  _fechaInicio = null;
                                  _fechaFin = null;
                                });
                                _markAsChanged();
                              },
                              activeColor: const Color(0xFF3D1F6E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Mostrar dropdown de paquetes o destinos según selección
                      if (_isPackage) ...[
                        DropdownButtonFormField<int>(
                          value: _selectedPackageId,
                          decoration: InputDecoration(
                            labelText: 'Seleccionar paquete *',
                            labelStyle: GoogleFonts.montserrat(fontSize: 13),
                            hintText: _packages.isEmpty ? 'No hay paquetes disponibles' : 'Selecciona un paquete',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.card_travel, size: 20),
                          ),
                          items: _packages.map((package) {
                            return DropdownMenuItem<int>(
                              value: package.id,
                              child: Text(
                                '${package.nombre} (${package.duracionDias} días - ${NumberFormatter.formatCurrency(package.precioBase)})',
                                style: GoogleFonts.montserrat(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: _onPackageSelected,
                          validator: (value) => _isPackage && value == null ? 'Selecciona un paquete' : null,
                        ),
                        if (_selectedPackageId != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Las fechas y precio se ajustarán según el paquete seleccionado',
                                    style: GoogleFonts.montserrat(fontSize: 12, color: Colors.blue[900]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ] else ...[
                        DropdownButtonFormField<int>(
                          value: _selectedDestinationId,
                          decoration: InputDecoration(
                            labelText: 'Seleccionar destino *',
                            labelStyle: GoogleFonts.montserrat(fontSize: 13),
                            hintText: _destinations.isEmpty ? 'No hay destinos disponibles' : 'Selecciona un destino',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.location_on, size: 20),
                          ),
                          items: _destinations.map((destination) {
                            return DropdownMenuItem<int>(
                              value: destination.id,
                              child: Text(
                                '${destination.ciudad}, ${destination.pais}${destination.precioBase != null ? ' - ${NumberFormatter.formatCurrency(destination.precioBase!)}' : ''}',
                                style: GoogleFonts.montserrat(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDestinationId = value;
                              // Auto-completar precio si el destino tiene precio base
                              if (value != null) {
                                final destination = _destinations.firstWhere((d) => d.id == value);
                                if (destination.precioBase != null) {
                                  // Formatear precio como número entero sin decimales
                                  _precioDestinoController.text = destination.precioBase!.toInt().toString();
                                  // Recalcular total
                                  _onDestinationPriceChanged();
                                }
                              }
                            });
                            _markAsChanged();
                          },
                          validator: (value) => !_isPackage && value == null ? 'Selecciona un destino' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _precioDestinoController,
                          decoration: InputDecoration(
                            labelText: 'Precio por persona *',
                            labelStyle: GoogleFonts.montserrat(fontSize: 13),
                            hintText: 'Ingresa el precio',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.attach_money, size: 20),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (!_isPackage && (value == null || value.isEmpty)) {
                              return 'Ingresa el precio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'El precio total se calculará automáticamente según la cantidad de personas',
                                  style: GoogleFonts.montserrat(fontSize: 12, color: Colors.orange[900]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Fechas del Viaje',
                    children: [
                      // Mostrar fecha actual si es edición
                      if (widget.reservation != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D1F6E).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF3D1F6E).withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Color(0xFF3D1F6E)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Fecha programada actualmente:',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF3D1F6E),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${DateFormat('dd/MM/yyyy').format(widget.reservation!.fechaInicioViaje)} - ${DateFormat('dd/MM/yyyy').format(widget.reservation!.fechaFinViaje)}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '(${widget.reservation!.fechaFinViaje.difference(widget.reservation!.fechaInicioViaje).inDays + 1} días)',
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Botón de reprogramar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _selectDateRange(context),
                            icon: const Icon(Icons.event_repeat, size: 18),
                            label: Text(
                              'Reprogramar viaje',
                              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF3D1F6E),
                              side: const BorderSide(color: Color(0xFF3D1F6E), width: 1.5),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Campo para mostrar/seleccionar fechas (solo clic si es nueva reserva)
                      IgnorePointer(
                        ignoring: widget.reservation != null, // Deshabilitar clic si es edición
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: widget.reservation != null 
                                ? 'Nueva fecha del viaje *' 
                                : 'Rango de fechas del viaje *',
                            labelStyle: GoogleFonts.montserrat(fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF3D1F6E), width: 1.5),
                            ),
                            filled: widget.reservation != null,
                            fillColor: widget.reservation != null ? Colors.grey[50] : null,
                          ),
                          child: InkWell(
                            onTap: widget.reservation == null ? () => _selectDateRange(context) : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _fechaInicio != null && _fechaFin != null
                                        ? '${DateFormat('dd/MM/yyyy').format(_fechaInicio!)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}'
                                        : widget.reservation != null 
                                            ? 'Usa el botón "Reprogramar viaje"'
                                            : _isPackage 
                                                ? 'Selecciona un paquete primero'
                                                : 'Seleccionar fechas',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      color: widget.reservation != null && _fechaInicio == null 
                                          ? Colors.grey[500] 
                                          : (_isPackage && _selectedPackageId == null)
                                              ? Colors.grey[500]
                                              : Colors.black87,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.date_range, 
                                  size: 20, 
                                  color: widget.reservation != null && _fechaInicio == null
                                      ? Colors.grey[400]
                                      : const Color(0xFF3D1F6E),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Detalles de la Reserva',
                    children: [
                      TextFormField(
                        controller: _cantidadPersonasController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Cantidad de personas *',
                          labelStyle: GoogleFonts.montserrat(fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.people_outline, size: 20),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Campo obligatorio';
                          if (int.tryParse(value) == null || int.parse(value) < 1) return 'Debe ser mayor a 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _totalPagoController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Precio total *',
                          labelStyle: GoogleFonts.montserrat(fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 16, right: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '\$',
                                  style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3D1F6E)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Campo obligatorio';
                          if (double.tryParse(value) == null) return 'Debe ser un número válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notasController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Notas adicionales',
                          labelStyle: GoogleFonts.montserrat(fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveReservation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D1F6E),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            )
                          : const Icon(Icons.save_rounded, size: 20, color: Colors.white),
                      label: Text(
                        isEditing ? 'Actualizar' : 'Guardar',
                        style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
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
          style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1F1F1F)),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}
