import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ClientListScreen extends StatelessWidget {
  const ClientListScreen({super.key, this.showAll = false});

  final bool showAll;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(showAll ? 'Clientes del equipo' : 'Clientes asignados'),
        backgroundColor: const Color(0xFF3D1F6E),
      ),
      backgroundColor: const Color(0xFFF6F7FB),
      floatingActionButton: showAll
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Formulario de clientes en desarrollo'),
                  ),
                );
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Nuevo cliente'),
              backgroundColor: const Color(0xFFfdb913),
            ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              showAll ? 'Gestión de clientes del equipo' : 'Gestión de clientes personales',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D1F6E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              showAll
                  ? 'Visualiza la cartera completa de clientes registrados por cada asesor. '
                    'Los listados y métricas se agruparán usando el campo `id_empleado`, lo que permitirá '
                    'filtrar por responsable, satisfacción y fecha de registro.'
                  : 'Cada registro quedará vinculado al asesor que lo crea mediante el campo `id_empleado`. '
                    'Esto garantiza que solo tú puedas ver, editar o eliminar la información de tus propios clientes.',
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D1F6E).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.people_outline,
                            color: Color(0xFF3D1F6E),
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          showAll
                              ? 'Aún no hay clientes registrados por el equipo.'
                              : 'Aún no tienes clientes asignados.',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F1F1F),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          showAll
                              ? 'Cuando los asesores comiencen a registrar prospectos, aparecerán aquí agrupados por responsable.'
                              : 'Registra tus primeros clientes desde el botón "Nuevo cliente" para construir tu cartera.',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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

  Widget _buildFieldTile({
    required IconData icon,
    required String label,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF3D1F6E).withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF3D1F6E)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.black87,
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
