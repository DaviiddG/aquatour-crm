import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/storage_service.dart';

class PerformanceIndicatorsScreen extends StatefulWidget {
  const PerformanceIndicatorsScreen({super.key});

  @override
  State<PerformanceIndicatorsScreen> createState() => _PerformanceIndicatorsScreenState();
}

class _PerformanceIndicatorsScreenState extends State<PerformanceIndicatorsScreen> {
  final StorageService _storageService = StorageService();
  Map<String, dynamic> _metrics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  Future<void> _loadPerformanceData() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = await _storageService.getCurrentUser();
      if (currentUser != null) {
        final metrics = await _storageService.getPerformanceMetrics(currentUser.idUsuario!);
        setState(() {
          _metrics = metrics;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando métricas: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Indicadores de Desempeño',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF3D1F6E),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_metrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No hay datos disponibles',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con resumen
          _buildSummaryCard(),

          const SizedBox(height: 24),

          // Gráficos
          Text(
            'Análisis de Rendimiento',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3D1F6E),
            ),
          ),

          const SizedBox(height: 16),

          // Gráfico de ventas
          _buildSalesChart(),

          const SizedBox(height: 24),

          // Gráfico de reservas
          _buildReservationsChart(),

          const SizedBox(height: 24),

          // Gráfico de cotizaciones
          _buildQuotesChart(),

          const SizedBox(height: 24),

          // Métricas detalladas
          _buildDetailedMetrics(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final sales = _metrics['sales'] ?? {};
    final reservations = _metrics['reservations'] ?? {};
    final quotes = _metrics['quotes'] ?? {};

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3D1F6E), Color(0xFF2C53A4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Resumen del Mes',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSummaryItem(
                  'Ventas',
                  '${sales['completed'] ?? 0}/${sales['total'] ?? 0}',
                  Icons.attach_money,
                ),
                _buildSummaryItem(
                  'Reservas',
                  '${reservations['confirmed'] ?? 0}/${reservations['total'] ?? 0}',
                  Icons.book_online,
                ),
                _buildSummaryItem(
                  'Cotizaciones',
                  '${quotes['accepted'] ?? 0}/${quotes['total'] ?? 0}',
                  Icons.request_quote,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
    final sales = _metrics['sales'] ?? {};
    final completed = (sales['completed'] ?? 0).toDouble();
    final total = (sales['total'] ?? 0).toDouble();
    final pending = total - completed;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rendimiento de Ventas',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D1F6E),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: completed,
                      title: '${completed.toInt()}\nCompletadas',
                      color: const Color(0xFFfdb913),
                      radius: 60,
                      titleStyle: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: pending,
                      title: '${pending.toInt()}\nPendientes',
                      color: Colors.grey.shade300,
                      radius: 60,
                      titleStyle: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Completadas', const Color(0xFFfdb913)),
                _buildLegendItem('Pendientes', Colors.grey.shade300),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationsChart() {
    final reservations = _metrics['reservations'] ?? {};
    final confirmed = (reservations['confirmed'] ?? 0).toDouble();
    final total = (reservations['total'] ?? 0).toDouble();
    final pending = total - confirmed;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado de Reservas',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D1F6E),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: confirmed,
                      title: '${confirmed.toInt()}\nConfirmadas',
                      color: Colors.green,
                      radius: 60,
                      titleStyle: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: pending,
                      title: '${pending.toInt()}\nPendientes',
                      color: Colors.orange,
                      radius: 60,
                      titleStyle: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Confirmadas', Colors.green),
                _buildLegendItem('Pendientes', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotesChart() {
    final quotes = _metrics['quotes'] ?? {};
    final accepted = (quotes['accepted'] ?? 0).toDouble();
    final total = (quotes['total'] ?? 0).toDouble();
    final rejected = total - accepted;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conversión de Cotizaciones',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D1F6E),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: accepted,
                      title: '${accepted.toInt()}\nAceptadas',
                      color: const Color(0xFF4C39A6),
                      radius: 60,
                      titleStyle: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: rejected,
                      title: '${rejected.toInt()}\nRechazadas',
                      color: Colors.red.shade300,
                      radius: 60,
                      titleStyle: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Aceptadas', const Color(0xFF4C39A6)),
                _buildLegendItem('Rechazadas', Colors.red.shade300),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedMetrics() {
    final sales = _metrics['sales'] ?? {};
    final reservations = _metrics['reservations'] ?? {};
    final quotes = _metrics['quotes'] ?? {};

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métricas Detalladas',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D1F6E),
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Ingresos Totales',
              '\$${(sales['totalRevenue'] ?? 0).toStringAsFixed(0)}',
              Icons.attach_money,
            ),
            _buildMetricRow(
              'Venta Promedio',
              '\$${(sales['averageSale'] ?? 0).toStringAsFixed(0)}',
              Icons.trending_up,
            ),
            _buildMetricRow(
              'Tasa de Conversión',
              '${((quotes['conversionRate'] ?? 0) * 100).toStringAsFixed(1)}%',
              Icons.percent,
            ),
            const Divider(),
            Text(
              'Período: ${_metrics['period'] ?? 'N/A'}',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF3D1F6E)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3D1F6E),
            ),
          ),
        ],
      ),
    );
  }
}
