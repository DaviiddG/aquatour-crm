import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquatour/widgets/module_scaffold.dart';
import 'package:aquatour/models/destination.dart';
import 'package:aquatour/services/storage_service.dart';
import 'package:aquatour/utils/permissions_helper.dart';
import 'package:aquatour/utils/number_formatter.dart';
import 'destination_edit_screen.dart';

class DestinationsScreen extends StatefulWidget {
  const DestinationsScreen({super.key});

  @override
  State<DestinationsScreen> createState() => _DestinationsScreenState();
}

class _DestinationsScreenState extends State<DestinationsScreen> {
  final StorageService _storageService = StorageService();
  List<Destination> _destinations = [];
  bool _isLoading = true;
  bool _canCreate = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadDestinations();
  }

  Future<void> _checkPermissions() async {
    final user = await _storageService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _canCreate = PermissionsHelper.canCreateDestinations(user.rol);
      });
    }
  }

  Future<void> _loadDestinations() async {
    setState(() => _isLoading = true);
    try {
      final destinations = await _storageService.getAllDestinations();
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
          SnackBar(
            content: Text('Error cargando destinos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryCards = [
      _DestinationSummaryCard(
        icon: Icons.place_rounded,
        label: 'Total de destinos',
        value: '${_destinations.length}',
        description: 'Destinos activos en tu catálogo de viajes.',
      ),
      _DestinationSummaryCard(
        icon: Icons.public_rounded,
        label: 'Países disponibles',
        value: '${_destinations.map((d) => d.pais).toSet().length}',
        description: 'Países únicos en tu portafolio.',
      ),
      _DestinationSummaryCard(
        icon: Icons.location_city_rounded,
        label: 'Ciudades únicas',
        value: '${_destinations.map((d) => d.ciudad).toSet().length}',
        description: 'Ciudades diferentes disponibles para tus clientes.',
      ),
    ];

    return ModuleScaffold(
      title: 'Destinos disponibles',
      subtitle: 'Explora y administra el portafolio de viajes para tus clientes.',
      icon: Icons.flight_takeoff_rounded,
      floatingActionButton: _canCreate ? FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const DestinationEditScreen(),
            ),
          );
          if (result == true) {
            _loadDestinations();
          }
        },
        backgroundColor: const Color(0xFFfdb913),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo destino'),
      ) : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 1180;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: summaryCards
                      .map((card) => SizedBox(
                            width: isWide ? (constraints.maxWidth - 32) / 3 : double.infinity,
                            child: card,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 26, 28, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _canCreate ? 'Construye tu catálogo' : 'Explora nuestro catálogo',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3D1F6E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _canCreate
                              ? 'Administra información clave como temporadas, actividades, partners y costos locales. '
                                'Muy pronto podrás importar catálogos masivos y sincronizarlos con tus propuestas.'
                              : 'Consulta los destinos disponibles para crear cotizaciones y reservas personalizadas para tus clientes. '
                                'Encuentra información sobre clima, temporadas y actividades de cada destino.',
                          style: GoogleFonts.montserrat(fontSize: 14, height: 1.55, color: Colors.black87),
                        ),
                        const SizedBox(height: 22),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _destinations.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3D1F6E).withOpacity(0.08),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.public_rounded, color: Color(0xFF3D1F6E), size: 38),
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          'Aún no hay destinos publicados.',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1F1F1F),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Carga tus primeros destinos para ofrecer experiencias únicas a tus clientes.',
                                          style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[700], height: 1.5),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _destinations.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final destination = _destinations[index];
                                      return _DestinationCard(
                                        destination: destination,
                                        canModify: _canCreate, // Solo admins pueden modificar
                                      );
                                    },
                                  ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DestinationCard extends StatefulWidget {
  const _DestinationCard({
    required this.destination,
    required this.canModify,
  });

  final Destination destination;
  final bool canModify;

  @override
  State<_DestinationCard> createState() => _DestinationCardState();
}

class _DestinationCardState extends State<_DestinationCard> {
  bool _isHovered = false;
  final StorageService _storageService = StorageService();

  Future<void> _deleteDestination(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar destino',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar ${widget.destination.ciudad}, ${widget.destination.pais}?',
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: GoogleFonts.montserrat()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar', style: GoogleFonts.montserrat(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await _storageService.deleteDestination(widget.destination.id!);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Destino eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          final state = context.findAncestorStateOfType<_DestinationsScreenState>();
          state?._loadDestinations();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar destino: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? const Color(0xFF3D1F6E) : Colors.grey[200]!,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF3D1F6E).withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.canModify ? () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DestinationEditScreen(destination: widget.destination),
                  ),
                );
                if (result == true && context.mounted) {
                  final state = context.findAncestorStateOfType<_DestinationsScreenState>();
                  state?._loadDestinations();
                }
              } : null,
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
              child: const Icon(Icons.place_rounded, color: Color(0xFF3D1F6E), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.destination.ciudad}, ${widget.destination.pais}',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F1F1F),
                    ),
                  ),
                  if (widget.destination.descripcion != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.destination.descripcion!,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (widget.destination.climaPromedio != null || widget.destination.temporadaAlta != null || widget.destination.precioBase != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (widget.destination.climaPromedio != null)
                          _buildChip(Icons.thermostat_rounded, widget.destination.climaPromedio!),
                        if (widget.destination.temporadaAlta != null)
                          _buildChip(Icons.calendar_today_rounded, widget.destination.temporadaAlta!),
                        if (widget.destination.precioBase != null)
                          _buildPriceChip(widget.destination.precioBase!),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (widget.canModify)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => _deleteDestination(context),
                tooltip: 'Eliminar destino',
              )
            else
              const SizedBox(width: 48), // Espacio para mantener alineación
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFfdb913).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFf7941e)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFf7941e),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPriceChip(double price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF3D1F6E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.payments_rounded, size: 14, color: Color(0xFF3D1F6E)),
          const SizedBox(width: 4),
          Text(
            NumberFormatter.formatCurrency(price),
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3D1F6E),
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationSummaryCard extends StatelessWidget {
  const _DestinationSummaryCard({
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
