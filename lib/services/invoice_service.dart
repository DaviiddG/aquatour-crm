import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import '../models/payment.dart';
import '../models/reservation.dart';
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
    required Client? client,
    String? employeeName,
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
              pw.SizedBox(height: 30),

              // Información de la factura
              _buildInvoiceInfo(payment),
              pw.SizedBox(height: 20),

              // Información del cliente
              if (client != null) ...[
                _buildClientInfo(client),
                pw.SizedBox(height: 20),
              ],

              // Información de la reserva
              if (reservation != null) ...[
                _buildReservationInfo(reservation),
                pw.SizedBox(height: 20),
              ],

              // Detalles del pago
              _buildPaymentDetails(payment, employeeName),
              pw.SizedBox(height: 30),

              // Total
              _buildTotal(payment),
              pw.SizedBox(height: 40),

              // Pie de página
              pw.Spacer(),
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
            fontSize: 32,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#3D1F6E'),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Agencia de Viajes y Turismo',
          style: pw.TextStyle(
            fontSize: 14,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'NIT: 900.123.456-7',
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Divider(thickness: 2, color: PdfColor.fromHex('#3D1F6E')),
      ],
    );
  }

  /// Información de la factura
  static pw.Widget _buildInvoiceInfo(Payment payment) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F5F5'),
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
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#3D1F6E'),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'No. ${payment.id?.toString().padLeft(6, '0') ?? '000000'}',
                style: pw.TextStyle(
                  fontSize: 14,
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
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _dateFormat.format(payment.fechaPago),
                style: pw.TextStyle(
                  fontSize: 14,
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
      padding: const pw.EdgeInsets.all(16),
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
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#3D1F6E'),
            ),
          ),
          pw.SizedBox(height: 12),
          _buildInfoRow('Nombre:', client.nombreCompleto),
          pw.SizedBox(height: 6),
          if (client.email.isNotEmpty)
            _buildInfoRow('Email:', client.email),
          pw.SizedBox(height: 6),
          if (client.telefono.isNotEmpty)
            _buildInfoRow('Teléfono:', client.telefono),
        ],
      ),
    );
  }

  /// Información de la reserva
  static pw.Widget _buildReservationInfo(Reservation reservation) {
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
            'INFORMACIÓN DE LA RESERVA',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#3D1F6E'),
            ),
          ),
          pw.SizedBox(height: 12),
          _buildInfoRow('Reserva No.:', '#${reservation.id}'),
          pw.SizedBox(height: 6),
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
      padding: const pw.EdgeInsets.all(16),
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
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#3D1F6E'),
            ),
          ),
          pw.SizedBox(height: 12),
          _buildInfoRow('Método de Pago:', payment.metodo),
          pw.SizedBox(height: 6),
          if (payment.bancoEmisor != null && payment.bancoEmisor!.isNotEmpty)
            _buildInfoRow('Banco Emisor:', payment.bancoEmisor!),
          if (payment.bancoEmisor != null && payment.bancoEmisor!.isNotEmpty)
            pw.SizedBox(height: 6),
          _buildInfoRow('No. Referencia:', payment.numReferencia),
          pw.SizedBox(height: 6),
          if (employeeName != null)
            _buildInfoRow('Atendido por:', employeeName),
        ],
      ),
    );
  }

  /// Total del pago
  static pw.Widget _buildTotal(Payment payment) {
    return pw.Container(
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
        pw.SizedBox(height: 8),
        pw.Text(
          'www.aquatour.com | contacto@aquatour.com | Tel: +57 300 123 4567',
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Este documento es una factura válida de pago',
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey500,
          ),
          textAlign: pw.TextAlign.center,
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
