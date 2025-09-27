import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquatour/dashboard_screen.dart';
import 'package:aquatour/limited_dashboard_screen.dart';
import 'package:aquatour/widgets/custom_button.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:aquatour/services/storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _claveFormulario = GlobalKey<FormState>();
  final _controladorUsuario = TextEditingController();
  final _controladorClave = TextEditingController();
  bool _ocultarClave = true;
  final StorageService _storageService = StorageService(); // Instancia del servicio
  bool _isLoading = false;

  @override
  void dispose() {
    _controladorUsuario.dispose();
    _controladorClave.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_claveFormulario.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final user = await _storageService.login(
        _controladorUsuario.text.trim(),
        _controladorClave.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No fue posible iniciar sesión. Verifica las credenciales.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final destination = user.esAdministrador
          ? const DashboardScreen()
          : const LimitedDashboardScreen();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error iniciando sesión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4C39A6), Color(0xFF2C53A4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 50.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _claveFormulario,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SizedBox(height: 16),
                        // Logo de AquaTour
                        Image.asset(
                          'assets/images/aqua-tour.png',
                          height: 150,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'AquaTour CRM',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Inicia sesión para continuar',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Semantics(
                          label: 'Usuario o correo',
                          child: TextFormField(
                            controller: _controladorUsuario,
                            decoration: InputDecoration(
                              labelText: 'Usuario o correo',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: RequiredValidator(errorText: 'El correo o usuario es obligatorio').call,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Semantics(
                          label: 'Contraseña',
                          child: TextFormField(
                            controller: _controladorClave,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _ocultarClave ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _ocultarClave = !_ocultarClave;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            obscureText: _ocultarClave,
                            validator: MinLengthValidator(6,
                                    errorText: 'La contraseña debe tener al menos 6 caracteres').call,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Semantics(
                                label: 'Iniciar Sesión',
                                child: CustomButton(
                                    text: 'Iniciar Sesión',
                                    onPressed: _iniciarSesion,
                                    color: const Color(0xFF4C39A6),
                                  ),
                              ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}