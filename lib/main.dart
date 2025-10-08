import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:aquatour/login_screen.dart';
import 'package:aquatour/dashboard_screen.dart';
import 'package:aquatour/limited_dashboard_screen.dart';
import 'package:aquatour/services/storage_service.dart';
import 'dart:html' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar variables de entorno
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Variables de entorno cargadas desde .env');
  } catch (e) {
    print('⚠️ Error cargando .env: $e');
  }

  final bool isLocalHost = kIsWeb && (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1');
  final bool shouldLoadLocalEnv = !kReleaseMode && (isLocalHost || !kIsWeb);

  if (shouldLoadLocalEnv) {
    try {
      await dotenv.load(fileName: ".env.local", mergeWith: dotenv.env);
      print('✅ Variables de entorno cargadas/actualizadas desde .env.local');
    } catch (e) {
      print('ℹ️ .env.local no encontrado o no accesible: $e');
    }
  } else {
    print('ℹ️ Entorno de producción detectado (host: ${Uri.base.host}). Se mantiene configuración de .env');
  }

  // Inicializar servicios de API
  try {
    final storageService = StorageService();
    await storageService.initializeData();
    print('✅ Servicios de API inicializados correctamente');
  } catch (e) {
    print('⚠️ Error inicializando servicios de API: $e');
    // Forzar recarga en caso de error
    if (kIsWeb) {
      html.window.location.reload();
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color colorPrimario = Color(0xFF3D1F6E);
    const Color colorAcento = Color(0xFFfdb913);

    return MaterialApp(
      title: 'Aquatour CRM',
      theme: ThemeData(
        primaryColor: colorPrimario,
        hintColor: colorAcento,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.montserratTextTheme(Theme.of(context).textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: colorPrimario,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: colorAcento,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: colorPrimario,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: colorPrimario),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: colorAcento, width: 2.0),
          ),
          prefixIconColor: colorPrimario,
          floatingLabelStyle: const TextStyle(color: colorAcento),
        ),
      ),
      home: const _SessionGate(),
      routes: {
        // No hay ruta de registro
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  final StorageService _storageService = StorageService();
  bool _isLoading = true;
  Widget? _destination;

  @override
  void initState() {
    super.initState();
    _evaluateSession();
  }

  Future<void> _evaluateSession() async {
    final user = await _storageService.getCurrentUser();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (user != null) {
        _destination = user.esAdministrador
            ? const DashboardScreen()
            : const LimitedDashboardScreen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_destination != null) {
      return _destination!;
    }

    return const LoginScreen();
  }
}
