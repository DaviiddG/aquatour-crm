import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/contact.dart';
import '../services/storage_service.dart';
import '../widgets/unsaved_changes_dialog.dart';

class ContactEditScreen extends StatefulWidget {
  final Contact? contact;

  const ContactEditScreen({super.key, this.contact});

  @override
  State<ContactEditScreen> createState() => _ContactEditScreenState();
}

class _ContactEditScreenState extends State<ContactEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _companyController;

  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _emailController = TextEditingController(text: widget.contact?.email ?? '');
    _phoneController = TextEditingController(text: widget.contact?.phone ?? '');
    _companyController = TextEditingController(text: widget.contact?.company ?? '');
    
    // Agregar listeners
    _nameController.addListener(_markAsChanged);
    _emailController.addListener(_markAsChanged);
    _phoneController.addListener(_markAsChanged);
    _companyController.addListener(_markAsChanged);
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final contact = Contact(
        id: widget.contact?.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        company: _companyController.text.trim(),
        createdAt: widget.contact?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.contact == null) {
        await _storageService.insertContact(contact);
      } else {
        await _storageService.updateContact(contact);
      }
      
      setState(() => _hasUnsavedChanges = false);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacto guardado exitosamente'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        
        // Extraer mensaje de error limpio
        String errorMessage = e.toString();
        if (errorMessage.contains('Exception:')) {
          errorMessage = errorMessage.replaceFirst('Exception:', '').trim();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.contact != null;

    return UnsavedChangesHandler(
      hasUnsavedChanges: _hasUnsavedChanges,
      onSave: _saveContact,
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3D1F6E)),
          onPressed: () async {
            if (_hasUnsavedChanges) {
              final result = await showUnsavedChangesDialog(
                context,
                onSave: _saveContact,
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
              isEditing ? 'Editar Contacto' : 'Nuevo Contacto',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 18, color: const Color(0xFF1F1F1F)),
            ),
            Text(
              'Gestión de contactos y prospectos',
              style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSection(
              title: 'Información Personal',
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre completo *',
                    labelStyle: GoogleFonts.montserrat(fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.person, size: 20),
                  ),
                  style: GoogleFonts.montserrat(fontSize: 14),
                  validator: (value) => value?.isEmpty ?? true ? 'El nombre es obligatorio' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    labelStyle: GoogleFonts.montserrat(fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.email, size: 20),
                  ),
                  style: GoogleFonts.montserrat(fontSize: 14),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'El email es obligatorio';
                    if (!value!.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Teléfono *',
                    labelStyle: GoogleFonts.montserrat(fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.phone, size: 20),
                  ),
                  style: GoogleFonts.montserrat(fontSize: 14),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  validator: (value) => value?.isEmpty ?? true ? 'El teléfono es obligatorio' : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Información Profesional',
              children: [
                TextFormField(
                  controller: _companyController,
                  decoration: InputDecoration(
                    labelText: 'Empresa *',
                    labelStyle: GoogleFonts.montserrat(fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.business, size: 20),
                  ),
                  style: GoogleFonts.montserrat(fontSize: 14),
                  validator: (value) => value?.isEmpty ?? true ? 'La empresa es obligatoria' : null,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveContact,
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
