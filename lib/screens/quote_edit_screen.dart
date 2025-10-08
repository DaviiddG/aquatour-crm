import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/quote.dart';
import '../models/client.dart';
import '../models/tour_package.dart';
import '../services/storage_service.dart';
import '../utils/number_formatter.dart';

class QuoteEditScreen extends StatefulWidget {
  final Quote? quote;

  const QuoteEditScreen({super.key, this.quote});

  @override
  State<QuoteEditScreen> createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();

  List<Client> _clients = [];
  List<TourPackage> _packages = [];
  int? _selectedClientId;
  int? _selectedPackageId;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  double _precioEstimado = 0.0;

  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.quote?.idCliente;
    _selectedPackageId = widget.quote?.idPaquete;
    _fechaInicio = widget.quote?.fechaInicioViaje;
    _fechaFin = widget.quote?.fechaFinViaje;
    _precioEstimado = widget.quote?.precioEstimado ?? 0.0;
    
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
        // Calcular precio automáticamente
        _precioEstimado = package.precioBase;
        // Sugerir duración
        if (_fechaInicio != null) {
          _fechaFin = _fechaInicio!.add(Duration(days: package.duracionDias));
        }
      }
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
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
    );

    if (picked != null) {
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

  Future<void> _saveQuote() async {
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
      if (currentUser?.idUsuario == null) {
        throw Exception('ID de usuario no disponible');
      }

      final quote = Quote(
        id: widget.quote?.id,
        fechaInicioViaje: _fechaInicio!,
        fechaFinViaje: _fechaFin!,
        precioEstimado: _precioEstimado,
        idPaquete: _selectedPackageId,
        idCliente: _selectedClientId!,
        idEmpleado: currentUser!.idUsuario!,
      );

      await _storageService.saveQuote(quote);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cotización guardada exitosamente'), backgroundColor: Colors.green),
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
    final isEditing = widget.quote != null;

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
              isEditing ? 'Editar Cotización' : 'Nueva Cotización',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 18, color: const Color(0xFF1F1F1F)),
            ),
            Text(
              'Genera propuestas para tus clientes',
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
                          prefixIcon: const Icon(Icons.person, size: 20),
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
                              '${package.nombre} (${package.duracionDias} días - ${NumberFormatter.formatCurrency(package.precioBase)})',
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
                                  'El precio se calculó automáticamente según el paquete',
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
                            prefixIcon: const Icon(Icons.calendar_today, size: 20),
                          ),
                          child: Text(
                            _fechaInicio != null && _fechaFin != null
                                ? '${DateFormat('dd/MM/yyyy').format(_fechaInicio!)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}'
                                : 'Seleccionar fechas',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: _fechaInicio != null ? Colors.black87 : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Precio Estimado',
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D1F6E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Precio estimado:',
                              style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              NumberFormatter.formatCurrencyWithDecimals(_precioEstimado),
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF3D1F6E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveQuote,
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
