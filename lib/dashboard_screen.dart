import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquatour/companies_screen.dart';
import 'package:aquatour/contacts_screen.dart';
import 'package:aquatour/login_screen.dart';
import 'package:aquatour/payment_history_screen.dart';
import 'package:aquatour/quotes_screen.dart';
import 'package:aquatour/reservations_screen.dart';
import 'package:aquatour/user_management_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Principal de Aquatour'),
        backgroundColor: const Color(0xFF0A2463),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Navega de vuelta a la pantalla de inicio de sesión
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        childAspectRatio: 3 / 2,
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        children: <Widget>[
          _buildDashboardItem(
            context,
            'Cotizaciones',
            Icons.request_quote,
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const QuotesScreen()),
            ),
          ),
          _buildDashboardItem(
            context,
            'Usuarios',
            Icons.people,
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const UserManagementScreen()),
            ),
          ),
          _buildDashboardItem(
            context,
            'Reservas',
            Icons.book_online,
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ReservationsScreen()),
            ),
          ),
          _buildDashboardItem(
            context,
            'Historial de Pagos',
            Icons.history,
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const PaymentHistoryScreen()),
            ),
          ),
          _buildDashboardItem(
            context,
            'Empresas',
            Icons.business,
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CompaniesScreen()),
            ),
          ),
          _buildDashboardItem(
            context,
            'Contactos',
            Icons.contacts,
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ContactsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 48.0, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
