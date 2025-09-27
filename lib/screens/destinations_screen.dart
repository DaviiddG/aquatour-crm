import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DestinationsScreen extends StatelessWidget {
  const DestinationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Destinos disponibles'),
        backgroundColor: const Color(0xFF3D1F6E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catálogo de destinos',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D1F6E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Aquí podrás explorar todos los destinos habilitados por el área de producto. '
              'Los asesores tendrán acceso a descripciones, temporadas, tarifas base y recomendaciones '
              'para crear propuestas personalizadas.',
              style: GoogleFonts.montserrat(fontSize: 14, height: 1.5, color: Colors.black87),
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
                      'Próximamente podrás filtrar por continente, temporada, categoría y nivel de precios. '
                      'Este módulo también mostrará fotografías, puntuaciones y experiencias recomendadas para cada destino.',
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
      backgroundColor: const Color(0xFFF6F7FB),
    );
  }
}
