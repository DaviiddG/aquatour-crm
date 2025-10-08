import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/provider.dart';
import '../services/storage_service.dart';

class ProviderEditScreen extends StatefulWidget {
  final Provider? provider;

  const ProviderEditScreen({super.key, this.provider});

  @override
  State<ProviderEditScreen> createState() => _ProviderEditScreenState();
}

class _ProviderEditScreenState extends State<ProviderEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();

  late TextEditingController _nombreController;
  late TextEditingController _tipoController;
  late TextEditingController _telefonoController;
  late TextEditingController _correoController;
  ProviderStatus _estado = ProviderStatus.activo;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.provider?.nombre ?? '');
    _tipoController = TextEditingController(text: widget.provider?.tipoProveedor ?? '');
    _telefonoController = TextEditingController(text: widget.provider?.telefono ?? '');
    _correoController = TextEditingController(text: widget.provider?.correo ?? '');
    _estado = widget.provider?.estado ?? ProviderStatus.activo;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _tipoController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _saveProvider() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final provider = Provider(
        id: widget.provider?.id,
        nombre: _nombreController.text.trim(),
        tipoProveedor: _tipoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        correo: _correoController.text.trim(),
        estado: _estado,
      );

      await _storageService.saveProvider(provider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proveedor guardado exitosamente'), backgroundColor: Colors.green),
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
    final isEditing = widget.provider != null;

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
              isEditing ? 'Editar Proveedor' : 'Nuevo Proveedor',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 18, color: const Color(0xFF1F1F1F)),
            ),
            Text(
              'Gestión de proveedores',
              style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF6F6F6F)),
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
              title: 'Información del Proveedor',
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del proveedor *',
                    labelStyle: GoogleFonts.montserrat(fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.business, size: 20),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tipoController,
                  decoration: InputDecoration(
                    labelText: 'Tipo de proveedor *',
                    labelStyle: GoogleFonts.montserrat(fontSize: 13),
                    hintText: 'Ej: Hospedaje, Transporte, Actividades',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.category, size: 20),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Campo obligatorio' : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Información de Contacto',
              children: [
                TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Teléfono *',
                    labelStyle: GoogleFonts.montserrat(fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.phone, size: 20),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico *',
                    labelStyle: GoogleFonts.montserrat(fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.email, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Campo obligatorio';
                    if (!value.contains('@')) return 'Correo inválido';
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Estado',
              children: [
                DropdownButtonFormField<ProviderStatus>(
                  value: _estado,
                  decoration: InputDecoration(
                    labelText: 'Estado del proveedor',
                    labelStyle: GoogleFonts.montserrat(fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.toggle_on, size: 20),
                  ),
                  items: ProviderStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.displayName, style: GoogleFonts.montserrat(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _estado = value!),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProvider,
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
