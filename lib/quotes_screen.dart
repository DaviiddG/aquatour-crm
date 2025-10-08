import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:aquatour/widgets/module_scaffold.dart';
import 'package:aquatour/models/quote.dart';
import 'package:aquatour/models/user.dart';
import 'package:aquatour/services/storage_service.dart';
import 'package:aquatour/screens/quote_edit_screen.dart';
import 'package:aquatour/utils/permissions_helper.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final StorageService _storageService = StorageService();
  List<Quote> _quotes = [];
  User? _currentUser;
  bool _isLoading = true;
  bool _canCreate = false;
  bool _canModify = false;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = await _storageService.getCurrentUser();
      if (currentUser != null) {
        _currentUser = currentUser;
        _canCreate = PermissionsHelper.canCreateQuotes(currentUser.rol);
        _canModify = PermissionsHelper.canModify(currentUser.rol);
        
        // Administradores y Superadministradores ven todas las cotizaciones
        // Empleados solo ven sus propias cotizaciones
        final quotes = currentUser.rol == UserRole.empleado
            ? await _storageService.getQuotesByEmployee(currentUser.idUsuario!)
            : await _storageService.getQuotes();
        
        if (mounted) {
          setState(() {
            _quotes = quotes;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando cotizaciones: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openQuoteForm({Quote? quote}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuoteEditScreen(quote: quote),
      ),
    );
    if (result == true) {
      _loadQuotes();
    }
  }

  Future<void> _deleteQuote(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación', style: GoogleFonts.montserrat()),
        content: Text('¿Estás seguro de eliminar esta cotización?', style: GoogleFonts.montserrat()),
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
      final success = await _storageService.deleteQuote(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Cotización eliminada' : 'Error eliminando cotización'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _loadQuotes();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      title: 'Cotizaciones',
      subtitle: 'Diseña propuestas comerciales y haz seguimiento a su evolución',
      icon: Icons.request_quote_rounded,
      floatingActionButton: _canCreate ? FloatingActionButton.extended(
        onPressed: () => _openQuoteForm(),
        backgroundColor: const Color(0xFFf7941e),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Nueva cotización', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600)),
      ) : null,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quotes.isEmpty
              ? _buildEmptyState()
              : _buildQuotesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.request_quote_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay cotizaciones',
            style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera cotización usando el botón naranja',
            style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _quotes.length,
      itemBuilder: (context, index) {
        final quote = _quotes[index];
        return _QuoteCard(
          quote: quote,
          canModify: _canModify,
          onTap: () => _openQuoteForm(quote: quote),
          onDelete: () => _deleteQuote(quote.id!),
          getStatusColor: _getStatusColor,
        );
      },
    );
  }

  Color _getStatusColor(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.aceptada:
        return Colors.green;
      case QuoteStatus.rechazada:
        return Colors.red;
      case QuoteStatus.vencida:
        return Colors.grey;
      case QuoteStatus.pendiente:
        return Colors.orange;
    }
  }
}

class _QuoteCard extends StatefulWidget {
  const _QuoteCard({
    required this.quote,
    required this.canModify,
    required this.onTap,
    required this.onDelete,
    required this.getStatusColor,
  });

  final Quote quote;
  final bool canModify;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Color Function(QuoteStatus) getStatusColor;

  @override
  State<_QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<_QuoteCard> {
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
            onTap: widget.canModify ? widget.onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.getStatusColor(widget.quote.estado).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.request_quote, color: widget.getStatusColor(widget.quote.estado), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cotización #${widget.quote.id}',
                          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('dd/MM/yyyy').format(widget.quote.fechaInicioViaje)} - ${DateFormat('dd/MM/yyyy').format(widget.quote.fechaFinViaje)} • \$${widget.quote.precioEstimado.toStringAsFixed(2)}',
                          style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.getStatusColor(widget.quote.estado).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.quote.estado.displayName,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.getStatusColor(widget.quote.estado),
                      ),
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

class _QuotesSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C39A6), Color(0xFF2C53A4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C53A4).withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estamos preparando un módulo inspirado en CRMs de alto desempeño',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Gestiona todo el ciclo de una propuesta: desde la solicitud inicial hasta la reserva confirmada. '
                    'Esta vista mostrará KPIs como tasa de conversión, ticket promedio y tiempo de respuesta.',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

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
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF3D1F6E).withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xFF3D1F6E)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                height: 1.5,
                color: const Color(0xFF5C5C5C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
