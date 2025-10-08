import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../widgets/module_scaffold.dart';
import 'payment_edit_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final StorageService _storageService = StorageService();
  List<Payment> _payments = [];
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = await _storageService.getCurrentUser();
      if (currentUser != null) {
        _currentUser = currentUser;
        final payments = currentUser.rol == UserRole.empleado
            ? await _storageService.getPaymentsByEmployee(currentUser.idUsuario!)
            : await _storageService.getAllPayments();
        if (mounted) {
          setState(() {
            _payments = payments;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando pagos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openPaymentForm({Payment? payment}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentEditScreen(payment: payment),
      ),
    );
    if (result == true) {
      _loadPayments();
    }
  }

  Future<void> _deletePayment(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación', style: GoogleFonts.montserrat()),
        content: Text('¿Estás seguro de eliminar este pago?', style: GoogleFonts.montserrat()),
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
      final success = await _storageService.deletePayment(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Pago eliminado' : 'Error eliminando pago'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _loadPayments();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCreatePayment = _currentUser?.rol == UserRole.empleado;
    
    return ModuleScaffold(
      title: _currentUser?.rol == UserRole.empleado ? 'Mis Pagos' : 'Pagos del Equipo',
      subtitle: _currentUser?.rol == UserRole.empleado 
          ? 'Registra y gestiona los pagos de tus clientes'
          : 'Supervisa todos los pagos registrados',
      icon: Icons.payment_rounded,
      floatingActionButton: canCreatePayment
          ? FloatingActionButton.extended(
              onPressed: () => _openPaymentForm(),
              backgroundColor: const Color(0xFFf7941e),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Registrar pago', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? _buildEmptyState()
              : _buildPaymentsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay pagos registrados',
            style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Registra tu primer pago usando el botón naranja',
            style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList() {
    // Agrupar pagos por reserva
    final Map<int, List<Payment>> paymentsByReservation = {};
    for (final payment in _payments) {
      if (!paymentsByReservation.containsKey(payment.idReserva)) {
        paymentsByReservation[payment.idReserva] = [];
      }
      paymentsByReservation[payment.idReserva]!.add(payment);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: paymentsByReservation.length,
      itemBuilder: (context, index) {
        final reservationId = paymentsByReservation.keys.elementAt(index);
        final payments = paymentsByReservation[reservationId]!;
        return _ReservationPaymentGroup(
          reservationId: reservationId,
          payments: payments,
          onPaymentTap: (payment) => _openPaymentForm(payment: payment),
          onPaymentDelete: (paymentId) => _deletePayment(paymentId),
          onRefresh: _loadPayments,
        );
      },
    );
  }
}

class _ReservationPaymentGroup extends StatefulWidget {
  const _ReservationPaymentGroup({
    required this.reservationId,
    required this.payments,
    required this.onPaymentTap,
    required this.onPaymentDelete,
    required this.onRefresh,
  });

  final int reservationId;
  final List<Payment> payments;
  final Function(Payment) onPaymentTap;
  final Function(int) onPaymentDelete;
  final VoidCallback onRefresh;

  @override
  State<_ReservationPaymentGroup> createState() => _ReservationPaymentGroupState();
}

class _ReservationPaymentGroupState extends State<_ReservationPaymentGroup> {
  final StorageService _storageService = StorageService();
  Map<String, dynamic>? _balance;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final balance = await _storageService.getReservationBalance(widget.reservationId);
    if (mounted) {
      setState(() => _balance = balance);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPaid = widget.payments.fold<double>(0.0, (sum, p) => sum + p.monto);
    final remaining = _balance?['montoRestante'] ?? 0.0;
    final totalReserva = _balance?['totalReserva'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: remaining > 0 ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    color: remaining > 0 ? Colors.orange : Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reserva #${widget.reservationId}',
                          style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.payments.length} pago(s) • Total: \$${totalReserva.toStringAsFixed(2)}',
                          style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Pagado: \$${totalPaid.toStringAsFixed(2)}',
                        style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green),
                      ),
                      if (remaining > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Restante: \$${remaining.toStringAsFixed(2)}',
                          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange),
                        ),
                      ] else ...[
                        const SizedBox(height: 2),
                        Text(
                          '¡Completo!',
                          style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            ...widget.payments.map((payment) => _PaymentCard(
              payment: payment,
              onTap: () => widget.onPaymentTap(payment),
              onDelete: () => widget.onPaymentDelete(payment.id!),
            )),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatefulWidget {
  const _PaymentCard({
    required this.payment,
    required this.onTap,
    required this.onDelete,
  });

  final Payment payment;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<_PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<_PaymentCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
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
                      child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF3D1F6E), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Factura #${widget.payment.numReferencia}',
                                style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.payment.metodo,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(widget.payment.fechaPago),
                            style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600]),
                          ),
                          if (widget.payment.bancoEmisor != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.payment.bancoEmisor!,
                              style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${widget.payment.monto.toStringAsFixed(2)}',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3D1F6E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reserva #${widget.payment.idReserva}',
                          style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: widget.onDelete,
                      tooltip: 'Eliminar pago',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
