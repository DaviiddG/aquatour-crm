import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/quote.dart';
import '../models/client.dart';
import '../models/tour_package.dart';
import '../models/companion.dart';
import '../services/storage_service.dart';
import '../utils/number_formatter.dart';
import '../widgets/unsaved_changes_dialog.dart';

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
  
  // Acompañantes
  List<Companion> _acompanantes = [];
  bool _tieneAcompanantes = false;

  bool _isSaving = false;
  bool _isLoading = true;
  
  // Control de cambios sin guardar
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.quote?.idCliente;
    _selectedPackageId = widget.quote?.idPaquete;
    _fechaInicio = widget.quote?.fechaInicioViaje;
    _fechaFin = widget.quote?.fechaFinViaje;
    _precioEstimado = widget.quote?.precioEstimado ?? 0.0;
    _acompanantes = widget.quote?.acompanantes ?? [];
    _tieneAcompanantes = _acompanantes.isNotEmpty;
    
    _loadData();
  }
  
  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
      debugPrint('🔔 CAMBIOS DETECTADOS: _hasUnsavedChanges = true');
    }
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
      _markAsChanged();
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
      _markAsChanged();
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
        acompanantes: _acompanantes,
      );

      await _storageService.saveQuote(quote);
      
      // Resetear el flag de cambios sin guardar
      setState(() {
        _hasUnsavedChanges = false;
      });

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

    return UnsavedChangesHandler(
      hasUnsavedChanges: _hasUnsavedChanges,
      onSave: _saveQuote,
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3D1F6E)),
          onPressed: () async {
            if (_hasUnsavedChanges) {
              final result = await showUnsavedChangesDialog(
                context,
                onSave: _saveQuote,
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
                        onChanged: (value) {
                          setState(() => _selectedClientId = value);
                          _markAsChanged();
                        },
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
                  _buildAcompanantesSection(),
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

  Widget _buildAcompanantesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Acompañantes',
              style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1F1F1F)),
            ),
            const SizedBox(width: 12),
            Switch(
              value: _tieneAcompanantes,
              onChanged: (value) {
                setState(() {
                  _tieneAcompanantes = value;
                  if (!value) {
                    _acompanantes.clear();
                  }
                });
                _markAsChanged();
              },
              activeColor: const Color(0xFF3D1F6E),
            ),
            Text(
              _tieneAcompanantes ? 'Sí' : 'No',
              style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        ),
        if (_tieneAcompanantes) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lista de Acompañantes (${_acompanantes.length})',
                      style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _addAcompanante(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D1F6E),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                      label: Text(
                        'Agregar',
                        style: GoogleFonts.montserrat(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_acompanantes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No hay acompañantes agregados. Presiona "Agregar" para incluir uno.',
                            style: GoogleFonts.montserrat(fontSize: 12, color: Colors.orange[900]),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _acompanantes.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final acomp = _acompanantes[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: acomp.esMenor ? Colors.blue[50] : Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                acomp.esMenor ? Icons.child_care : Icons.person,
                                color: acomp.esMenor ? Colors.blue[700] : Colors.green[700],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    acomp.nombreCompleto,
                                    style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (acomp.edad != null) ...[
                                        Text(
                                          '${acomp.edad} años',
                                          style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600]),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: acomp.esMenor ? Colors.blue[100] : Colors.green[100],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          acomp.esMenor ? 'Menor' : 'Adulto',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: acomp.esMenor ? Colors.blue[900] : Colors.green[900],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () => _editAcompanante(index),
                              color: const Color(0xFF3D1F6E),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () => _removeAcompanante(index),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _addAcompanante() async {
    final result = await showDialog<Companion>(
      context: context,
      builder: (context) => _CompanionDialog(),
    );
    if (result != null) {
      setState(() {
        _acompanantes.add(result);
      });
      _markAsChanged();
    }
  }

  void _editAcompanante(int index) async {
    final result = await showDialog<Companion>(
      context: context,
      builder: (context) => _CompanionDialog(companion: _acompanantes[index]),
    );
    if (result != null) {
      setState(() {
        _acompanantes[index] = result;
      });
      _markAsChanged();
    }
  }

  void _removeAcompanante(int index) {
    setState(() {
      _acompanantes.removeAt(index);
    });
    _markAsChanged();
  }
}

// Dialog para agregar/editar acompañante
class _CompanionDialog extends StatefulWidget {
  final Companion? companion;

  const _CompanionDialog({this.companion});

  @override
  State<_CompanionDialog> createState() => _CompanionDialogState();
}

class _CompanionDialogState extends State<_CompanionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombresController;
  late TextEditingController _apellidosController;
  late TextEditingController _documentoController;
  late TextEditingController _nacionalidadController;
  DateTime? _fechaNacimiento;
  bool _esMenor = false;

  @override
  void initState() {
    super.initState();
    _nombresController = TextEditingController(text: widget.companion?.nombres ?? '');
    _apellidosController = TextEditingController(text: widget.companion?.apellidos ?? '');
    _documentoController = TextEditingController(text: widget.companion?.documento ?? '');
    _nacionalidadController = TextEditingController(text: widget.companion?.nacionalidad ?? 'Perú');
    _fechaNacimiento = widget.companion?.fechaNacimiento;
    _esMenor = widget.companion?.esMenor ?? false;
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _documentoController.dispose();
    _nacionalidadController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF3D1F6E)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fechaNacimiento = picked;
        // Calcular si es menor automáticamente
        final edad = DateTime.now().year - picked.year;
        _esMenor = edad < 18;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final companion = Companion(
      nombres: _nombresController.text.trim(),
      apellidos: _apellidosController.text.trim(),
      documento: _documentoController.text.trim().isEmpty ? null : _documentoController.text.trim(),
      nacionalidad: _nacionalidadController.text.trim().isEmpty ? null : _nacionalidadController.text.trim(),
      fechaNacimiento: _fechaNacimiento,
      esMenor: _esMenor,
    );

    Navigator.of(context).pop(companion);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.companion == null ? 'Agregar Acompañante' : 'Editar Acompañante',
                  style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF3D1F6E)),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nombresController,
                  decoration: InputDecoration(
                    labelText: 'Nombres *',
                    labelStyle: GoogleFonts.montserrat(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.person, size: 20),
                  ),
                  validator: (value) => value?.trim().isEmpty ?? true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _apellidosController,
                  decoration: InputDecoration(
                    labelText: 'Apellidos *',
                    labelStyle: GoogleFonts.montserrat(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                  ),
                  validator: (value) => value?.trim().isEmpty ?? true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _documentoController,
                  decoration: InputDecoration(
                    labelText: 'Documento (Opcional)',
                    labelStyle: GoogleFonts.montserrat(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.badge, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nacionalidadController,
                  decoration: InputDecoration(
                    labelText: 'Nacionalidad (Opcional)',
                    labelStyle: GoogleFonts.montserrat(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.flag, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Fecha de Nacimiento (Opcional)',
                      labelStyle: GoogleFonts.montserrat(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.cake, size: 20),
                    ),
                    child: Text(
                      _fechaNacimiento != null
                          ? DateFormat('dd/MM/yyyy').format(_fechaNacimiento!)
                          : 'Seleccionar fecha',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: _fechaNacimiento != null ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: Text('Es menor de edad', style: GoogleFonts.montserrat(fontSize: 13)),
                  value: _esMenor,
                  onChanged: (value) => setState(() => _esMenor = value ?? false),
                  activeColor: const Color(0xFF3D1F6E),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancelar', style: GoogleFonts.montserrat(color: Colors.grey[700])),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D1F6E),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Guardar', style: GoogleFonts.montserrat(color: Colors.white)),
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
