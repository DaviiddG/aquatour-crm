import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TourPackagesScreen extends StatelessWidget {
  const TourPackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paquetes Turísticos'),
        backgroundColor: const Color(0xFF3D1F6E),
      ),
      backgroundColor: const Color(0xFFF6F7FB),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestión de Paquetes',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D1F6E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'En este módulo podrás visualizar los paquetes turísticos activos, sus componentes '
              '(alojamiento, transporte, actividades) y costos asociados. '
              'Más adelante se habilitará la opción de personalizar tarifas y crear paquetes nuevos para tus clientes.',
              style: GoogleFonts.montserrat(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Próximamente se mostrarán listados de paquetes, filtros por destino y temporada, '
                      'así como comparativas de precios para ayudarte a proponer la mejor opción a cada cliente.',
                      style: GoogleFonts.montserrat(fontSize: 15, color: Colors.grey[700], height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
