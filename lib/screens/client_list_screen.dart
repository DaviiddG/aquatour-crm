import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key, this.showAll = false});

  final bool showAll;

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _openClientForm() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ClientFormSheet(
          onSubmit: (data) {
            Navigator.of(context).pop();
            final firstName = data['nombreCompleto']?.toString().split(' ').first ?? 'cliente';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cliente $firstName registrado. (Integración pendiente)'),
                backgroundColor: const Color(0xFF3D1F6E),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showAll ? 'Clientes del equipo' : 'Clientes asignados'),
        backgroundColor: const Color(0xFF3D1F6E),
      ),
      backgroundColor: const Color(0xFFF6F7FB),
      floatingActionButton: widget.showAll
          ? null
          : FloatingActionButton.extended(
              onPressed: _openClientForm,
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
              widget.showAll ? 'Gestión de clientes del equipo' : 'Gestión de clientes personales',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D1F6E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.showAll
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
                          widget.showAll
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
                          widget.showAll
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

class _ClientFormSheet extends StatefulWidget {
  const _ClientFormSheet({required this.onSubmit});

  final void Function(Map<String, dynamic> data) onSubmit;

  @override
  State<_ClientFormSheet> createState() => _ClientFormSheetState();
}

class _ClientFormSheetState extends State<_ClientFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _paisController = TextEditingController();
  final _observacionesController = TextEditingController();

  DateTime? _fechaNacimiento;
  String _fuente = 'Referencia';
  String _interes = 'Cotización';

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _ciudadController.dispose();
    _paisController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _fechaNacimiento = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final data = <String, dynamic>{
      'nombreCompleto': _nombreController.text.trim(),
      'email': _emailController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      'ciudad': _ciudadController.text.trim(),
      'pais': _paisController.text.trim(),
      'fechaNacimiento': _fechaNacimiento?.toIso8601String(),
      'fuente': _fuente,
      'interes': _interes,
      'observaciones': _observacionesController.text.trim(),
    };

    widget.onSubmit(data);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, viewInsets.bottom + 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D1F6E).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_alt_1, color: Color(0xFF3D1F6E)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nuevo Cliente',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F1F1F),
                            ),
                          ),
                          Text(
                            'Completa la información del prospecto para asignarlo a tu cartera.',
                            style: GoogleFonts.montserrat(
                              fontSize: 12.5,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Información básica',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D1F6E),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El correo es obligatorio';
                          }
                          final emailReg = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!emailReg.hasMatch(value.trim())) {
                            return 'Formato inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El teléfono es obligatorio';
                          }
                          final phoneReg = RegExp(r'^\+?[0-9\s]{7,}$');
                          if (!phoneReg.hasMatch(value.trim())) {
                            return 'Formato inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ciudadController,
                        decoration: const InputDecoration(
                          labelText: 'Ciudad',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _paisController,
                        decoration: const InputDecoration(
                          labelText: 'País',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha de nacimiento',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _fechaNacimiento != null
                                ? '${_fechaNacimiento!.day.toString().padLeft(2, '0')}/'
                                    '${_fechaNacimiento!.month.toString().padLeft(2, '0')}/'
                                    '${_fechaNacimiento!.year}'
                                : 'Selecciona una fecha',
                            style: GoogleFonts.montserrat(
                              color: _fechaNacimiento != null ? const Color(0xFF1F1F1F) : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _fuente,
                        decoration: const InputDecoration(
                          labelText: 'Fuente de contacto *',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Referencia', child: Text('Referencia')),
                          DropdownMenuItem(value: 'Redes sociales', child: Text('Redes sociales')),
                          DropdownMenuItem(value: 'Página web', child: Text('Página web')),
                          DropdownMenuItem(value: 'Feria o evento', child: Text('Feria o evento')),
                          DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _fuente = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _interes,
                  decoration: const InputDecoration(
                    labelText: 'Interés principal *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Cotización', child: Text('Cotización')),
                    DropdownMenuItem(value: 'Reserva directa', child: Text('Reserva directa')),
                    DropdownMenuItem(value: 'Información general', child: Text('Información general')),
                    DropdownMenuItem(value: 'Seguimiento post-venta', child: Text('Seguimiento post-venta')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _interes = value);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _observacionesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Notas u observaciones',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Guardar cliente'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
