import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/user.dart';
import 'login_screen.dart';
import 'performance_indicators_screen.dart';
import 'contacts_screen.dart';
import 'companies_screen.dart';
import 'quotes_screen.dart';
import 'reservations_screen.dart';
import 'user_management_screen.dart';
import 'services/storage_service.dart';
import 'widgets/dashboard_option_card.dart';

class DashboardModule {
  final String title;
  final String description;
  final IconData icon;
  final String? badge;
  final WidgetBuilder builder;
  final List<UserRole> allowedRoles;

  const DashboardModule({
    required this.title,
    required this.description,
    required this.icon,
    required this.builder,
    this.badge,
    this.allowedRoles = const [
      UserRole.empleado,
      UserRole.administrador,
      UserRole.superadministrador
    ],
  });
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  List<DashboardModule> _getModulesForUser(User user) {
    final modules = <DashboardModule>[
      DashboardModule(
        title: 'Indicadores',
        description: 'Métricas clave del negocio y desempeño del equipo.',
        icon: Icons.analytics_rounded,
        builder: (context) => const PerformanceIndicatorsScreen(),
      ),
      DashboardModule(
        title: 'Contactos',
        description: 'Base de clientes y prospectos asignados.',
        icon: Icons.people_alt_rounded,
        builder: (context) => const ContactsScreen(),
      ),
      DashboardModule(
        title: 'Empresas',
        description: 'Directorio de compañías con las que colaboramos.',
        icon: Icons.business_rounded,
        builder: (context) => const CompaniesScreen(),
      ),
      DashboardModule(
        title: 'Cotizaciones',
        description: 'Prepara y da seguimiento a propuestas comerciales.',
        icon: Icons.request_quote_rounded,
        builder: (context) => const QuotesScreen(),
      ),
      DashboardModule(
        title: 'Reservas',
        description: 'Gestiona reservas y estado de viajes confirmados.',
        icon: Icons.event_available_rounded,
        builder: (context) => const ReservationsScreen(),
      ),
      DashboardModule(
        title: 'Usuarios',
        description: 'Administra credenciales, roles y accesos.',
        icon: Icons.admin_panel_settings_rounded,
        badge: 'Solo administración',
        builder: (context) => const UserManagementScreen(),
        allowedRoles: const [UserRole.administrador, UserRole.superadministrador],
      ),
    ];

    return modules.where((module) => module.allowedRoles.contains(user.rol)).toList();
  }

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
                Icons.dashboard_customize_rounded,
                color: Color(0xFF3D1F6E),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel de Control',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
                Text(
                  'Gestiona las métricas clave y coordina a tu equipo',
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
        child: FutureBuilder<User?>(
          future: StorageService().getCurrentUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('No se pudo cargar la información del usuario'));
            }

            final user = snapshot.data!;
            final modules = _getModulesForUser(user);

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = _getColumnsForWidth(width);
                final cardAspectRatio = _getAspectRatioForWidth(width);

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                        child: _DashboardHeader(
                          width: width,
                          currentUser: user,
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
                            final module = modules[index];
                            return DashboardOptionCard(
                              title: module.title,
                              description: module.description,
                              icon: module.icon,
                              badge: module.badge,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: module.builder),
                              ),
                            );
                          },
                          childCount: modules.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  int _getColumnsForWidth(double width) {
    if (width >= 1200) return 3;
    if (width >= 800) return 2;
    return 1;
  }

  double _getAspectRatioForWidth(double width) {
    if (width >= 1200) return 1.6;
    if (width >= 800) return 1.45;
    return 1.3;
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.width, this.currentUser});

  final double width;
  final User? currentUser;

  @override
  Widget build(BuildContext context) {
    final isCompact = width < 900;
    final firstName = (currentUser?.nombre ?? '').trim();
    final greetingName = firstName.isNotEmpty ? firstName.split(' ').first : 'Bienvenido';
    final subtitle = currentUser != null
        ? 'Gestiona tus módulos como ${currentUser!.rol.displayName} desde este panel centralizado.'
        : 'Supervisa las operaciones clave desde un solo lugar.';

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, $greetingName 👋',
                      style: GoogleFonts.montserrat(
                        fontSize: isCompact ? 22 : 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: GoogleFonts.montserrat(
                        fontSize: isCompact ? 13 : 15,
                        color: Colors.white.withOpacity(0.82),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCompact) const SizedBox(width: 24),
              if (!isCompact)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoy',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Observa las métricas clave y gestiona tus equipos en minutos.',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
