import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquatour/widgets/module_scaffold.dart';

class DestinationsScreen extends StatelessWidget {
  const DestinationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mockCards = [
      const _DestinationSummaryCard(
        icon: Icons.public_rounded,
        label: 'Continentes cubiertos',
        value: '0',
        description: 'Añade destinos en cada región con tarifas actualizadas.',
      ),
      const _DestinationSummaryCard(
        icon: Icons.thermostat_auto_rounded,
        label: 'Temporadas destacadas',
        value: '0',
        description: 'Define temporadas altas y bajas para optimizar precios.',
      ),
      const _DestinationSummaryCard(
        icon: Icons.image_rounded,
        label: 'Galería multimedia',
        value: '0',
        description: 'Carga fotos y reseñas para inspirar a tus clientes.',
      ),
    ];

    return ModuleScaffold(
      title: 'Destinos disponibles',
      subtitle: 'Explora y administra el portafolio de viajes para tus clientes.',
      icon: Icons.flight_takeoff_rounded,
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
                  children: mockCards
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
                          'Construye tu catálogo',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3D1F6E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Administra información clave como temporadas, actividades, partners y costos locales. '
                          'Muy pronto podrás importar catálogos masivos y sincronizarlos con tus propuestas.',
                          style: GoogleFonts.montserrat(fontSize: 14, height: 1.55, color: Colors.black87),
                        ),
                        const SizedBox(height: 22),
                        Center(
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
