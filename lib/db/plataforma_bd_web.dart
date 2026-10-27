// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/db/plataforma_bd_web.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Configuración de SQLite para cuando la app corre en el navegador.
// ============================================================

import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'
    show databaseFactoryFfiWebNoWebWorker;

/// En web SQLite corre con WebAssembly y los datos quedan en IndexedDB.
/// Uso la versión sin web worker porque con el worker me fallaba en algunos navegadores.
Future<void> configurarBaseDeDatos() async {
  databaseFactory = databaseFactoryFfiWebNoWebWorker;
}

// en web no puedo usar dart:io, así que devuelvo el nombre directo
String nombrePlataforma() => 'Web';
