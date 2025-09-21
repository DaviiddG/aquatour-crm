import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CompaniesScreen extends StatelessWidget {
  const CompaniesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empresas'),
        backgroundColor: const Color(0xFF3D1F6E),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business,
              size: 80,
              color: Color(0xFF3D1F6E),
            ),
            SizedBox(height: 20),
            Text(
              'Gestión de Empresas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D1F6E),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Próximamente: Administración completa de empresas',
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
