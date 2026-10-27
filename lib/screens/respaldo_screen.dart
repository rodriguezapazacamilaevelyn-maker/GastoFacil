// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/screens/respaldo_screen.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Pantalla para sacar una copia de los datos y restaurarla.
// ============================================================

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../services/respaldo_service.dart';
import '../utils/formato.dart';
import '../utils/tema.dart';
import '../widgets/tarjetas.dart';

/// Desde aquí el usuario crea una copia nueva o vuelve a una anterior.
class RespaldoScreen extends StatefulWidget {
  const RespaldoScreen({super.key});

  @override
  State<RespaldoScreen> createState() => _RespaldoScreenState();
}

class _RespaldoScreenState extends State<RespaldoScreen> {
  List<File> _copias = [];
  String _carpeta = '';
  bool _trabajando = false; // mientras está en true desactivo los botones

  @override
  void initState() {
    super.initState();
    // en web no hay carpetas de archivos, así que ni intento cargar
    if (!kIsWeb) _cargar();
  }

  Future<void> _cargar() async {
    try {
      final carpeta = await RespaldoService.carpetaRespaldos();
      if (mounted) setState(() => _carpeta = carpeta.path);
      final copias = await RespaldoService.listarRespaldos();
      if (!mounted) return;
      setState(() => _copias = copias);
    } catch (e) {
      // por ejemplo si no hay permiso para la carpeta
      _avisar('No se pudo acceder a la carpeta de respaldos: $e', error: true);
    }
  }

  // muestro el SnackBar abajo; si es error lo pongo en rojo
  void _avisar(String texto, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? TemaApp.gasto : null,
      content: Text(texto),
    ));
  }

  Future<void> _crear() async {
    setState(() => _trabajando = true);
    try {
      final archivo = await RespaldoService.crearRespaldo();
      _avisar('Copia creada: ${_nombre(archivo)}');
      await _cargar(); // recargo para que aparezca la copia nueva en la lista
    } catch (e) {
      _avisar('No se pudo crear la copia: $e', error: true);
    } finally {
      // el finally corre siempre, haya error o no, así el botón vuelve a activarse
      if (mounted) setState(() => _trabajando = false);
    }
  }

  /// Como restaurar borra todo lo actual, primero pido confirmación.
  Future<void> _restaurar(File archivo) async {
    // showDialog devuelve lo que paso en Navigator.pop (true o false)
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar copia'),
        content: Text('Se reemplazarán TODOS los datos actuales por los de '
            '"${_nombre(archivo)}". ¿Deseas continuar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restaurar')),
        ],
      ),
    );
    // uso != true porque si cierra tocando afuera llega null
    if (ok != true) return;
    setState(() => _trabajando = true);
    try {
      await RespaldoService.restaurarRespaldo(archivo);
      _avisar('Datos restaurados correctamente');
    } on FormatException catch (e) {
      // este es el error que lanzo yo cuando el archivo no sirve, ya trae buen mensaje
      _avisar(e.message, error: true);
    } catch (e) {
      _avisar('No se pudo restaurar la copia: $e', error: true);
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  // me quedo solo con el nombre del archivo, sin toda la ruta
  String _nombre(File f) => f.uri.pathSegments.last;

  @override
  Widget build(BuildContext context) {
    // en web solo explico que la copia está en las versiones de Android y Windows
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Copia de respaldo')),
        body: const MensajeVacio(
          icono: Icons.cloud_off_outlined,
          texto: 'En la versión web los datos se guardan en el navegador.\n'
              'La copia de respaldo en archivo está disponible en la app '
              'de Android y de Windows.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Copia de respaldo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TarjetaSeccion(
            titulo: 'Proteger mis datos',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Crea una copia de todas tus transacciones, categorías y '
                  'presupuestos. Si cambias de celular o borras la app, '
                  'podrás recuperarlos restaurando la copia.',
                  style: TextStyle(color: TemaApp.textoSuave),
                ),
                const SizedBox(height: 12),
                // con onPressed en null el botón se desactiva mientras trabaja
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  onPressed: _trabajando ? null : _crear,
                  icon: _trabajando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.backup),
                  label: const Text('Crear copia de respaldo'),
                ),
                const SizedBox(height: 10),
                const Text('Carpeta de las copias:',
                    style: TextStyle(fontSize: 12)),
                // SelectableText para que puedan copiar la ruta
                SelectableText(_carpeta,
                    style: const TextStyle(
                        fontSize: 12, color: TemaApp.textoSuave)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TarjetaSeccion(
            titulo: 'Copias guardadas (${_copias.length})',
            child: _copias.isEmpty
                ? const MensajeVacio(
                    icono: Icons.cloud_off_outlined,
                    texto: 'Todavía no hay copias de respaldo.')
                : Column(
                    children: [
                      for (final f in _copias)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.description_outlined,
                              color: TemaApp.primario),
                          title: Text(_nombre(f),
                              style: const TextStyle(fontSize: 13)),
                          // fecha del archivo y su tamaño pasado a KB
                          subtitle: Text(
                              '${formatoFecha(f.lastModifiedSync())} · '
                              '${(f.lengthSync() / 1024).toStringAsFixed(1)} KB'),
                          trailing: TextButton(
                            onPressed:
                                _trabajando ? null : () => _restaurar(f),
                            child: const Text('Restaurar'),
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
