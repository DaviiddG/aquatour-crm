import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aquatour/dashboard_screen.dart';
import 'package:aquatour/limited_dashboard_screen.dart';
import 'package:aquatour/widgets/custom_button.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:aquatour/services/storage_service.dart';
import 'package:aquatour/services/access_log_service.dart';
import 'dart:html' as html;

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
  
  // Control de intentos de login
  static const int _maxLoginAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  @override
  void dispose() {
    _controladorUsuario.dispose();
    _controladorClave.dispose();
    super.dispose();
  }

  // Obtener IP del cliente (limitado en web)
  String _getClientIP() {
    try {
      // En web, no podemos obtener la IP real del cliente directamente
      // Retornamos un placeholder que el backend puede reemplazar
      return 'Web Client';
    } catch (e) {
      return 'Unknown';
    }
  }

  // Obtener información del navegador
  String _getBrowserInfo() {
    try {
      final userAgent = html.window.navigator.userAgent;
      if (userAgent.contains('Chrome')) return 'Chrome';
      if (userAgent.contains('Firefox')) return 'Firefox';
      if (userAgent.contains('Safari')) return 'Safari';
      if (userAgent.contains('Edge')) return 'Edge';
      return 'Unknown Browser';
    } catch (e) {
      return 'Unknown';
    }
  }

  // Obtener información del sistema operativo
  String _getOSInfo() {
    try {
      final userAgent = html.window.navigator.userAgent;
      if (userAgent.contains('Windows')) return 'Windows';
      if (userAgent.contains('Mac')) return 'macOS';
      if (userAgent.contains('Linux')) return 'Linux';
      if (userAgent.contains('Android')) return 'Android';
      if (userAgent.contains('iOS')) return 'iOS';
      return 'Unknown OS';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _iniciarSesion() async {
    if (!_claveFormulario.currentState!.validate()) return;

    // Verificar si la cuenta está bloqueada
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      final remainingMinutes = _lockoutUntil!.difference(DateTime.now()).inMinutes + 1;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cuenta bloqueada temporalmente. Intenta de nuevo en $remainingMinutes minuto(s).'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // Si el bloqueo expiró, resetear intentos
    if (_lockoutUntil != null && DateTime.now().isAfter(_lockoutUntil!)) {
      setState(() {
        _lockoutUntil = null;
        _failedAttempts = 0;
      });
    }

    try {
      setState(() => _isLoading = true);

      final user = await _storageService.login(
        _controladorUsuario.text.trim(),
        _controladorClave.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (user == null) {
        _handleFailedLogin('No fue posible iniciar sesión. Verifica las credenciales.');
        return;
      }

      // Login exitoso - resetear intentos
      setState(() {
        _failedAttempts = 0;
        _lockoutUntil = null;
      });

      // Registrar acceso al sistema
      try {
        final ipAddress = _getClientIP();
        final navegador = _getBrowserInfo();
        final sistemaOperativo = _getOSInfo();
        
        debugPrint('🔐 Registrando acceso - Usuario: ${user.nombre} ${user.apellido}');
        debugPrint('📍 IP: $ipAddress, Navegador: $navegador, SO: $sistemaOperativo');
        
        final logId = await AccessLogService.logLogin(
          usuario: user,
          ipAddress: ipAddress,
          navegador: navegador,
          sistemaOperativo: sistemaOperativo,
        );
        
        // Guardar el ID del log para usarlo al cerrar sesión
        if (logId != null) {
          await _storageService.saveAccessLogId(logId);
          debugPrint('✅ Acceso registrado con ID: $logId');
        } else {
          debugPrint('⚠️ No se pudo obtener ID del log de acceso');
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Error al registrar acceso: $e');
        debugPrint('Stack trace: $stackTrace');
        // No bloqueamos el login si falla el registro
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
      
      String errorMessage = 'Error iniciando sesión';
      
      // Detectar error de usuario inactivo
      if (e.toString().contains('Usuario inactivo') || e.toString().contains('403')) {
        errorMessage = 'Tu cuenta ha sido desactivada. Contacta al administrador.';
      } else if (e.toString().contains('Credenciales incorrectas') || e.toString().contains('401')) {
        errorMessage = 'Credenciales incorrectas. Verifica tu email y contraseña.';
      } else {
        errorMessage = 'Error iniciando sesión: $e';
      }
      
      _handleFailedLogin(errorMessage);
    }
  }

  void _handleFailedLogin(String errorMessage) {
    setState(() {
      _failedAttempts++;
      
      if (_failedAttempts >= _maxLoginAttempts) {
        _lockoutUntil = DateTime.now().add(_lockoutDuration);
        errorMessage = '⚠️ Demasiados intentos fallidos. Cuenta bloqueada por ${_lockoutDuration.inMinutes} minutos.';
      } else {
        final remainingAttempts = _maxLoginAttempts - _failedAttempts;
        errorMessage = '$errorMessage\nIntentos restantes: $remainingAttempts';
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: _failedAttempts >= _maxLoginAttempts ? Colors.red : Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
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
                          label: 'Correo electrónico',
                          child: TextFormField(
                            controller: _controladorUsuario,
                            decoration: InputDecoration(
                              labelText: 'Correo electrónico',
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