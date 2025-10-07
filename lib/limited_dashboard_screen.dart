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
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.builder,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final WidgetBuilder builder;
}

class LimitedDashboardScreen extends StatefulWidget {
  const LimitedDashboardScreen({super.key});

  @override
  State<LimitedDashboardScreen> createState() => _LimitedDashboardScreenState();
}

class _LimitedDashboardScreenState extends State<LimitedDashboardScreen> {
  final StorageService _storageService = StorageService();
  List<_LimitedModule> _modules = [];
  bool _loadingModules = true;
  User? _currentUser;

  static List<_LimitedModule> _baseModules() => [
        _LimitedModule(
          id: 'quotes',
          title: 'Cotizaciones',
          description: 'Genera propuestas a clientes y da seguimiento a su estado.',
          icon: Icons.request_quote,
          builder: (context) => const QuotesScreen(),
        ),
        _LimitedModule(
          id: 'reservations',
          title: 'Reservas',
          description: 'Revisa viajes agendados y actualiza la información necesaria.',
          icon: Icons.book_online,
          builder: (context) => const ReservationsScreen(),
        ),
        _LimitedModule(
          id: 'contacts',
          title: 'Contactos',
          description: 'Consulta datos clave de clientes y mantén la información al día.',
          icon: Icons.contacts,
          builder: (context) => const ContactsScreen(),
        ),
        _LimitedModule(
          id: 'metrics',
          title: 'Indicadores de Desempeño',
          description: 'Visualiza tus métricas personales y analiza tu rendimiento mensual.',
          icon: Icons.analytics,
          builder: (context) => const PerformanceIndicatorsScreen(),
        ),
        _LimitedModule(
          id: 'clients',
          title: 'Clientes',
          description: 'Gestiona la cartera de clientes asignados y su información clave.',
          icon: Icons.people_outline,
          builder: (context) => const ClientListScreen(),
        ),
        _LimitedModule(
          id: 'destinations',
          title: 'Destinos',
          description: 'Explora los destinos disponibles para crear experiencias a medida.',
          icon: Icons.location_on_outlined,
          builder: (context) => const DestinationsScreen(),
        ),
        _LimitedModule(
          id: 'packages',
          title: 'Paquetes Turísticos',
          description: 'Consulta y personaliza paquetes y promociones para tus clientes.',
          icon: Icons.card_travel,
          builder: (context) => const TourPackagesScreen(),
        ),
      ];

  @override
  void initState() {
    super.initState();
    _initializeModules();
  }

  Future<void> _initializeModules() async {
    final user = await _storageService.getCurrentUser();
    final baseModules = _baseModules();
    final orderKey = user == null ? 'guest' : _orderKeyForUser(user);
    final storedOrder = await _storageService.getDashboardOrder(orderKey);
    final moduleMap = {for (final module in baseModules) module.id: module};
    final ordered = <_LimitedModule>[];

    for (final id in storedOrder) {
      final module = moduleMap.remove(id);
      if (module != null) ordered.add(module);
    }
    ordered.addAll(moduleMap.values);

    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _modules = ordered;
      _loadingModules = false;
    });
  }

  String _orderKeyForUser(User user) {
    final identifier = user.idUsuario?.toString().trim();
    if (identifier != null && identifier.isNotEmpty) {
      return 'limited_$identifier';
    }
    return 'limited_${user.email}';
  }

  void _handleReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final updated = List<_LimitedModule>.from(_modules);
    final module = updated.removeAt(oldIndex);
    updated.insert(newIndex, module);

    setState(() {
      _modules = updated;
    });

    final user = _currentUser;
    final key = user == null ? 'guest' : _orderKeyForUser(user);
    _storageService.saveDashboardOrder(key, updated.map((m) => m.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 520;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: isNarrow ? 16 : 24,
        title: Row(
          children: [
            Container(
              height: isNarrow ? 38 : 44,
              width: isNarrow ? 38 : 44,
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
          if (isNarrow)
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: () => _handleLogout(context),
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFf7941e),
              ),
            )
          else
            TextButton.icon(
              onPressed: () => _handleLogout(context),
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

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: _LimitedHeader(width: width, currentUser: _currentUser),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Mantén presionado y arrastra las tarjetas para ordenar tus accesos.',
                      style: GoogleFonts.montserrat(fontSize: 11, color: const Color(0xFF6F6F6F)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loadingModules
                      ? const Center(child: CircularProgressIndicator())
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                          buildDefaultDragHandles: false,
                          physics: const BouncingScrollPhysics(),
                          onReorder: _handleReorder,
                          itemCount: _modules.length,
                          itemBuilder: (context, index) {
                            final module = _modules[index];
                            return Padding(
                              key: ValueKey(module.id),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: ReorderableDelayedDragStartListener(
                                index: index,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minHeight: 140),
                                  child: DashboardOptionCard(
                                    title: module.title,
                                    description: module.description,
                                    icon: module.icon,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: module.builder),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
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

  Future<void> _handleLogout(BuildContext context) async {
    await _storageService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
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
      child: Row(
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
                    color: Colors.white.withOpacity(0.84),
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
                    'Prioriza tus clientes clave y mantén vivas tus oportunidades.',
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
    );
  }
}
