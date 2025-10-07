import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquatour/widgets/module_scaffold.dart';

class TourPackagesScreen extends StatelessWidget {
  const TourPackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      const _PackageSummaryCard(
        icon: Icons.card_travel_rounded,
        label: 'Paquetes activos',
        value: '0',
        description: 'Configura paquetes base para reutilizarlos rápidamente.',
      ),
      const _PackageSummaryCard(
        icon: Icons.settings_input_component_rounded,
        label: 'Componentes promedio',
        value: '0',
        description: 'Alojamiento, tours y transportes combinados por paquete.',
      ),
      const _PackageSummaryCard(
        icon: Icons.attach_money_rounded,
        label: 'Margen estimado',
        value: '0%',
        description: 'Optimiza el margen con tarifas dinámicas y descuentos.',
      ),
    ];

    return ModuleScaffold(
      title: 'Paquetes turísticos',
      subtitle: 'Diseña propuestas completas y personalizadas para tus clientes.',
      icon: Icons.work_outline_rounded,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Función en desarrollo: pronto podrás crear paquetes.'),
              backgroundColor: const Color(0xFF3D1F6E),
            ),
          );
        },
        backgroundColor: const Color(0xFFf7941e),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo paquete'),
      ),
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
                  children: metrics
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
                          'Construye experiencias únicas',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3D1F6E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Muy pronto podrás combinar destinos, alojamientos, actividades y extras en itinerarios completos, '
                          'establecer reglas de precio y compartir cotizaciones al instante.',
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
                                child: const Icon(Icons.card_travel_rounded, color: Color(0xFF3D1F6E), size: 38),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Todavía no tienes paquetes creados.',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1F1F1F),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Configura tu primer paquete para reutilizarlo en futuras propuestas.',
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

class _PackageSummaryCard extends StatelessWidget {
  const _PackageSummaryCard({
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
