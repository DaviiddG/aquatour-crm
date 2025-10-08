import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/reservation.dart';
import '../models/client.dart';
import '../models/tour_package.dart';
import '../services/storage_service.dart';

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
  int? _selectedClientId;
  int? _selectedPackageId;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  
  late TextEditingController _cantidadPersonasController;
  late TextEditingController _totalPagoController;
  late TextEditingController _notasController;

  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.reservation?.idCliente;
    _selectedPackageId = widget.reservation?.idPaquete;
    _fechaInicio = widget.reservation?.fechaInicioViaje;
    _fechaFin = widget.reservation?.fechaFinViaje;
    
    _cantidadPersonasController = TextEditingController(
      text: widget.reservation?.cantidadPersonas.toString() ?? '1',
    );
    _totalPagoController = TextEditingController(
      text: widget.reservation?.totalPago.toString() ?? '',
    );
    _notasController = TextEditingController(
      text: widget.reservation?.notas ?? '',
    );
    
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final currentUser = await _storageService.getCurrentUser();
      if (currentUser != null) {
        final clients = await _storageService.getClients(forEmployeeId: currentUser.idUsuario);
        final packages = await _storageService.getPackages();
        if (mounted) {
          setState(() {
            _clients = clients;
            _packages = packages;
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

  void _onPackageSelected(int? packageId) {
    setState(() {
      _selectedPackageId = packageId;
      if (packageId != null) {
        final package = _packages.firstWhere((p) => p.id == packageId);
        // Sugerir duración basada en el paquete
        if (_fechaInicio != null) {
          _fechaFin = _fechaInicio!.add(Duration(days: package.duracionDias));
        }
        // Sugerir precio base
        if (_totalPagoController.text.isEmpty) {
          _totalPagoController.text = package.precioBase.toString();
        }
      }
    });
  }

  @override
  void dispose() {
    _cantidadPersonasController.dispose();
    _totalPagoController.dispose();
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
      // Validar duración mínima si hay paquete seleccionado
      if (minDuration != null) {
        final selectedDuration = picked.end.difference(picked.start).inDays + 1;
        if (selectedDuration < minDuration) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('El paquete requiere mínimo $minDuration días. Seleccionaste $selectedDuration días.'),
                backgroundColor: Colors.orange,
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

      final reservation = Reservation(
        id: widget.reservation?.id,
        estado: ReservationStatus.pendiente,
        cantidadPersonas: int.parse(_cantidadPersonasController.text),
        totalPago: double.parse(_totalPagoController.text),
        fechaInicioViaje: _fechaInicio!,
        fechaFinViaje: _fechaFin!,
        idCliente: _selectedClientId!,
        idPaquete: _selectedPackageId,
        idEmpleado: currentUser.idUsuario!,
        notas: _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
      );

      debugPrint('🔍 Creando reserva con idEmpleado: ${currentUser.idUsuario}, idPaquete: $_selectedPackageId');

      await _storageService.saveReservation(reservation);

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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3D1F6E)),
          onPressed: () => Navigator.of(context).pop(),
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
                          labelText: 'Seleccionar cliente *',
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
                        ),
                        items: _clients.map((client) {
                          return DropdownMenuItem<int>(
                            value: client.id,
                            child: Text(client.nombreCompleto, style: GoogleFonts.montserrat(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedClientId = value),
                        validator: (value) => value == null ? 'Selecciona un cliente' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Paquete Turístico (Opcional)',
                    children: [
                      DropdownButtonFormField<int>(
                        value: _selectedPackageId,
                        decoration: InputDecoration(
                          labelText: 'Seleccionar paquete',
                          labelStyle: GoogleFonts.montserrat(fontSize: 13),
                          hintText: _packages.isEmpty ? 'No hay paquetes disponibles' : 'Sin paquete (destino individual)',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.card_travel, size: 20),
                        ),
                        items: _packages.map((package) {
                          return DropdownMenuItem<int>(
                            value: package.id,
                            child: Text(
                              '${package.nombre} (${package.duracionDias} días - \$${package.precioBase.toStringAsFixed(0)})',
                              style: GoogleFonts.montserrat(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: _onPackageSelected,
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
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Fechas del Viaje',
                    children: [
                      InkWell(
                        onTap: () => _selectDateRange(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Rango de fechas del viaje *',
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
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fechaInicio != null && _fechaFin != null
                                    ? '${DateFormat('dd/MM/yyyy').format(_fechaInicio!)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}'
                                    : 'Seleccionar fechas',
                                style: GoogleFonts.montserrat(fontSize: 14),
                              ),
                              const Icon(Icons.date_range, size: 20, color: Color(0xFF3D1F6E)),
                            ],
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
