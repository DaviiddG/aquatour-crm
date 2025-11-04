import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/destination.dart';
import '../services/storage_service.dart';
import '../services/audit_service.dart';
import '../models/audit_log.dart';
import '../data/countries_cities.dart';
import '../widgets/unsaved_changes_dialog.dart';

class DestinationEditScreen extends StatefulWidget {
  final Destination? destination;

  const DestinationEditScreen({super.key, this.destination});

  @override
  State<DestinationEditScreen> createState() => _DestinationEditScreenState();
}

class _DestinationEditScreenState extends State<DestinationEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();

  String? _selectedPais;
  String? _selectedCiudad;
  List<String> _availableCities = [];
  late TextEditingController _descripcionController;
  late TextEditingController _climaController;
  late TextEditingController _temporadaController;
  late TextEditingController _idiomaController;
  late TextEditingController _monedaController;

  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _selectedPais = widget.destination?.pais;
    _selectedCiudad = widget.destination?.ciudad;
    if (_selectedPais != null) {
      _availableCities = getCitiesForCountry(_selectedPais!);
    }
    _descripcionController = TextEditingController(text: widget.destination?.descripcion ?? '');
    _climaController = TextEditingController(text: widget.destination?.climaPromedio ?? '');
    _temporadaController = TextEditingController(text: widget.destination?.temporadaAlta ?? '');
    _idiomaController = TextEditingController(text: widget.destination?.idiomaPrincipal ?? '');
    _monedaController = TextEditingController(text: widget.destination?.moneda ?? '');
    
    // Agregar listeners para detectar cambios
    _descripcionController.addListener(_markAsChanged);
    _climaController.addListener(_markAsChanged);
    _temporadaController.addListener(_markAsChanged);
    _idiomaController.addListener(_markAsChanged);
    _monedaController.addListener(_markAsChanged);
  }
  
  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _climaController.dispose();
    _temporadaController.dispose();
    _idiomaController.dispose();
    _monedaController.dispose();
    super.dispose();
  }

  Future<void> _saveDestination() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final destination = Destination(
        id: widget.destination?.id,
        ciudad: _selectedCiudad!,
        pais: _selectedPais!,
        descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
        climaPromedio: _climaController.text.trim().isEmpty ? null : _climaController.text.trim(),
        temporadaAlta: _temporadaController.text.trim().isEmpty ? null : _temporadaController.text.trim(),
        idiomaPrincipal: _idiomaController.text.trim().isEmpty ? null : _idiomaController.text.trim(),
        moneda: _monedaController.text.trim().isEmpty ? null : _monedaController.text.trim(),
      );

      await _storageService.saveDestination(destination);
      
      // Registrar en auditoría
      final currentUser = await _storageService.getCurrentUser();
      if (currentUser != null) {
        await AuditService.logAction(
          usuario: currentUser,
          accion: widget.destination == null ? AuditAction.crearDestino : AuditAction.editarDestino,
          entidad: 'Destino',
          idEntidad: destination.id,
          nombreEntidad: '${destination.ciudad}, ${destination.pais}',
        );
      }
      
      // Resetear el flag de cambios sin guardar
      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.destination == null
                  ? 'Destino creado exitosamente'
                  : 'Destino actualizado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar destino: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.destination != null;

    return UnsavedChangesHandler(
      hasUnsavedChanges: _hasUnsavedChanges,
      onSave: _saveDestination,
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3D1F6E)),
          onPressed: () async {
            if (_hasUnsavedChanges) {
              final result = await showUnsavedChangesDialog(
                context,
                onSave: _saveDestination,
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
              isEditing ? 'Editar Destino' : 'Nuevo Destino',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: const Color(0xFF1F1F1F),
              ),
            ),
            Text(
              'Gestión de destinos',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: const Color(0xFF6F6F6F),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSection(
              title: 'Información Básica',
              children: [
                _buildDropdown(
                  label: 'País *',
                  value: _selectedPais,
                  items: getCountries(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPais = value;
                      _selectedCiudad = null;
                      _availableCities = value != null ? getCitiesForCountry(value) : [];
                      // Auto-completar clima, moneda e idioma
                      if (value != null) {
                        _climaController.text = getClimateForCountry(value) ?? '';
                        _monedaController.text = getCurrencyForCountry(value) ?? '';
                        _idiomaController.text = getLanguageForCountry(value) ?? '';
                      }
                    });
                    _markAsChanged();
                  },
                  validator: (value) => value == null ? 'El país es obligatorio' : null,
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Ciudad *',
                  value: _selectedCiudad,
                  items: _availableCities,
                  onChanged: (value) {
                    setState(() => _selectedCiudad = value);
                    _markAsChanged();
                  },
                  validator: (value) => value == null ? 'La ciudad es obligatoria' : null,
                  enabled: _selectedPais != null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descripcionController,
                  label: 'Descripción',
                  icon: Icons.description_rounded,
                  maxLines: 4,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Detalles del Destino',
              children: [
                _buildTextField(
                  controller: _climaController,
                  label: 'Clima Promedio',
                  icon: Icons.thermostat_rounded,
                  hint: 'Ej: Tropical, 25-30°C',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _temporadaController,
                  label: 'Temporada Alta',
                  icon: Icons.calendar_today_rounded,
                  hint: 'Ej: Diciembre - Marzo',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _idiomaController,
                  label: 'Idioma Principal',
                  icon: Icons.language_rounded,
                  hint: 'Ej: Español, Inglés',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _monedaController,
                  label: 'Moneda',
                  icon: Icons.attach_money_rounded,
                  hint: 'Ej: USD, EUR, COP',
                ),
              ],
            ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveDestination,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D1F6E),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 20, color: Colors.white),
                label: Text(
                  isEditing ? 'Actualizar' : 'Guardar',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
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
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    // Asegurar que el valor actual esté en la lista de items
    final validValue = (value != null && items.contains(value)) ? value : null;
    
    return DropdownButtonFormField<String>(
      value: validValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3D1F6E), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      items: items.toSet().toList().map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: GoogleFonts.montserrat(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
      style: GoogleFonts.montserrat(fontSize: 14, color: Colors.black),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.montserrat(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[400]),
        labelStyle: GoogleFonts.montserrat(fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3D1F6E), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
