import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import '../models/payment.dart';
import '../models/reservation.dart';
import '../models/quote.dart';
import '../models/client.dart';

class InvoiceService {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  /// Generar factura PDF para un pago
  static Future<Uint8List> generateInvoice({
    required Payment payment,
    required Reservation? reservation,
    required Quote? quote,
    required Client? client,
    String? employeeName,
    String? packageName,
    String? destinationName,
    double? totalReserva,
    double? totalPagado,
    double? saldoPendiente,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              _buildHeader(),
              pw.SizedBox(height: 12),

              // Información de la factura
              _buildInvoiceInfo(payment),
              pw.SizedBox(height: 10),

              // Información del cliente
              if (client != null) ...[
                _buildClientInfo(client),
                pw.SizedBox(height: 10),
              ],

              // Información de la reserva o cotización
              if (reservation != null) ...[
                _buildReservationInfo(
                  reservation,
                  packageName: packageName,
                  destinationName: destinationName,
                ),
                pw.SizedBox(height: 10),
              ] else if (quote != null) ...[
                _buildQuoteInfo(
                  quote,
                  packageName: packageName,
                  destinationName: destinationName,
                ),
                pw.SizedBox(height: 10),
              ],

              // Detalles del pago
              _buildPaymentDetails(payment, employeeName),
              pw.SizedBox(height: 12),

              // Total
              _buildTotal(
                payment,
                totalReserva: totalReserva,
                totalPagado: totalPagado,
                saldoPendiente: saldoPendiente,
              ),
              pw.SizedBox(height: 10),

              // Pie de página
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Encabezado de la factura
  static pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'AQUATOUR',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#3D1F6E'),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Agencia de Viajes y Turismo',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 1),
        pw.Text(
          'NIT: 900.123.456-7',
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColor.fromHex('#3D1F6E'), thickness: 1.5),
      ],
    );
  }

  /// Información de la factura
  static pw.Widget _buildInvoiceInfo(Payment payment) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F3F7'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'FACTURA DE PAGO',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#3D1F6E'),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'No. ${payment.numReferencia}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Fecha de Emisión',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                _dateFormat.format(payment.fechaPago),
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Información del cliente
  static pw.Widget _buildClientInfo(Client client) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMACIÓN DEL CLIENTE',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#3D1F6E'),
            ),
          ),
          pw.SizedBox(height: 6),
          _buildInfoRow('Nombre:', client.nombreCompleto),
          pw.SizedBox(height: 3),
          if (client.email.isNotEmpty)
            _buildInfoRow('Email:', client.email),
          pw.SizedBox(height: 3),
          if (client.telefono.isNotEmpty)
            _buildInfoRow('Teléfono:', client.telefono),
        ],
      ),
    );
  }

  /// Información de la cotización
  static pw.Widget _buildQuoteInfo(Quote quote, {String? packageName, String? destinationName}) {
    // Calcular duración del viaje
    final duracion = quote.fechaFinViaje.difference(quote.fechaInicioViaje).inDays;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMACIÓN DEL VIAJE',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#3D1F6E'),
            ),
          ),
          pw.SizedBox(height: 8),
          _buildInfoRow('Cotización No.:', '#${quote.id}'),
          pw.SizedBox(height: 4),
          
          // Mostrar paquete o destino
          if (packageName != null && packageName.isNotEmpty) ...[
            _buildInfoRow('Paquete Turístico:', packageName),
            pw.SizedBox(height: 4),
          ] else if (destinationName != null && destinationName.isNotEmpty) ...[
            _buildInfoRow('Destino:', destinationName),
            pw.SizedBox(height: 4),
          ],
          
          _buildInfoRow(
            'Fecha de Inicio:',
            _dateFormat.format(quote.fechaInicioViaje),
          ),
          pw.SizedBox(height: 4),
          _buildInfoRow(
            'Fecha de Fin:',
            _dateFormat.format(quote.fechaFinViaje),
          ),
          pw.SizedBox(height: 4),
          _buildInfoRow(
            'Duración:',
            '$duracion ${duracion == 1 ? "día" : "días"}',
          ),
          pw.SizedBox(height: 4),
          _buildInfoRow(
            'Cantidad de Personas:',
            '${1 + quote.acompanantes.length} ${(1 + quote.acompanantes.length) == 1 ? "persona" : "personas"}',
          ),
          pw.SizedBox(height: 4),
          _buildInfoRow(
            'Total Cotización:',
            _currencyFormat.format(quote.precioEstimado),
          ),
          
          // Acompañantes (versión compacta)
          if (quote.acompanantes.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 3),
            pw.Text(
              'ACOMPAÑANTES (${quote.acompanantes.length})',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#3D1F6E'),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              quote.acompanantes.map((a) => '${a.nombres} ${a.apellidos}').join(', '),
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Información de la reserva
  static pw.Widget _buildReservationInfo(Reservation reservation, {String? packageName, String? destinationName}) {
    // Calcular duración del viaje
    final duracion = reservation.fechaFinViaje.difference(reservation.fechaInicioViaje).inDays;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMACIÓN DEL VIAJE',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#3D1F6E'),
            ),
          ),
          pw.SizedBox(height: 12),
          _buildInfoRow('Reserva No.:', '#${reservation.id}'),
          pw.SizedBox(height: 6),
          
          // Mostrar paquete o destino
          if (packageName != null && packageName.isNotEmpty) ...[
            _buildInfoRow('Paquete Turístico:', packageName),
            pw.SizedBox(height: 6),
          ] else if (destinationName != null && destinationName.isNotEmpty) ...[
            _buildInfoRow('Destino:', destinationName),
            pw.SizedBox(height: 6),
          ] else ...[
            _buildInfoRow('Tipo de Viaje:', 'Viaje personalizado'),
            pw.SizedBox(height: 6),
          ],
          
          _buildInfoRow(
            'Fecha de Inicio:',
            _dateFormat.format(reservation.fechaInicioViaje),
          ),
          pw.SizedBox(height: 6),
          _buildInfoRow(
            'Fecha de Fin:',
            _dateFormat.format(reservation.fechaFinViaje),
          ),
          pw.SizedBox(height: 6),
          _buildInfoRow(
            'Duración:',
            '$duracion ${duracion == 1 ? "día" : "días"}',
          ),
          pw.SizedBox(height: 6),
          _buildInfoRow(
            'Cantidad de Personas:',
            '${reservation.cantidadPersonas} ${reservation.cantidadPersonas == 1 ? "persona" : "personas"}',
          ),
          pw.SizedBox(height: 6),
          _buildInfoRow(
            'Total Reserva:',
            _currencyFormat.format(reservation.totalPago),
          ),
        ],
      ),
    );
  }

  /// Detalles del pago
  static pw.Widget _buildPaymentDetails(Payment payment, String? employeeName) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F9F9F9'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DETALLES DEL PAGO',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#3D1F6E'),
            ),
          ),
          pw.SizedBox(height: 6),
          _buildInfoRow('Método de Pago:', payment.metodo),
          pw.SizedBox(height: 3),
          if (payment.bancoEmisor != null && payment.bancoEmisor!.isNotEmpty)
            _buildInfoRow('Banco Emisor:', payment.bancoEmisor!),
          if (payment.bancoEmisor != null && payment.bancoEmisor!.isNotEmpty)
            pw.SizedBox(height: 3),
          _buildInfoRow('No. Referencia:', payment.numReferencia),
          pw.SizedBox(height: 3),
          if (employeeName != null)
            _buildInfoRow('Atendido por:', employeeName),
        ],
      ),
    );
  }

  /// Total del pago
  static pw.Widget _buildTotal(
    Payment payment, {
    double? totalReserva,
    double? totalPagado,
    double? saldoPendiente,
  }) {
    return pw.Column(
      children: [
        // Monto de este pago
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#3D1F6E'),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'MONTO PAGADO',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                _currencyFormat.format(payment.monto),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ),
        
        // Desglose de pagos si está disponible
        if (totalReserva != null && totalPagado != null && saldoPendiente != null) ...[
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Reserva:',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      _currencyFormat.format(totalReserva),
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Pagado:',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      _currencyFormat.format(totalPagado),
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Saldo Pendiente:',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      _currencyFormat.format(saldoPendiente),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: saldoPendiente > 0 ? PdfColors.red : PdfColors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Pie de página
  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 12),
        pw.Text(
          'Gracias por confiar en Aquatour',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#3D1F6E'),
          ),
        ),
      ],
    );
  }

  /// Fila de información
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Descargar PDF en el navegador
  static void downloadPDF(Uint8List pdfBytes, String fileName) {
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  /// Generar nombre de archivo para la factura
  static String generateFileName(Payment payment) {
    final date = DateFormat('yyyyMMdd').format(payment.fechaPago);
    final invoiceNumber = payment.id?.toString().padLeft(6, '0') ?? '000000';
    return 'Factura_${invoiceNumber}_$date.pdf';
  }
}
