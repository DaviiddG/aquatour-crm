import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquatour/widgets/module_scaffold.dart';
import 'package:aquatour/models/tour_package.dart';
import 'package:aquatour/services/storage_service.dart';
import 'package:aquatour/screens/package_edit_screen.dart';
import '../utils/number_formatter.dart';
import '../utils/permissions_helper.dart';

class TourPackagesScreen extends StatefulWidget {
  const TourPackagesScreen({super.key});

  @override
  State<TourPackagesScreen> createState() => _TourPackagesScreenState();
}

class _TourPackagesScreenState extends State<TourPackagesScreen> {
  final StorageService _storageService = StorageService();
  List<TourPackage> _packages = [];
  bool _isLoading = true;
  bool _canCreate = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadPackages();
  }

  Future<void> _checkPermissions() async {
    final user = await _storageService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _canCreate = PermissionsHelper.canCreatePackages(user.rol);
      });
    }
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
      try {
        await _storageService.deletePackage(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Paquete eliminado exitosamente', style: GoogleFonts.montserrat()),
              backgroundColor: Colors.green,
            ),
          );
          _loadPackages();
        }
      } catch (e) {
        if (mounted) {
          // Extraer el mensaje de error del servidor
          String errorMessage = 'Error eliminando paquete';
          if (e.toString().contains('Exception:')) {
            errorMessage = e.toString().replaceAll('Exception:', '').trim();
          } else if (e.toString().contains(':')) {
            errorMessage = e.toString().split(':').last.trim();
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage, style: GoogleFonts.montserrat()),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5), // Más tiempo para leer el mensaje
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      title: 'Paquetes turísticos',
      subtitle: _canCreate 
          ? 'Centraliza paquetes base y promociones para el equipo'
          : 'Consulta los paquetes disponibles para tus cotizaciones',
      icon: Icons.card_travel_rounded,
      floatingActionButton: _canCreate ? FloatingActionButton.extended(
        onPressed: () => _openPackageForm(),
        backgroundColor: const Color(0xFFf7941e),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Nuevo paquete', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600)),
      ) : null,
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
            _canCreate
                ? 'Crea tu primer paquete usando el botón naranja'
                : 'Aún no hay paquetes disponibles en el catálogo',
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
          canModify: _canCreate, // Solo admins pueden modificar
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
    required this.canModify,
    required this.onTap,
    required this.onDelete,
  });

  final TourPackage package;
  final bool canModify;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard> {
  bool _isHovered = false;
  final StorageService _storageService = StorageService();
  List<String> _destinationNames = [];
  bool _isLoadingDestinations = true;

  @override
  void initState() {
    super.initState();
    _loadDestinationNames();
  }

  Future<void> _loadDestinationNames() async {
    try {
      debugPrint('🔍 Cargando destinos para paquete: ${widget.package.nombre}');
      debugPrint('🔍 IDs de destinos: ${widget.package.destinosIds}');
      
      if (widget.package.destinosIds.isEmpty) {
        debugPrint('⚠️ El paquete no tiene destinos asignados');
        if (mounted) {
          setState(() {
            _destinationNames = [];
            _isLoadingDestinations = false;
          });
        }
        return;
      }
      
      final allDestinations = await _storageService.getAllDestinations();
      debugPrint('📍 Total destinos disponibles: ${allDestinations.length}');
      
      final names = <String>[];
      for (final id in widget.package.destinosIds) {
        try {
          final dest = allDestinations.firstWhere((d) => d.id == id);
          names.add('${dest.ciudad}, ${dest.pais}');
          debugPrint('✅ Destino encontrado: ${dest.ciudad}, ${dest.pais}');
        } catch (e) {
          debugPrint('❌ Destino con ID $id no encontrado');
        }
      }
      
      if (mounted) {
        setState(() {
          _destinationNames = names;
          _isLoadingDestinations = false;
        });
      }
      
      debugPrint('✅ Destinos cargados: $_destinationNames');
    } catch (e) {
      debugPrint('❌ Error cargando destinos: $e');
      if (mounted) {
        setState(() {
          _destinationNames = [];
          _isLoadingDestinations = false;
        });
      }
    }
  }

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
            onTap: widget.canModify ? widget.onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.package.duracionDias} días',
                              style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[700]),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.attach_money, size: 14, color: Colors.grey[600]),
                            Text(
                              NumberFormatter.formatCurrency(widget.package.precioBase),
                              style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF3D1F6E)),
                            ),
                          ],
                        ),
                        if (!_isLoadingDestinations && _destinationNames.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.place, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _destinationNames.join(' • '),
                                  style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[700]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (widget.package.descripcion != null && widget.package.descripcion!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.package.descripcion!,
                            style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600], height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.canModify) ...[
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
