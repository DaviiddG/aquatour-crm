import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/tour_package.dart';
import '../models/destination.dart';
import '../services/storage_service.dart';
import '../utils/currency_input_formatter.dart';

class PackageEditScreen extends StatefulWidget {
  final TourPackage? package;

  const PackageEditScreen({super.key, this.package});

  @override
  State<PackageEditScreen> createState() => _PackageEditScreenState();
}

class _PackageEditScreenState extends State<PackageEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();

  List<Destination> _destinations = [];
  List<int> _selectedDestinations = [];
  
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _precioController;
  late TextEditingController _duracionController;
  late TextEditingController _cupoController;
  late TextEditingController _serviciosController;

  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDestinations = widget.package?.destinosIds ?? [];
    
    _nombreController = TextEditingController(text: widget.package?.nombre ?? '');
    _descripcionController = TextEditingController(text: widget.package?.descripcion ?? '');
    
    // Formatear el precio inicial con puntos de miles
    String initialPrecio = '';
    if (widget.package?.precioBase != null) {
      final formatter = NumberFormat('#,##0', 'es_CO');
      initialPrecio = formatter.format(widget.package!.precioBase.toInt());
    }
    _precioController = TextEditingController(text: initialPrecio);
    
    _duracionController = TextEditingController(text: widget.package?.duracionDias.toString() ?? '');
    _cupoController = TextEditingController(text: widget.package?.cupoMaximo.toString() ?? '');
    _serviciosController = TextEditingController(text: widget.package?.serviciosIncluidos ?? '');
    
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    try {
      final destinations = await _storageService.getDestinations();
      
      debugPrint('🔍 Destinos seleccionados inicialmente: $_selectedDestinations');
      debugPrint('📍 Destinos disponibles: ${destinations.map((d) => '${d.id}: ${d.ciudad}').toList()}');
      
      if (mounted) {
        setState(() {
          _destinations = destinations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando destinos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _duracionController.dispose();
    _cupoController.dispose();
    _serviciosController.dispose();
    super.dispose();
  }

  Future<void> _savePackage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Parsear el precio formateado
      final precio = CurrencyInputFormatter.parseFormattedValue(_precioController.text);
      if (precio == null) {
        throw Exception('Precio inválido');
      }
      
      debugPrint('🔍 Guardando paquete con destinos: $_selectedDestinations');
      
      final package = TourPackage(
        id: widget.package?.id,
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
        precioBase: precio,
        duracionDias: int.parse(_duracionController.text),
        cupoMaximo: int.parse(_cupoController.text),
        serviciosIncluidos: _serviciosController.text.trim().isEmpty ? null : _serviciosController.text.trim(),
        destinosIds: _selectedDestinations,
      );

      await _storageService.savePackage(package);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paquete guardado exitosamente'), backgroundColor: Colors.green),
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
    final isEditing = widget.package != null;

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
              isEditing ? 'Editar Paquete' : 'Nuevo Paquete',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 18, color: const Color(0xFF1F1F1F)),
            ),
            Text(
              'Gestión de paquetes turísticos',
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
                    title: 'Información Básica',
                    children: [
                      TextFormField(
                        controller: _nombreController,
                        decoration: InputDecoration(
                          labelText: 'Nombre del paquete *',
                          labelStyle: GoogleFonts.montserrat(fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.card_travel, size: 20),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descripcionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Descripción',
                          labelStyle: GoogleFonts.montserrat(fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Destinos Incluidos',
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selecciona los destinos del paquete:',
                              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            ..._destinations.map((destination) {
                              final isSelected = _selectedDestinations.contains(destination.id);
                              return CheckboxListTile(
                                title: Text(
                                  '${destination.ciudad}, ${destination.pais}',
                                  style: GoogleFonts.montserrat(fontSize: 14),
                                ),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedDestinations.add(destination.id!);
                                      debugPrint('✅ Destino agregado: ${destination.ciudad} (ID: ${destination.id})');
                                    } else {
                                      _selectedDestinations.remove(destination.id);
                                      debugPrint('❌ Destino removido: ${destination.ciudad} (ID: ${destination.id})');
                                    }
                                    debugPrint('📋 Destinos seleccionados ahora: $_selectedDestinations');
                                  });
                                },
                                activeColor: const Color(0xFF3D1F6E),
                              );
                            }).toList(),
                            if (_destinations.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'No hay destinos disponibles. Crea destinos primero.',
                                  style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Detalles del Paquete',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _precioController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                CurrencyInputFormatter(),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Precio base *',
                                labelStyle: GoogleFonts.montserrat(fontSize: 13),
                                hintText: '0',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                prefixText: '\$ ',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Obligatorio';
                                final parsedValue = CurrencyInputFormatter.parseFormattedValue(value);
                                if (parsedValue == null) return 'Número inválido';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _duracionController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                labelText: 'Duración (días) *',
                                labelStyle: GoogleFonts.montserrat(fontSize: 13),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Obligatorio';
                                if (int.tryParse(value) == null || int.parse(value) < 1) return 'Mínimo 1 día';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cupoController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Cupo máximo *',
                          labelStyle: GoogleFonts.montserrat(fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.people, size: 20),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Campo obligatorio';
                          if (int.tryParse(value) == null || int.parse(value) < 1) return 'Mínimo 1 persona';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _serviciosController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Servicios incluidos',
                          labelStyle: GoogleFonts.montserrat(fontSize: 13),
                          hintText: 'Ej: Hospedaje, alimentación, transporte...',
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
                      onPressed: _isSaving ? null : _savePackage,
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
