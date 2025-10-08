import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquatour/widgets/module_scaffold.dart';

class CompaniesScreen extends StatelessWidget {
  const CompaniesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      title: 'Empresas aliadas',
      subtitle: 'Estandariza la relación con tus operadores',
      icon: Icons.business_rounded,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionalidad en desarrollo')),
        ),
        backgroundColor: const Color(0xFFf7941e),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar empresa'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeadlineCard(),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 720;
                return GridView.count(
                  crossAxisCount: isCompact ? 1 : 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: isCompact ? 16 / 9 : 20 / 9,
                  children: const [
                    _FeatureCard(
                      icon: Icons.handshake_rounded,
                      title: 'Convenios estratégicos',
                      description:
                          'Registra acuerdos, cláusulas y vigencia de cada empresa aliada. Próximamente podrás adjuntar contratos y documentar beneficios exclusivos.',
                    ),
                    _FeatureCard(
                      icon: Icons.contact_mail_rounded,
                      title: 'Referentes y ejecutivos',
                      description:
                          'Gestiona los puntos de contacto clave, teléfonos directos y horarios de atención para agilizar negociaciones y reservas.',
                    ),
                    _FeatureCard(
                      icon: Icons.insights_rounded,
                      title: 'Analítica de acuerdos',
                      description:
                          'Visualiza el desempeño de cada convenio: ingresos generados, reservas realizadas y satisfacción promedio de los clientes.',
                    ),
                    _FeatureCard(
                      icon: Icons.library_books_rounded,
                      title: 'Documentación centralizada',
                      description:
                          'Un repositorio único para brochures, tarifas, catálogos y políticas de cada operador turístico.',
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

class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard();

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
        padding: const EdgeInsets.all(32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estandariza la relación con tus operadores',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Consolida la información clave de hoteles, aerolíneas y operadores aliados. '
                    'Pronto podrás monitorear KPIs, documentar acuerdos y automatizar recordatorios de renovación.',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.white.withOpacity(0.88),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.tonal(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF3D1F6E),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    ),
                    child: const Text('Ver roadmap del módulo'),
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

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
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
