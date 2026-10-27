// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/main.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Aquí arranca la app, preparo la base y el idioma antes de abrirla.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'db/plataforma_bd.dart';
import 'screens/main_shell.dart';
import 'utils/tema.dart';

/// main es async porque antes de mostrar nada tengo que esperar a la BD y a las fechas.
Future<void> main() async {
  // sin esta línea los plugins (como SQLite) fallan si los llamo antes de runApp
  WidgetsFlutterBinding.ensureInitialized();

  // esto viene del import condicional, cada plataforma configura SQLite a su manera
  await configurarBaseDeDatos();

  // cargo los nombres de meses y días en español para DateFormat
  await initializeDateFormatting('es');

  runApp(const GastoFacilApp());
}

/// Widget principal, acá pongo el tema, el idioma y la pantalla con la barra de abajo.
class GastoFacilApp extends StatelessWidget {
  const GastoFacilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GastoFácil',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.claro(),
      // con esto el calendario y los botones del sistema salen en español
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      // los delegates son los que traen las traducciones de Material y Cupertino
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainShell(),
    );
  }
}
