// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/services/respaldo_service.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Guardo y restauro las copias de respaldo en archivos JSON.
// ============================================================

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../db/database_helper.dart';

/// Las copias quedan en un JSON dentro del dispositivo, no se suben a internet.
/// El usuario después puede copiar el archivo donde quiera.
class RespaldoService {
  RespaldoService._();

  // con esta marca reviso al restaurar que el archivo sea de mi app
  static const String _marcaApp = 'GastoFacil';
  static const String _nombreCarpeta = 'GastoFacil_respaldos';

  /// En Android uso la carpeta externa de la app, que se ve conectando por USB;
  /// en Windows termina en Documentos/GastoFacil_respaldos.
  static Future<Directory> carpetaRespaldos() async {
    Directory? base;
    if (Platform.isAndroid) {
      base = await getExternalStorageDirectory();
    }
    // si no es Android o no hay almacenamiento externo, uso Documentos
    base ??= await getApplicationDocumentsDirectory();
    final carpeta = Directory(join(base.path, _nombreCarpeta));
    if (!await carpeta.exists()) {
      // recursive crea también las carpetas de arriba si faltan
      await carpeta.create(recursive: true);
    }
    return carpeta;
  }

  /// El archivo se llama "gastofacil_respaldo_AAAAMMDD_HHMMSS.json".
  static Future<File> crearRespaldo() async {
    final datos = await DatabaseHelper.instancia.exportarDatos();
    final ahora = DateTime.now();
    // con el spread (...) meto las tablas junto a los datos de control
    final contenido = {
      'app': _marcaApp,
      'version_bd': 2,
      'fecha_respaldo': ahora.toIso8601String(),
      ...datos,
    };

    // función chiquita para poner el cero adelante (5 -> "05")
    String dos(int n) => n.toString().padLeft(2, '0');
    final nombre = 'gastofacil_respaldo_'
        '${ahora.year}${dos(ahora.month)}${dos(ahora.day)}_'
        '${dos(ahora.hour)}${dos(ahora.minute)}${dos(ahora.second)}.json';

    final carpeta = await carpetaRespaldos();
    final archivo = File(join(carpeta.path, nombre));
    // con indentación el JSON se puede leer si alguien lo abre
    const codificador = JsonEncoder.withIndent('  ');
    return archivo.writeAsString(codificador.convert(contenido));
  }

  /// Las ordeno de la más nueva a la más vieja.
  static Future<List<File>> listarRespaldos() async {
    final carpeta = await carpetaRespaldos();
    // me quedo solo con los archivos .json, sin carpetas
    final archivos = carpeta
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.json'))
        .toList();
    // como el nombre lleva la fecha, al ordenar por nombre queda por fecha
    archivos.sort((a, b) => b.path.compareTo(a.path));
    return archivos;
  }

  /// Antes de reemplazar nada reviso que el archivo tenga la marca y las tablas.
  static Future<void> restaurarRespaldo(File archivo) async {
    final datos = await _leerJson(archivo);
    final valido = datos['app'] == _marcaApp &&
        datos['categorias'] is List &&
        datos['transacciones'] is List &&
        datos['presupuestos'] is List;
    if (!valido) {
      throw const FormatException(
          'El archivo no es una copia de respaldo de GastoFácil.');
    }
    await DatabaseHelper.instancia.importarDatos(datos);
  }

  static Future<Map<String, dynamic>> _leerJson(File archivo) async {
    try {
      final contenido = jsonDecode(await archivo.readAsString());
      if (contenido is Map<String, dynamic>) return contenido;
    } catch (_) {
      // no hago nada aquí, el error entendible lo lanzo abajo
    }
    // llega aquí si el JSON estaba roto o no era un objeto
    throw const FormatException('El archivo está dañado o no es válido.');
  }
}
