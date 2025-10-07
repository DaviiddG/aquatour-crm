import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquatour/widgets/module_scaffold.dart';

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      title: 'Reservas activas',
      subtitle: 'Coordina viajes confirmados y tareas pendientes con cada proveedor',
      icon: Icons.event_available_rounded,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionalidad en desarrollo')),
        ),
        backgroundColor: const Color(0xFFf7941e),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva reserva'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReservationsHero(),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 780;
                return GridView.count(
                  crossAxisCount: isCompact ? 1 : 2,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  childAspectRatio: isCompact ? 16 / 10 : 20 / 10,
                  children: const [
                    _ReservationFeatureCard(
                      icon: Icons.flight_takeoff_rounded,
                      title: 'Calendario inteligente',
                      description:
                          'Sincroniza todos los viajes confirmados con recordatorios automáticos para check-in, documentación y pagos pendientes.',
                    ),
                    _ReservationFeatureCard(
                      icon: Icons.task_alt_rounded,
                      title: 'Checklist operativo',
                      description:
                          'Asigna tareas por reserva (vuelos, alojamiento, traslados) y monitoréalas en tiempo real para asegurar la experiencia del cliente.',
                    ),
                    _ReservationFeatureCard(
                      icon: Icons.receipt_long_rounded,
                      title: 'Control financiero',
                      description:
                          'Registra abonos, comisiones y saldos con proveedores. El módulo mostrará alertas cuando falte conciliar un pago.',
                    ),
                    _ReservationFeatureCard(
                      icon: Icons.support_agent_rounded,
                      title: 'Atención post-venta',
                      description:
                          'Centraliza incidencias, solicitudes especiales y encuestas de satisfacción para cada reserva gestionada.',
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

class _ReservationsHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF3D1F6E),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3D1F6E).withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 18),
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
              child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Todas las reservas bajo control',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Monitorea la evolución de cada itinerario, centraliza documentos y coordina con proveedores sin salir del CRM.',
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

class _ReservationFeatureCard extends StatelessWidget {
  const _ReservationFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
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
