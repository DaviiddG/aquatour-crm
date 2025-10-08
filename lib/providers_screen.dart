import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquatour/widgets/module_scaffold.dart';
import 'package:aquatour/models/provider.dart';
import 'package:aquatour/services/storage_service.dart';
import 'package:aquatour/screens/provider_edit_screen.dart';
import 'package:aquatour/utils/permissions_helper.dart';

class ProvidersScreen extends StatefulWidget {
  const ProvidersScreen({super.key});

  @override
  State<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> {
  final StorageService _storageService = StorageService();
  List<Provider> _providers = [];
  bool _isLoading = true;
  bool _canCreate = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadProviders();
  }

  Future<void> _checkPermissions() async {
    final user = await _storageService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _canCreate = PermissionsHelper.canCreateProviders(user.rol);
      });
    }
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);
    try {
      final providers = await _storageService.getProviders();
      if (mounted) {
        setState(() {
          _providers = providers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando proveedores: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openProviderForm({Provider? provider}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProviderEditScreen(provider: provider),
      ),
    );
    if (result == true) {
      _loadProviders();
    }
  }

  Future<void> _deleteProvider(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación', style: GoogleFonts.montserrat()),
        content: Text('¿Estás seguro de eliminar este proveedor?', style: GoogleFonts.montserrat()),
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
      final success = await _storageService.deleteProvider(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Proveedor eliminado' : 'Error eliminando proveedor'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _loadProviders();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      title: 'Proveedores',
      subtitle: 'Estandariza la relación con tus operadores',
      icon: Icons.business_rounded,
      floatingActionButton: _canCreate ? FloatingActionButton.extended(
        onPressed: () => _openProviderForm(),
        backgroundColor: const Color(0xFFf7941e),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Nuevo proveedor', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600)),
      ) : null,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _providers.isEmpty
              ? _buildEmptyState()
              : _buildProvidersList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay proveedores',
            style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primer proveedor usando el botón naranja',
            style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildProvidersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _providers.length,
      itemBuilder: (context, index) {
        final provider = _providers[index];
        return _ProviderCard(
          provider: provider,
          onTap: () => _openProviderForm(provider: provider),
          onDelete: () => _deleteProvider(provider.id!),
        );
      },
    );
  }
}

class _ProviderCard extends StatefulWidget {
  const _ProviderCard({
    required this.provider,
    required this.onTap,
    required this.onDelete,
  });

  final Provider provider;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<_ProviderCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.provider.estado == ProviderStatus.activo ? Colors.green : Colors.grey;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? const Color(0xFF3D1F6E).withOpacity(0.15) : Colors.black.withOpacity(0.05),
              blurRadius: _isHovered ? 12 : 4,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
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
                    child: const Icon(Icons.business, color: Color(0xFF3D1F6E), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.provider.nombre,
                          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.provider.tipoProveedor} • ${widget.provider.telefono}',
                          style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.provider.estado.displayName,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
