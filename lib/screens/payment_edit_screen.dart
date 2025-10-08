import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../models/reservation.dart';
import '../services/storage_service.dart';
import '../utils/number_formatter.dart';

class PaymentEditScreen extends StatefulWidget {
  final Payment? payment;

  const PaymentEditScreen({super.key, this.payment});

  @override
  State<PaymentEditScreen> createState() => _PaymentEditScreenState();
}

class _PaymentEditScreenState extends State<PaymentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();

  List<Reservation> _reservations = [];
  int? _selectedReservationId;
  String _selectedMetodo = PaymentMethod.transferencia;
  DateTime _fechaPago = DateTime.now();
  
  late TextEditingController _bancoEmisorController;
  late TextEditingController _numReferenciaController;
  late TextEditingController _montoController;

  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedReservationId = widget.payment?.idReserva;
    _selectedMetodo = widget.payment?.metodo ?? PaymentMethod.transferencia;
    _fechaPago = widget.payment?.fechaPago ?? DateTime.now();
    
    _bancoEmisorController = TextEditingController(
      text: widget.payment?.bancoEmisor ?? '',
    );
    _numReferenciaController = TextEditingController(
      text: widget.payment?.numReferencia ?? '',
    );
    _montoController = TextEditingController(
      text: widget.payment?.monto.toString() ?? '',
    );
    
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    try {
      final currentUser = await _storageService.getCurrentUser();
      if (currentUser != null) {
        final reservations = await _storageService.getReservationsByEmployee(currentUser.idUsuario!);
        if (mounted) {
          setState(() {
            _reservations = reservations;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando reservas: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _bancoEmisorController.dispose();
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
      setState(() => _fechaPago = picked);
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedReservationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una reserva'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Generar número de factura automáticamente si está vacío
      String numFactura = _numReferenciaController.text.trim();
      if (numFactura.isEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        numFactura = 'FAC-$timestamp';
      }

      final payment = Payment(
        id: widget.payment?.id,
        fechaPago: DateTime(_fechaPago.year, _fechaPago.month, _fechaPago.day),
        metodo: _selectedMetodo,
        bancoEmisor: _bancoEmisorController.text.trim().isEmpty ? null : _bancoEmisorController.text.trim(),
        numReferencia: numFactura,
        monto: double.parse(_montoController.text),
        idReserva: _selectedReservationId!,
      );

      await _storageService.savePayment(payment);

      // Verificar si la reserva está completamente pagada
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
        } catch (e) {
          debugPrint('⚠️ Error actualizando estado de reserva: $e');
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(remaining <= 0 
                ? 'Pago guardado. ¡Reserva completamente pagada!' 
                : 'Pago guardado exitosamente'),
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
    final isEditing = widget.payment != null;

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
              isEditing ? 'Editar Pago' : 'Registrar Pago',
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
                    title: 'Reserva Asociada',
                    children: [
                      DropdownButtonFormField<int>(
                        value: _selectedReservationId,
                        decoration: InputDecoration(
                          labelText: 'Seleccionar reserva *',
                          labelStyle: GoogleFonts.montserrat(fontSize: 13),
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
                        onChanged: (value) => setState(() => _selectedReservationId = value),
                        validator: (value) => value == null ? 'Selecciona una reserva' : null,
                      ),
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
                        onChanged: (value) => setState(() => _selectedMetodo = value!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bancoEmisorController,
                        decoration: InputDecoration(
                          labelText: 'Banco emisor',
                          labelStyle: GoogleFonts.montserrat(fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.account_balance, size: 20),
                        ),
                      ),
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
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Monto *',
                          labelStyle: GoogleFonts.montserrat(fontSize: 13),
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
                          if (double.tryParse(value) == null) return 'Debe ser un número válido';
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
