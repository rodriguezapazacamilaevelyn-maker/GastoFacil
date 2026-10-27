// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/db/plataforma_bd_nativa.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Configuración de SQLite para celular y computadora.
// ============================================================

import 'dart:io';

import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

/// En el celular sqflite ya funciona solo; en escritorio tengo que activar FFI.
Future<void> configurarBaseDeDatos() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // inicio FFI y cambio la fábrica global para que sqflite use la de escritorio
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

/// Lo uso en la pantalla "Acerca de" para mostrar en qué plataforma está.
String nombrePlataforma() {
  if (Platform.isAndroid) return 'Android';
  if (Platform.isIOS) return 'iOS';
  if (Platform.isWindows) return 'Windows';
  if (Platform.isLinux) return 'Linux';
  if (Platform.isMacOS) return 'macOS';
  return 'Otra';
}
