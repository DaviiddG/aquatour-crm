import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquatour/widgets/module_scaffold.dart';

class QuotesScreen extends StatelessWidget {
  const QuotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      title: 'Cotizaciones',
      subtitle: 'Diseña propuestas comerciales y haz seguimiento a su evolución',
      icon: Icons.request_quote_rounded,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionalidad en desarrollo')),
        ),
        backgroundColor: const Color(0xFFf7941e),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva cotización'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuotesSummaryCard(),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 720;
                return GridView.count(
                  crossAxisCount: isCompact ? 1 : 2,
                  childAspectRatio: isCompact ? 16 / 9 : 18 / 9,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  children: const [
                    _PlaceholderCard(
                      title: 'Embudo de cotizaciones',
                      description:
                          'Visualiza cuántas propuestas están en cada etapa: enviada, en negociación, ganada o perdida. Próximamente podrás arrastrar cada oportunidad.',
                      icon: Icons.timeline_rounded,
                    ),
                    _PlaceholderCard(
                      title: 'Segmentación por origen',
                      description:
                          'Analiza qué canales generan más solicitudes (web, referidos, campañas). La vista mostrará gráficos interactivos con comparativas mensuales.',
                      icon: Icons.pie_chart_rounded,
                    ),
                    _PlaceholderCard(
                      title: 'Plantillas inteligentes',
                      description:
                          'Guarda propuestas base con itinerarios, tarifas y beneficios para duplicarlas en segundos y personalizarlas por cliente.',
                      icon: Icons.description_outlined,
                    ),
                    _PlaceholderCard(
                      title: 'Seguimiento automático',
                      description:
                          'Recibe alertas cuando una cotización venza o lleve muchos días sin respuesta. Muy pronto podrás programar recordatorios automáticos.',
                      icon: Icons.alarm_rounded,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
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
