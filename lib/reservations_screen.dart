import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas'),
        backgroundColor: const Color(0xFF3D1F6E),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_online,
              size: 80,
              color: Color(0xFF3D1F6E),
            ),
            SizedBox(height: 20),
            Text(
              'Gestión de Reservas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D1F6E),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Próximamente: Sistema completo de reservas',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Función en desarrollo'),
            ),
          );
        },
        backgroundColor: const Color(0xFFfdb913),
        child: const Icon(Icons.add),
      ),
    );
  }
}
