import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../models/quote.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../screens/payment_edit_screen.dart';
import '../utils/number_formatter.dart';
import '../widgets/module_scaffold.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> with SingleTickerProviderStateMixin {
  final StorageService _storageService = StorageService();
  List<Payment> _payments = [];
  Map<int, List<Payment>> _paymentsByEmployee = {};
  User? _currentUser;
  bool _isLoading = true;
  Set<int> _expandedEmployees = {};
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPayments();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = await _storageService.getCurrentUser();
      debugPrint('🔍 Usuario actual: ${currentUser?.nombre} - Rol: ${currentUser?.rol}');
      
      if (currentUser != null) {
        _currentUser = currentUser;
        
        debugPrint('🔍 Cargando pagos para rol: ${currentUser.rol}');
        final payments = currentUser.rol == UserRole.empleado
            ? await _storageService.getPaymentsByEmployee(currentUser.idUsuario!)
            : await _storageService.getAllPayments();
        
        debugPrint('✅ Pagos cargados: ${payments.length}');
        debugPrint('📋 Detalle de pagos:');
        for (var payment in payments) {
          debugPrint('   Pago #${payment.id}: idReserva=${payment.idReserva}, idCotizacion=${payment.idCotizacion}, monto=${payment.monto}');
        }
        
        // Si es admin, agrupar por empleado
        if (currentUser.rol != UserRole.empleado && payments.isNotEmpty) {
          _paymentsByEmployee = {};
          for (var payment in payments) {
            if (payment.idEmpleado != null) {
              final employeeId = payment.idEmpleado!;
              if (!_paymentsByEmployee.containsKey(employeeId)) {
                _paymentsByEmployee[employeeId] = [];
              }
              _paymentsByEmployee[employeeId]!.add(payment);
            }
          }
        }
        
        if (mounted) {
          setState(() {
            _payments = payments;
            _isLoading = false;
          });
        }
      } else {
        print('❌ No hay usuario actual');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error cargando pagos: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando pagos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openPaymentForm() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PaymentEditScreen(),
      ),
    );
    if (result == true) {
      _loadPayments();
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
              label: Text(
                'Registrar pago',
                style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF3D1F6E),
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: const Color(0xFF3D1F6E),
                        labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                        tabs: const [
                          Tab(icon: Icon(Icons.event_available), text: 'Reservas'),
                          Tab(icon: Icon(Icons.request_quote), text: 'Cotizaciones'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildReservationPayments(),
                          _buildQuotePayments(),
                        ],
                      ),
                    ),
                  ],
                ),
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

  Widget _buildReservationPayments() {
    // Filtrar solo pagos de reservas
    final reservationPayments = _payments.where((p) => p.idReserva != null).toList();
    
    if (reservationPayments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No hay pagos de reservas',
              style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    return _buildPaymentsList(reservationPayments);
  }
  
  Widget _buildQuotePayments() {
    // Filtrar solo pagos de cotizaciones
    final quotePayments = _payments.where((p) => p.idCotizacion != null).toList();
    
    debugPrint('📊 Total pagos cargados: ${_payments.length}');
    debugPrint('📊 Pagos de cotizaciones: ${quotePayments.length}');
    for (var payment in _payments) {
      debugPrint('   Pago #${payment.id}: idReserva=${payment.idReserva}, idCotizacion=${payment.idCotizacion}');
    }
    
    if (quotePayments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.request_quote, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No hay pagos de cotizaciones',
              style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    // Agrupar pagos por cotización
    final Map<int, List<Payment>> paymentsByQuote = {};
    for (final payment in quotePayments) {
      if (payment.idCotizacion != null) {
        if (!paymentsByQuote.containsKey(payment.idCotizacion)) {
          paymentsByQuote[payment.idCotizacion!] = [];
        }
        paymentsByQuote[payment.idCotizacion!]!.add(payment);
      }
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: paymentsByQuote.entries.map((entry) => _QuotePaymentGroup(
        quoteId: entry.key,
        payments: entry.value,
        onRefresh: _loadPayments,
      )).toList(),
    );
  }

  Widget _buildPaymentsList(List<Payment> payments) {
    // Agrupar pagos por reserva
    final Map<int, List<Payment>> paymentsByReservation = {};
    
    for (final payment in payments) {
      if (payment.idReserva != null) {
        if (!paymentsByReservation.containsKey(payment.idReserva)) {
          paymentsByReservation[payment.idReserva!] = [];
        }
        paymentsByReservation[payment.idReserva!]!.add(payment);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: paymentsByReservation.entries.map((entry) => _ReservationPaymentGroup(
        reservationId: entry.key,
        payments: entry.value,
        onRefresh: _loadPayments,
      )).toList(),
    );
  }

  Widget _buildGroupedPaymentsList() {
    final sortedEmployeeIds = _paymentsByEmployee.keys.toList()
      ..sort((a, b) {
        final nameA = _paymentsByEmployee[a]?.first.empleadoNombreCompleto ?? '';
        final nameB = _paymentsByEmployee[b]?.first.empleadoNombreCompleto ?? '';
        return nameA.compareTo(nameB);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedEmployeeIds.length,
      itemBuilder: (context, index) {
        final employeeId = sortedEmployeeIds[index];
        final payments = _paymentsByEmployee[employeeId] ?? [];
        final isExpanded = _expandedEmployees.contains(employeeId);
        final employeeName = payments.isNotEmpty ? payments.first.empleadoNombreCompleto : 'Empleado #$employeeId';
        
        // Calcular total de pagos del empleado
        final totalPagos = payments.fold<double>(0.0, (sum, p) => sum + p.monto);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedEmployees.remove(employeeId);
                    } else {
                      _expandedEmployees.add(employeeId);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4C39A6).withValues(alpha: 0.1),
                        const Color(0xFF3D1F6E).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D1F6E).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF3D1F6E),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employeeName,
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F1F1F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${payments.length} ${payments.length == 1 ? 'pago' : 'pagos'} • ${NumberFormatter.formatCurrency(totalPagos)}',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: const Color(0xFF3D1F6E),
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded) ...[
                // Agrupar pagos por reserva dentro de cada empleado
                ...() {
                  final Map<int, List<Payment>> paymentsByReservation = {};
                  for (final payment in payments) {
                    if (payment.idReserva != null) {
                      if (!paymentsByReservation.containsKey(payment.idReserva)) {
                        paymentsByReservation[payment.idReserva!] = [];
                      }
                      paymentsByReservation[payment.idReserva!]!.add(payment);
                    }
                  }
                  return paymentsByReservation.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: _ReservationPaymentGroup(
                      reservationId: entry.key,
                      payments: entry.value,
                      onRefresh: _loadPayments,
                    ),
                  ));
                }(),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ReservationPaymentGroup extends StatefulWidget {
  const _ReservationPaymentGroup({
    required this.reservationId,
    required this.payments,
    required this.onRefresh,
  });

  final int reservationId;
  final List<Payment> payments;
  final VoidCallback onRefresh;

  @override
  State<_ReservationPaymentGroup> createState() => _ReservationPaymentGroupState();
}

class _ReservationPaymentGroupState extends State<_ReservationPaymentGroup> {
  final StorageService _storageService = StorageService();
  Map<String, dynamic>? _balance;
  bool _isExpanded = false; // Colapsado por defecto

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
                          '${widget.payments.length} pago(s) • Total: ${NumberFormatter.formatCurrencyWithDecimals(totalReserva)}',
                          style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Pagado: ${NumberFormatter.formatCurrencyWithDecimals(totalPaid)}',
                        style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green),
                      ),
                      if (remaining > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Restante: ${NumberFormatter.formatCurrencyWithDecimals(remaining)}',
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
            )),
        ],
      ),
    );
  }
}

class _QuotePaymentGroup extends StatefulWidget {
  const _QuotePaymentGroup({
    required this.quoteId,
    required this.payments,
    required this.onRefresh,
  });

  final int quoteId;
  final List<Payment> payments;
  final VoidCallback onRefresh;

  @override
  State<_QuotePaymentGroup> createState() => _QuotePaymentGroupState();
}

class _QuotePaymentGroupState extends State<_QuotePaymentGroup> {
  final StorageService _storageService = StorageService();
  Quote? _quote;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    try {
      final currentUser = await _storageService.getCurrentUser();
      if (currentUser != null) {
        final quotes = await _storageService.getQuotesByEmployee(currentUser.idUsuario!);
        final quote = quotes.firstWhere((q) => q.id == widget.quoteId);
        if (mounted) {
          setState(() => _quote = quote);
        }
      }
    } catch (e) {
      debugPrint('Error cargando cotización: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPaid = widget.payments.fold<double>(0.0, (sum, p) => sum + p.monto);
    final totalQuote = _quote?.precioEstimado ?? 0.0;
    final remaining = totalQuote - totalPaid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                color: remaining > 0 ? Colors.purple.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.request_quote_rounded,
                    color: remaining > 0 ? Colors.purple[700] : Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cotización #${widget.quoteId}',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: remaining > 0 ? Colors.purple[900] : Colors.green[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.payments.length} pago${widget.payments.length != 1 ? 's' : ''} • Total: ${NumberFormatter.formatCurrencyWithDecimals(totalQuote)}',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Pagado: ${NumberFormatter.formatCurrency(totalPaid)}',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                      if (remaining > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Restante: ${NumberFormatter.formatCurrency(remaining)}',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '¡Completo!',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.green[900],
                            ),
                          ),
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
            )),
        ],
      ),
    );
  }
}

class _QuotePaymentsSection extends StatelessWidget {
  const _QuotePaymentsSection({
    required this.payments,
  });

  final List<Payment> payments;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.request_quote_rounded,
                  color: Colors.purple[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pagos de Cotizaciones',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.purple[900],
                        ),
                      ),
                      Text(
                        '${payments.length} pago${payments.length != 1 ? 's' : ''}',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...payments.map((payment) => _QuotePaymentCard(payment: payment)),
        ],
      ),
    );
  }
}

class _QuotePaymentCard extends StatelessWidget {
  const _QuotePaymentCard({
    required this.payment,
  });

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_long_rounded, color: Colors.purple[700], size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Factura #${payment.numReferencia}',
                      style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        payment.metodo,
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
                  dateFormat.format(payment.fechaPago),
                  style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600]),
                ),
                if (payment.bancoEmisor != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    payment.bancoEmisor!,
                    style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
                if (payment.empleadoNombre != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Registrado por: ${payment.empleadoNombreCompleto}',
                        style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormatter.formatCurrencyWithDecimals(payment.monto),
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.purple[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cotización #${payment.idCotizacion}',
                style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
  });

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return MouseRegion(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            child: DecoratedBox(
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
                                'Factura #${payment.numReferencia}',
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
                                  payment.metodo,
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
                            dateFormat.format(payment.fechaPago),
                            style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600]),
                          ),
                          if (payment.bancoEmisor != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              payment.bancoEmisor!,
                              style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                          if (payment.empleadoNombre != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Registrado por: ${payment.empleadoNombreCompleto}',
                                  style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormatter.formatCurrencyWithDecimals(payment.monto),
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3D1F6E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reserva #${payment.idReserva}',
                          style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
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
