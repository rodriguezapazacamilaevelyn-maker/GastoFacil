// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/db/plataforma_bd.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Escoge cómo configurar SQLite según dónde corre la app.
// ============================================================

// uso import condicional: al compilar Dart se queda solo con uno de los dos.
// si existe js_interop es que estoy en el navegador y toma el archivo web,
// si no, toma el nativo (Android, iOS, Windows, Linux, macOS)
export 'plataforma_bd_nativa.dart'
    if (dart.library.js_interop) 'plataforma_bd_web.dart';
