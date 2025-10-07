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
import 'screens/client_list_screen.dart';
import 'screens/destinations_screen.dart';
import 'screens/tour_packages_screen.dart';

class DashboardModule {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String? badge;
  final WidgetBuilder builder;
  final List<UserRole> allowedRoles;

  const DashboardModule({
    required this.id,
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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StorageService _storageService = StorageService();
  User? _activeUser;
  List<DashboardModule> _modules = [];
  bool _loadingModules = false;

  List<DashboardModule> _getModulesForUser(User user) {
    final modules = <DashboardModule>[
      DashboardModule(
        id: 'indicators',
        title: 'Indicadores',
        description: 'Métricas clave del negocio y desempeño del equipo.',
        icon: Icons.analytics_rounded,
        builder: (context) => const PerformanceIndicatorsScreen(),
      ),
      DashboardModule(
        id: 'users',
        title: 'Usuarios',
        description: 'Administra credenciales, roles y accesos.',
        icon: Icons.admin_panel_settings_rounded,
        badge: 'Solo administración',
        builder: (context) => const UserManagementScreen(),
        allowedRoles: const [UserRole.administrador, UserRole.superadministrador],
      ),
      DashboardModule(
        id: 'clients',
        title: 'Clientes',
        description: 'Gestiona la cartera completa del equipo y asignaciones.',
        icon: Icons.people_outline_rounded,
        builder: (context) => const ClientListScreen(showAll: true),
        allowedRoles: const [UserRole.administrador, UserRole.superadministrador],
      ),
      DashboardModule(
        id: 'contacts',
        title: 'Contactos',
        description: 'Base de clientes y prospectos asignados.',
        icon: Icons.people_alt_rounded,
        builder: (context) => const ContactsScreen(),
      ),
      DashboardModule(
        id: 'destinations',
        title: 'Destinos',
        description: 'Explora destinos y materiales para personalizar experiencias.',
        icon: Icons.flight_takeoff_rounded,
        builder: (context) => const DestinationsScreen(),
        allowedRoles: const [UserRole.administrador, UserRole.superadministrador],
      ),
      DashboardModule(
        id: 'packages',
        title: 'Paquetes turísticos',
        description: 'Centraliza paquetes base y promociones para el equipo.',
        icon: Icons.card_travel_rounded,
        builder: (context) => const TourPackagesScreen(),
        allowedRoles: const [UserRole.administrador, UserRole.superadministrador],
      ),
      DashboardModule(
        id: 'quotes',
        title: 'Cotizaciones',
        description: 'Prepara y da seguimiento a propuestas comerciales.',
        icon: Icons.request_quote_rounded,
        builder: (context) => const QuotesScreen(),
      ),
      DashboardModule(
        id: 'reservations',
        title: 'Reservas',
        description: 'Gestiona reservas y estado de viajes confirmados.',
        icon: Icons.event_available_rounded,
        builder: (context) => const ReservationsScreen(),
      ),
      DashboardModule(
        id: 'companies',
        title: 'Empresas',
        description: 'Directorio de compañías con las que colaboramos.',
        icon: Icons.business_rounded,
        builder: (context) => const CompaniesScreen(),
      ),
    ];

    return modules.where((module) => module.allowedRoles.contains(user.rol)).toList();
  }

  List<DashboardModule> _applyStoredOrder(
    List<DashboardModule> modules,
    List<String> storedOrder,
  ) {
    if (storedOrder.isEmpty) {
      return modules;
    }

    final moduleMap = {for (final module in modules) module.id: module};
    final ordered = <DashboardModule>[];

    for (final id in storedOrder) {
      final module = moduleMap.remove(id);
      if (module != null) {
        ordered.add(module);
      }
    }

    ordered.addAll(moduleMap.values);
    return ordered;
  }

  String _orderKeyForUser(User user) {
    final identifier = user.idUsuario?.toString().trim();
    if (identifier != null && identifier.isNotEmpty) {
      return identifier;
    }
    return user.email;
  }

  void _ensureModulesLoaded(User user) {
    final sameUser = _activeUser?.idUsuario == user.idUsuario;
    if (sameUser && (_modules.isNotEmpty || _loadingModules)) {
      return;
    }

    _activeUser = user;
    if (!_loadingModules) {
      _loadingModules = true;
      Future.microtask(() {
        if (!mounted) return;
        setState(() {});
      });
    }

    final userKey = _orderKeyForUser(user);
    Future.microtask(() async {
      final modules = _getModulesForUser(user);
      final storedOrder = await _storageService.getDashboardOrder(userKey);
      if (!mounted) return;
      setState(() {
        _modules = _applyStoredOrder(modules, storedOrder);
        _loadingModules = false;
      });
    });
  }

  void _handleReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final updated = List<DashboardModule>.from(_modules);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    setState(() {
      _modules = updated;
    });

    final user = _activeUser;
    if (user != null) {
      _storageService.saveDashboardOrder(
        _orderKeyForUser(user),
        updated.map((module) => module.id).toList(),
      );
    }
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
              await _storageService.logout();
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
          future: _storageService.getCurrentUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('No se pudo cargar la información del usuario'));
            }

            final user = snapshot.data!;
            _ensureModulesLoaded(user);
            final modules = _modules;
            final width = MediaQuery.of(context).size.width;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: _DashboardHeader(
                    width: width,
                    currentUser: user,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Mantén presionado y arrastra para ordenar tus módulos.',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: const Color(0xFF6F6F6F),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loadingModules && modules.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : modules.isEmpty
                          ? const Center(child: Text('No tienes módulos disponibles.'))
                          : ReorderableListView.builder(
                              buildDefaultDragHandles: false,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                              itemCount: modules.length,
                              onReorder: _handleReorder,
                              itemBuilder: (context, index) {
                                final module = modules[index];
                                return Padding(
                                  key: ValueKey(module.id),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: ReorderableDelayedDragStartListener(
                                    index: index,
                                    child: DashboardOptionCard(
                                      title: module.title,
                                      description: module.description,
                                      icon: module.icon,
                                      badge: module.badge,
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: module.builder),
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
