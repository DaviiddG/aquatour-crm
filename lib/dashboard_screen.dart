import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquatour/companies_screen.dart';
import 'package:aquatour/contacts_screen.dart';
import 'package:aquatour/login_screen.dart';
import 'package:aquatour/payment_history_screen.dart';
import 'package:aquatour/quotes_screen.dart';
import 'package:aquatour/reservations_screen.dart';
import 'package:aquatour/user_management_screen.dart';
import 'package:aquatour/widgets/dashboard_option_card.dart';

class _DashboardModule {
  const _DashboardModule({
    required this.title,
    required this.description,
    required this.icon,
    this.badge,
    required this.builder,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? badge;
  final WidgetBuilder builder;
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static final List<_DashboardModule> _modules = [
    _DashboardModule(
      title: 'Cotizaciones',
      description: 'Crea, envía y realiza seguimiento a las cotizaciones emitidas.',
      icon: Icons.request_quote,
      badge: 'Nuevo',
      builder: (context) => const QuotesScreen(),
    ),
    _DashboardModule(
      title: 'Usuarios',
      description: 'Gestiona roles, permisos y estados de los usuarios en el sistema.',
      icon: Icons.people_alt,
      builder: (context) => const UserManagementScreen(),
    ),
    _DashboardModule(
      title: 'Reservas',
      description: 'Administra las reservas activas y próximas salidas.',
      icon: Icons.book_online,
      builder: (context) => const ReservationsScreen(),
    ),
    _DashboardModule(
      title: 'Historial de Pagos',
      description: 'Consulta pagos recientes y verifica estados de facturación.',
      icon: Icons.history_toggle_off,
      builder: (context) => const PaymentHistoryScreen(),
    ),
    _DashboardModule(
      title: 'Empresas',
      description: 'Mantén actualizados los datos de tus aliados estratégicos.',
      icon: Icons.apartment,
      builder: (context) => const CompaniesScreen(),
    ),
    _DashboardModule(
      title: 'Contactos',
      description: 'Gestiona la información clave de tus clientes y prospectos.',
      icon: Icons.contacts,
      builder: (context) => const ContactsScreen(),
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
                Icons.dashboard_customize,
                color: Color(0xFF3D1F6E),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel Principal',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
                Text(
                  'Gestiona todos los módulos clave de Aquatour desde aquí',
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
            onPressed: () {
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
                    child: _DashboardHeader(width: width),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: cardAspectRatio,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final module = _modules[index];
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
    if (width >= 1400) return 4;
    if (width >= 1080) return 3;
    if (width >= 760) return 2;
    return 1;
  }

  double _aspectRatioForWidth(double width) {
    if (width >= 1400) return 1.25;
    if (width >= 1080) return 1.2;
    if (width >= 760) return 1.15;
    return 1.4;
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final isCompact = width < 900;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 20 : 32,
        vertical: isCompact ? 24 : 32,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D1F6E), Color(0xFF4C39A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3D1F6E).withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
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
                      'Bienvenido a Aquatour CRM',
                      style: GoogleFonts.montserrat(
                        fontSize: isCompact ? 22 : 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supervisa todas las operaciones desde un panel diseñado para ofrecerte rapidez y claridad.',
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
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _HeaderChip(
                icon: Icons.check_circle_rounded,
                label: 'Módulos activos: 6',
              ),
              _HeaderChip(
                icon: Icons.supervisor_account,
                label: 'Usuarios conectados: 18',
              ),
              _HeaderChip(
                icon: Icons.auto_graph,
                label: 'Productividad semanal +12%',
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }
}
