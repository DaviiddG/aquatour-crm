import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pagos'),
        backgroundColor: const Color(0xFF3D1F6E),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Color(0xFF3D1F6E),
            ),
            SizedBox(height: 20),
            Text(
              'Historial de Pagos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D1F6E),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Próximamente: Seguimiento completo de pagos',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
