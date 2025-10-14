import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget para manejar cambios no guardados en formularios
/// Muestra un diálogo de confirmación antes de salir si hay cambios pendientes
class UnsavedChangesHandler extends StatefulWidget {
  final Widget child;
  final bool hasUnsavedChanges;
  final VoidCallback? onSave;
  final String? customMessage;

  const UnsavedChangesHandler({
    super.key,
    required this.child,
    required this.hasUnsavedChanges,
    this.onSave,
    this.customMessage,
  });

  @override
  State<UnsavedChangesHandler> createState() => _UnsavedChangesHandlerState();
}

class _UnsavedChangesHandlerState extends State<UnsavedChangesHandler> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        debugPrint('🚪 Intentando salir - hasUnsavedChanges: ${widget.hasUnsavedChanges}');
        
        if (!widget.hasUnsavedChanges) {
          debugPrint('✅ No hay cambios, permitiendo salir');
          return true;
        }

        debugPrint('⚠️ Hay cambios sin guardar, mostrando diálogo');
        final result = await showUnsavedChangesDialog(
          context,
          onSave: widget.onSave,
          customMessage: widget.customMessage,
        );

        debugPrint('📝 Resultado del diálogo: $result');
        return result ?? false;
      },
      child: widget.child,
    );
  }
}

/// Muestra un diálogo de confirmación para cambios no guardados
Future<bool?> showUnsavedChangesDialog(
  BuildContext context, {
  VoidCallback? onSave,
  String? customMessage,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[700],
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '¿Descartar cambios?',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customMessage ??
                  'Tienes cambios sin guardar. Si sales ahora, perderás todos los cambios realizados.',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¿Qué deseas hacer?',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Botón Cancelar (quedarse en la página)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancelar',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          
          // Botón Guardar (si está disponible)
          if (onSave != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(false);
                onSave();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D1F6E),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.save, size: 18, color: Colors.white),
              label: Text(
                'Guardar',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          
          // Botón Descartar
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white),
            label: Text(
              'Descartar',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    },
  );
}
