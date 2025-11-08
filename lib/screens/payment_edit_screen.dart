import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../models/reservation.dart';
import '../models/quote.dart';
import '../services/storage_service.dart';
import '../services/audit_service.dart';
import '../models/audit_log.dart';
import '../utils/number_formatter.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/max_amount_formatter.dart';
import '../widgets/unsaved_changes_dialog.dart';

class PaymentEditScreen extends StatefulWidget {
  final Payment? payment;

  const PaymentEditScreen({super.key, this.payment});

  @override
  State<PaymentEditScreen> createState() => _PaymentEditScreenState();
}

class _PaymentEditScreenState extends State<PaymentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();

  // Tipo de pago: 'cotizacion' o 'reserva'
  String _tipoPago = 'reserva';
  
  List<Reservation> _reservations = [];
  List<Quote> _quotes = [];
  int? _selectedReservationId;
  int? _selectedQuoteId;
  double _saldoPendiente = 0.0;
  
  String _selectedMetodo = PaymentMethod.transferencia;
  DateTime _fechaPago = DateTime.now();
  
  String? _selectedBanco;
  late TextEditingController _numReferenciaController;
  late TextEditingController _montoController;
  
  List<String> _bancosDisponibles = [];
  String? _paisCliente;

  bool _isSaving = false;
  bool _isLoading = true;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _selectedReservationId = widget.payment?.idReserva;
    _selectedMetodo = widget.payment?.metodo ?? PaymentMethod.transferencia;
    _fechaPago = widget.payment?.fechaPago ?? DateTime.now();
    
    _selectedBanco = widget.payment?.bancoEmisor;
    _numReferenciaController = TextEditingController(text: widget.payment?.numReferencia ?? '');
    _montoController = TextEditingController(
      text: widget.payment?.monto != null ? widget.payment!.monto.toStringAsFixed(0) : '',
    );
    
    // Formatear el monto inicial con puntos de miles
    String initialMonto = '';
    if (widget.payment?.monto != null) {
      final formatter = NumberFormat('#,##0', 'es_CO');
      initialMonto = formatter.format(widget.payment!.monto.toInt());
    }
    _montoController = TextEditingController(text: initialMonto);
    
    // Agregar listeners
    _numReferenciaController.addListener(_markAsChanged);
    _montoController.addListener(_markAsChanged);
    
    _loadData();
  }
  
  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }
  
  List<String> _getBancosPorPais(String pais) {
    switch (pais.toLowerCase()) {
      case 'colombia':
        return [
          'Bancolombia',
          'Banco de Bogotá',
          'Davivienda',
          'BBVA Colombia',
          'Banco Popular',
          'Banco de Occidente',
          'Banco Caja Social',
          'Banco AV Villas',
          'Banco Agrario',
          'Banco Pichincha',
          'Scotiabank Colpatria',
          'Itaú',
          'Bancoomeva',
          'Banco Falabella',
          'Banco Finandina',
          'Nequi',
          'Daviplata',
          'Otro',
        ];
      case 'méxico':
      case 'mexico':
        return [
          'BBVA México',
          'Banamex',
          'Santander México',
          'Banorte',
          'HSBC México',
          'Scotiabank México',
          'Inbursa',
          'Banco Azteca',
          'Afirme',
          'BanBajío',
          'Otro',
        ];
      case 'argentina':
        return [
          'Banco Nación',
          'Banco Provincia',
          'Banco Galicia',
          'BBVA Argentina',
          'Santander Río',
          'Macro',
          'ICBC',
          'Supervielle',
          'Patagonia',
          'Otro',
        ];
      case 'chile':
        return [
          'Banco de Chile',
          'Banco Estado',
          'BCI',
          'Santander Chile',
          'Itaú Chile',
          'Scotiabank Chile',
          'BBVA Chile',
          'Banco Falabella',
          'Otro',
        ];
      case 'perú':
      case 'peru':
        return [
          'BCP',
          'BBVA Perú',
          'Interbank',
          'Scotiabank Perú',
          'Banco de la Nación',
          'Banco Pichincha',
          'Banco GNB',
          'Otro',
        ];
      case 'españa':
      case 'espana':
        return [
          'Santander',
          'BBVA',
          'CaixaBank',
          'Bankia',
          'Sabadell',
          'Bankinter',
          'ING',
          'Unicaja',
          'Otro',
        ];
      case 'estados unidos':
      case 'usa':
      case 'united states':
        return [
          'Bank of America',
          'Chase',
          'Wells Fargo',
          'Citibank',
          'US Bank',
          'PNC Bank',
          'Capital One',
          'TD Bank',
          'Otro',
        ];
      default:
        return [
          'Banco Internacional',
          'Transferencia Internacional',
          'Otro',
        ];
    }
  }

  Future<void> _loadData() async {
    try {
      final currentUser = await _storageService.getCurrentUser();
      if (currentUser != null) {
        // Cargar reservas con saldo pendiente
        final allReservations = await _storageService.getReservationsByEmployee(currentUser.idUsuario!);
        final reservationsWithBalance = <Reservation>[];
        
        // Si estamos editando un pago, incluir la reserva asociada aunque esté completamente pagada
        final editingReservationId = widget.payment?.idReserva;
        
        for (var reservation in allReservations) {
          final balance = await _storageService.getReservationBalance(reservation.id!);
          final remaining = balance['montoRestante'] as double;
          
          debugPrint('🔍 Reserva #${reservation.id}: Total=${reservation.totalPago}, Pagado=${balance['montoPagado']}, Restante=$remaining');
          
          // Incluir si tiene saldo pendiente O si es la reserva que estamos editando
          if (remaining > 0 || reservation.id == editingReservationId) {
            reservationsWithBalance.add(reservation);
          }
        }
        
        debugPrint('✅ Total reservas con saldo: ${reservationsWithBalance.length} de ${allReservations.length}');
        
        // Cargar cotizaciones (por ahora sin filtro de saldo, ya que no tienen pagos asociados)
        final quotes = await _storageService.getQuotesByEmployee(currentUser.idUsuario!);
        
        debugPrint('📋 Cotizaciones cargadas: ${quotes.length}');
        for (var quote in quotes) {
          debugPrint('   Cotización #${quote.id}: Precio=${quote.precioEstimado}');
        }
        
        // Obtener el país del cliente para cargar los bancos correspondientes
        if (_selectedReservationId != null && reservationsWithBalance.isNotEmpty) {
          final reservation = reservationsWithBalance.firstWhere((r) => r.id == _selectedReservationId);
          final clients = await _storageService.getClients();
          final client = clients.where((c) => c.id == reservation.idCliente).firstOrNull;
          if (client != null && client.pais != null) {
            _paisCliente = client.pais;
            _bancosDisponibles = _getBancosPorPais(client.pais!);
          } else {
            _paisCliente = 'Colombia';
            _bancosDisponibles = _getBancosPorPais('Colombia');
          }
        } else {
          // Si no hay reserva seleccionada, usar Colombia por defecto
          _paisCliente = 'Colombia';
          _bancosDisponibles = _getBancosPorPais('Colombia');
        }
        
        if (mounted) {
          setState(() {
            _reservations = reservationsWithBalance;
            _quotes = quotes;
            _isLoading = false;
            
            // Si estamos editando, preseleccionar la reserva después de cargar
            if (widget.payment != null && editingReservationId != null) {
              _selectedReservationId = editingReservationId;
              _updateSaldoPendiente();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  Future<void> _updateSaldoPendiente() async {
    if (_tipoPago == 'reserva' && _selectedReservationId != null) {
      // Para reservas, calcular el saldo pendiente
      final reservation = _reservations.firstWhere((r) => r.id == _selectedReservationId);
      final payments = await _storageService.getPaymentsByReservation(_selectedReservationId!);
      final totalPagado = payments.fold<double>(0, (sum, payment) => sum + payment.monto);
      
      // Actualizar bancos según el país del cliente
      final clients = await _storageService.getClients();
      final client = clients.where((c) => c.id == reservation.idCliente).firstOrNull;
      
      setState(() {
        _saldoPendiente = reservation.totalPago - totalPagado;
        if (client != null && client.pais != null) {
          _paisCliente = client.pais;
          _bancosDisponibles = _getBancosPorPais(client.pais);
        }
      });
    } else if (_tipoPago == 'cotizacion' && _selectedQuoteId != null) {
      // Para cotizaciones, calcular el saldo pendiente restando pagos realizados
      final quote = _quotes.firstWhere((q) => q.id == _selectedQuoteId);
      final payments = await _storageService.getPaymentsByQuote(_selectedQuoteId!);
      final totalPagado = payments.fold<double>(0, (sum, payment) => sum + payment.monto);
      
      setState(() {
        _saldoPendiente = quote.precioEstimado - totalPagado;
      });
    }
  }

  @override
  void dispose() {
    _numReferenciaController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaPago,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF3D1F6E)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fechaPago = picked;
      });
      _markAsChanged();
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_tipoPago == 'reserva' && _selectedReservationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una reserva'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    if (_tipoPago == 'cotizacion' && _selectedQuoteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una cotización'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '¿Confirmar registro?',
                style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ IMPORTANTE',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.orange[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Una vez registrado, este pago NO podrá ser editado ni eliminado.',
              style: GoogleFonts.montserrat(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen del pago:',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Monto: ${NumberFormatter.formatCurrency(CurrencyInputFormatter.parseFormattedValue(_montoController.text) ?? 0)}',
                    style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Método: $_selectedMetodo',
                    style: GoogleFonts.montserrat(fontSize: 13),
                  ),
                  Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaPago)}',
                    style: GoogleFonts.montserrat(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Está seguro de registrar este pago?',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.montserrat(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3D1F6E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Sí, registrar',
              style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      // Generar número de factura automáticamente si está vacío
      String numFactura = _numReferenciaController.text.trim();
      if (numFactura.isEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        numFactura = 'FAC-$timestamp';
      }

      // Parsear el monto formateado (ej: "5.000.000" → 5000000)
      final monto = CurrencyInputFormatter.parseFormattedValue(_montoController.text);
      if (monto == null) {
        throw Exception('Monto inválido');
      }

      final payment = Payment(
        id: widget.payment?.id,
        idReserva: _tipoPago == 'reserva' ? _selectedReservationId : null,
        idCotizacion: _tipoPago == 'cotizacion' ? _selectedQuoteId : null,
        metodo: _selectedMetodo,
        monto: double.parse(_montoController.text.replaceAll('.', '').replaceAll(',', '')),
        fechaPago: _fechaPago,
        bancoEmisor: _selectedBanco,
        numReferencia: _numReferenciaController.text.trim().isEmpty ? 'AUTO' : _numReferenciaController.text.trim(),
      );

      debugPrint('💰 Guardando pago:');
      debugPrint('   Tipo: $_tipoPago');
      debugPrint('   idReserva: ${payment.idReserva}');
      debugPrint('   idCotizacion: ${payment.idCotizacion}');
      debugPrint('   Monto: ${payment.monto}');

      await _storageService.savePayment(payment);
      
      // Registrar en auditoría
      final currentUser = await _storageService.getCurrentUser();
      if (currentUser != null) {
        await AuditService.logAction(
          usuario: currentUser,
          accion: AuditAction.registrarPago,
          entidad: 'Pago',
          idEntidad: payment.id,
          nombreEntidad: 'Pago #${payment.numReferencia}',
          detalles: {
            'monto': payment.monto.toString(),
            'metodo': payment.metodo,
          },
        );
      }

      setState(() => _hasUnsavedChanges = false);

      String successMessage = 'Pago guardado exitosamente';
      
      // Verificar saldo y actualizar estado según el tipo
      if (_tipoPago == 'reserva') {
        final balance = await _storageService.getReservationBalance(_selectedReservationId!);
        final remaining = balance['montoRestante'] as double;

        // Si el pago está completo, actualizar el estado de la reserva a "confirmada"
        if (remaining <= 0) {
          try {
            final reservations = await _storageService.getAllReservations();
            final reservation = reservations.firstWhere((r) => r.id == _selectedReservationId);
            
            final updatedReservation = reservation.copyWith(
              estado: ReservationStatus.confirmada,
            );
            
            await _storageService.saveReservation(updatedReservation);
            debugPrint('✅ Reserva #${_selectedReservationId} marcada como confirmada (pago completo)');
            successMessage = 'Pago guardado. ¡Reserva completamente pagada!';
          } catch (e) {
            debugPrint('⚠️ Error actualizando estado de reserva: $e');
          }
        }
      } else if (_tipoPago == 'cotizacion') {
        // Actualizar estado de cotización según pagos
        try {
          final currentUser = await _storageService.getCurrentUser();
          final quotes = await _storageService.getQuotesByEmployee(currentUser!.idUsuario!);
          final quote = quotes.firstWhere((q) => q.id == _selectedQuoteId);
          
          // Calcular total pagado
          final allPayments = await _storageService.getPaymentsByEmployee(currentUser.idUsuario!);
          final quotePayments = allPayments.where((p) => p.idCotizacion == _selectedQuoteId).toList();
          final totalPaid = quotePayments.fold<double>(0.0, (sum, p) => sum + p.monto);
          
          // Determinar nuevo estado
          QuoteStatus newStatus;
          if (totalPaid >= quote.precioEstimado) {
            newStatus = QuoteStatus.aceptada; // Completamente pagada
            successMessage = 'Pago guardado. ¡Cotización completamente pagada!';
          } else if (totalPaid > 0) {
            newStatus = QuoteStatus.pendiente; // Pago parcial (mantenemos pendiente pero con pagos)
          } else {
            newStatus = quote.estado; // Sin cambios
          }
          
          if (newStatus != quote.estado) {
            final updatedQuote = quote.copyWith(estado: newStatus);
            await _storageService.saveQuote(updatedQuote);
            debugPrint('✅ Cotización #${_selectedQuoteId} actualizada a estado: $newStatus');
          }
        } catch (e) {
          debugPrint('⚠️ Error actualizando estado de cotización: $e');
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
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
    return UnsavedChangesHandler(
      hasUnsavedChanges: _hasUnsavedChanges,
      onSave: _savePayment,
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3D1F6E)),
          onPressed: () async {
            if (_hasUnsavedChanges) {
              final result = await showUnsavedChangesDialog(
                context,
                onSave: _savePayment,
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
              'Registrar Pago',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 18, color: const Color(0xFF1F1F1F)),
            ),
            Text(
              'Gestión de pagos de clientes',
              style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF6F6F6F)),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildSection(
                    title: 'Tipo de Pago',
                    children: [
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'reserva',
                            label: Text('Reserva'),
                            icon: Icon(Icons.event_available, size: 18),
                          ),
                          ButtonSegment(
                            value: 'cotizacion',
                            label: Text('Cotización'),
                            icon: Icon(Icons.request_quote, size: 18),
                          ),
                        ],
                        selected: {_tipoPago},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _tipoPago = newSelection.first;
                            _selectedReservationId = null;
                            _selectedQuoteId = null;
                            _saldoPendiente = 0.0;
                          });
                          _markAsChanged();
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                            if (states.contains(MaterialState.selected)) {
                              return const Color(0xFF3D1F6E);
                            }
                            return Colors.white;
                          }),
                          foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.white;
                            }
                            return const Color(0xFF3D1F6E);
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: _tipoPago == 'reserva' ? 'Reserva Asociada' : 'Cotización Asociada',
                    children: [
                      if (_tipoPago == 'reserva') ...[
                        DropdownButtonFormField<int>(
                          value: _selectedReservationId,
                          decoration: InputDecoration(
                            labelText: 'Seleccionar reserva *',
                            labelStyle: GoogleFonts.montserrat(fontSize: 13),
                            hintText: _reservations.isEmpty ? 'No hay reservas con saldo pendiente' : 'Selecciona una reserva',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF3D1F6E), width: 1.5),
                            ),
                          ),
                          items: _reservations.map((reservation) {
                            return DropdownMenuItem<int>(
                              value: reservation.id,
                              child: Text(
                                'Reserva #${reservation.id} - ${NumberFormatter.formatCurrencyWithDecimals(reservation.totalPago)}',
                                style: GoogleFonts.montserrat(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) async {
                            setState(() => _selectedReservationId = value);
                            _markAsChanged();
                            await _updateSaldoPendiente();
                          },
                          validator: (value) => value == null ? 'Selecciona una reserva' : null,
                        ),
                      ] else ...[
                        DropdownButtonFormField<int>(
                          value: _selectedQuoteId,
                          decoration: InputDecoration(
                            labelText: 'Seleccionar cotización *',
                            labelStyle: GoogleFonts.montserrat(fontSize: 13),
                            hintText: _quotes.isEmpty ? 'No hay cotizaciones disponibles' : 'Selecciona una cotización',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF3D1F6E), width: 1.5),
                            ),
                          ),
                          items: _quotes.map((quote) {
                            return DropdownMenuItem<int>(
                              value: quote.id,
                              child: Text(
                                'Cotización #${quote.id} - ${NumberFormatter.formatCurrencyWithDecimals(quote.precioEstimado)}',
                                style: GoogleFonts.montserrat(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) async {
                            debugPrint('✅ Cotización seleccionada: #$value');
                            setState(() => _selectedQuoteId = value);
                            _markAsChanged();
                            await _updateSaldoPendiente();
                          },
                          validator: (value) => value == null ? 'Selecciona una cotización' : null,
                        ),
                      ],
                      if (_saldoPendiente > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Saldo pendiente',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      NumberFormatter.formatCurrency(_saldoPendiente),
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Información del Pago',
                    children: [
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Fecha de pago *',
                            labelStyle: GoogleFonts.montserrat(fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy').format(_fechaPago),
                                style: GoogleFonts.montserrat(fontSize: 14),
                              ),
                              const Icon(Icons.calendar_today, size: 18, color: Color(0xFF3D1F6E)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedMetodo,
                        decoration: InputDecoration(
                          labelText: 'Método de pago *',
                          labelStyle: GoogleFonts.montserrat(fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: PaymentMethod.all.map((method) {
                          return DropdownMenuItem(
                            value: method,
                            child: Text(method, style: GoogleFonts.montserrat(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMetodo = value!;
                            // Limpiar banco emisor si se selecciona efectivo
                            if (value == PaymentMethod.efectivo) {
                              _selectedBanco = null;
                            }
                          });
                          _markAsChanged();
                        },
                        validator: (value) => value == null || value.isEmpty ? 'Selecciona un método de pago' : null,
                      ),
                      if (_selectedMetodo != PaymentMethod.efectivo) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedBanco,
                          decoration: InputDecoration(
                            labelText: 'Banco emisor *',
                            labelStyle: GoogleFonts.montserrat(fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.account_balance, size: 20),
                          ),
                          items: _bancosDisponibles.map((banco) {
                            return DropdownMenuItem<String>(
                              value: banco,
                              child: Text(
                                banco,
                                style: GoogleFonts.montserrat(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedBanco = value);
                            _markAsChanged();
                          },
                          validator: (value) => value == null ? 'Selecciona el banco emisor' : null,
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _numReferenciaController,
                        decoration: InputDecoration(
                          labelText: 'Número de factura (opcional)',
                          labelStyle: GoogleFonts.montserrat(fontSize: 13),
                          hintText: 'Se generará automáticamente si se deja vacío',
                          hintStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[400]),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.receipt_long, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _montoController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CurrencyInputFormatter(),
                          if (_saldoPendiente > 0) MaxAmountFormatter(_saldoPendiente),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Monto *',
                          labelStyle: GoogleFonts.montserrat(fontSize: 13),
                          hintText: '0',
                          helperText: _saldoPendiente > 0 
                              ? 'Máximo: ${NumberFormatter.formatCurrency(_saldoPendiente)}'
                              : null,
                          helperStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.blue[700]),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 16, right: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '\$',
                                  style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3D1F6E)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Campo obligatorio';
                          final parsedValue = CurrencyInputFormatter.parseFormattedValue(value);
                          if (parsedValue == null) return 'Debe ser un número válido';
                          if (_saldoPendiente > 0 && parsedValue > _saldoPendiente) {
                            return 'El monto no puede exceder el saldo pendiente';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _savePayment,
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
                        'Guardar',
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
