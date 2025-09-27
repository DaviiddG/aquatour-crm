import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:aquatour/login_screen.dart';
import 'package:aquatour/services/storage_service.dart';
import 'dart:html' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar variables de entorno
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Variables de entorno cargadas desde .env');
  } catch (e) {
    print('⚠️ Error cargando .env, intentando .env.local: $e');
    try {
      await dotenv.load(fileName: ".env.local");
      print('✅ Variables de entorno cargadas desde .env.local');
    } catch (e2) {
      print('⚠️ Error cargando .env.local, usando valores por defecto: $e2');
    }
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
      home: const LoginScreen(),
      routes: {
        // No hay ruta de registro
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
