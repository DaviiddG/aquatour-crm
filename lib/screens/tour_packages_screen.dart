import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquatour/widgets/module_scaffold.dart';
import 'package:aquatour/models/tour_package.dart';
import 'package:aquatour/services/storage_service.dart';
import 'package:aquatour/screens/package_edit_screen.dart';

class TourPackagesScreen extends StatefulWidget {
  const TourPackagesScreen({super.key});

  @override
  State<TourPackagesScreen> createState() => _TourPackagesScreenState();
}

class _TourPackagesScreenState extends State<TourPackagesScreen> {
  final StorageService _storageService = StorageService();
  List<TourPackage> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);
    try {
      final packages = await _storageService.getPackages();
      if (mounted) {
        setState(() {
          _packages = packages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando paquetes: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openPackageForm({TourPackage? package}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PackageEditScreen(package: package),
      ),
    );
    if (result == true) {
      _loadPackages();
    }
  }

  Future<void> _deletePackage(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación', style: GoogleFonts.montserrat()),
        content: Text('¿Estás seguro de eliminar este paquete?', style: GoogleFonts.montserrat()),
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
      final success = await _storageService.deletePackage(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Paquete eliminado' : 'Error eliminando paquete'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _loadPackages();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      title: 'Paquetes turísticos',
      subtitle: 'Diseña propuestas completas y personalizadas para tus clientes',
      icon: Icons.card_travel_rounded,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPackageForm(),
        backgroundColor: const Color(0xFFf7941e),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Nuevo paquete', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _packages.isEmpty
              ? _buildEmptyState()
              : _buildPackagesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_travel_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay paquetes turísticos',
            style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primer paquete usando el botón naranja',
            style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _packages.length,
      itemBuilder: (context, index) {
        final package = _packages[index];
        return _PackageCard(
          package: package,
          onTap: () => _openPackageForm(package: package),
          onDelete: () => _deletePackage(package.id!),
        );
      },
    );
  }
}

class _PackageCard extends StatefulWidget {
  const _PackageCard({
    required this.package,
    required this.onTap,
    required this.onDelete,
  });

  final TourPackage package;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
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
                    child: const Icon(Icons.card_travel, color: Color(0xFF3D1F6E), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.package.nombre,
                          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.package.duracionDias} días • \$${widget.package.precioBase.toStringAsFixed(2)} • ${widget.package.destinosIds.length} destino(s)',
                          style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
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

class _PackageSummaryCard extends StatelessWidget {
  const _PackageSummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.description,
  });

  final IconData icon;
  final String label;
  final String value;
  final String description;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3D1F6E).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xFF3D1F6E)),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6F6F6F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: GoogleFonts.montserrat(
                fontSize: 12.5,
                height: 1.5,
                color: const Color(0xFF4B4B4B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
