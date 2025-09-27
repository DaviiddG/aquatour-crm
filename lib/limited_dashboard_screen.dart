import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquatour/contacts_screen.dart';
import 'package:aquatour/login_screen.dart';
import 'package:aquatour/performance_indicators_screen.dart';
import 'package:aquatour/quotes_screen.dart';
import 'package:aquatour/reservations_screen.dart';
import 'package:aquatour/widgets/dashboard_option_card.dart';
import 'package:aquatour/models/user.dart';
import 'package:aquatour/services/storage_service.dart';
import 'package:aquatour/screens/destinations_screen.dart';
import 'package:aquatour/screens/tour_packages_screen.dart';
import 'package:aquatour/screens/client_list_screen.dart';

class _LimitedModule {
  const _LimitedModule({
    required this.title,
    required this.description,
    required this.icon,
    required this.builder,
  });

  final String title;
  final String description;
  final IconData icon;
  final WidgetBuilder builder;
}

class LimitedDashboardScreen extends StatelessWidget {
  const LimitedDashboardScreen({super.key});

  static final List<_LimitedModule> _modules = [
    _LimitedModule(
      title: 'Cotizaciones',
      description: 'Genera propuestas a clientes y da seguimiento a su estado.',
      icon: Icons.request_quote,
      builder: (context) => const QuotesScreen(),
    ),
    _LimitedModule(
      title: 'Reservas',
      description: 'Revisa viajes agendados y actualiza la información necesaria.',
      icon: Icons.book_online,
      builder: (context) => const ReservationsScreen(),
    ),
    _LimitedModule(
      title: 'Contactos',
      description: 'Consulta datos clave de clientes y mantén la información al día.',
      icon: Icons.contacts,
      builder: (context) => const ContactsScreen(),
    ),
    _LimitedModule(
      title: 'Indicadores de Desempeño',
      description: 'Visualiza tus métricas personales y analiza tu rendimiento mensual.',
      icon: Icons.analytics,
      builder: (context) => const PerformanceIndicatorsScreen(),
    ),
    _LimitedModule(
      title: 'Clientes',
      description: 'Gestiona la cartera de clientes asignados y su información clave.',
      icon: Icons.people_outline,
      builder: (context) => const ClientListScreen(),
    ),
    _LimitedModule(
      title: 'Destinos',
      description: 'Explora los destinos disponibles para crear experiencias a medida.',
      icon: Icons.location_on_outlined,
      builder: (context) => const DestinationsScreen(),
    ),
    _LimitedModule(
      title: 'Paquetes Turísticos',
      description: 'Consulta y personaliza paquetes y promociones para tus clientes.',
      icon: Icons.card_travel,
      builder: (context) => const TourPackagesScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 24,
        title: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF3D1F6E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Color(0xFF3D1F6E),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel de Empleado',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
                Text(
                  'Accede rápidamente a tus módulos habilitados',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: const Color(0xFF6F6F6F),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await StorageService().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFf7941e),
              textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar sesión'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = _columnsForWidth(width);
            final cardAspectRatio = _aspectRatioForWidth(width);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: FutureBuilder<User?>(
                      future: StorageService().getCurrentUser(),
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        return _LimitedHeader(width: width, currentUser: user);
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 16,
                      childAspectRatio: cardAspectRatio,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final module = _modules[index];
                        return DashboardOptionCard(
                          title: module.title,
                          description: module.description,
                          icon: module.icon,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: module.builder),
                          ),
                        );
                      },
                      childCount: _modules.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }

  int _columnsForWidth(double width) {
    if (width >= 1200) return 3;
    if (width >= 800) return 2;
    return 1;
  }

  double _aspectRatioForWidth(double width) {
    if (width >= 1200) return 1.6;
    if (width >= 800) return 1.45;
    return 1.3;
  }
}

class _LimitedHeader extends StatelessWidget {
  const _LimitedHeader({required this.width, this.currentUser});

  final double width;
  final User? currentUser;

  @override
  Widget build(BuildContext context) {
    final isCompact = width < 900;
    final firstName = (currentUser?.nombre ?? '').trim();
    final greetingName = firstName.isNotEmpty ? firstName.split(' ').first : 'Bienvenido';
    final subtitle = currentUser != null
        ? 'Accede a tus módulos asignados y consulta tu rendimiento en tiempo real.'
        : 'Gestiona tus tareas y mantente al día con tus clientes.';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 20 : 32,
        vertical: isCompact ? 24 : 32,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C39A6), Color(0xFF2C53A4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C53A4).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola, $greetingName 👋',
            style: GoogleFonts.montserrat(
              fontSize: isCompact ? 22 : 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: GoogleFonts.montserrat(
              fontSize: isCompact ? 13 : 14,
              color: Colors.white.withOpacity(0.84),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
