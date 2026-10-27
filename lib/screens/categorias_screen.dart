// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/screens/categorias_screen.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Pantalla para ver, crear y borrar categorías de ingresos y gastos.
// ============================================================

import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/categoria.dart';
import '../utils/tema.dart';
import '../widgets/tarjetas.dart';

/// Separé las categorías en dos pestañas, Gastos e Ingresos. Aquí se crean
/// nuevas y se borran las personalizadas que no se estén usando.
class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  List<Categoria> _categorias = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // traigo las de los dos tipos juntas y después las separo por pestaña
  Future<void> _cargar() async {
    final lista = await DatabaseHelper.instancia.obtenerCategorias();
    if (!mounted) return;
    setState(() {
      _categorias = lista;
      _cargando = false;
    });
  }

  /// Abro el diálogo y, si el nombre no se repite, guardo la categoría.
  Future<void> _agregar(String tipoInicial) async {
    // el diálogo me devuelve la Categoria armada o null si canceló
    final nueva = await showDialog<Categoria>(
      context: context,
      builder: (_) => _DialogoCategoria(tipoInicial: tipoInicial),
    );
    if (nueva == null || !mounted) return;
    final mensajero = ScaffoldMessenger.of(context);

    // comparo en minúsculas para que "Comida" y "comida" cuenten como la misma
    final repetida = _categorias.any((c) =>
        c.tipo == nueva.tipo &&
        c.nombre.toLowerCase() == nueva.nombre.toLowerCase());
    if (repetida) {
      mensajero.showSnackBar(SnackBar(
          backgroundColor: TemaApp.gasto,
          content: Text('Ya existe la categoría "${nueva.nombre}".')));
      return;
    }
    try {
      await DatabaseHelper.instancia.insertarCategoria(nueva);
      mensajero.showSnackBar(
          SnackBar(content: Text('Categoría "${nueva.nombre}" creada')));
      _cargar();
    } catch (e) {
      // por si igual choca con el UNIQUE de la tabla
      mensajero.showSnackBar(SnackBar(
          backgroundColor: TemaApp.gasto,
          content: Text('No se pudo crear la categoría: $e')));
    }
  }

  Future<void> _eliminar(Categoria c) async {
    final mensajero = ScaffoldMessenger.of(context);
    // antes de borrar cuento cuántos movimientos la usan
    final usos =
        await DatabaseHelper.instancia.contarTransaccionesDeCategoria(c.id!);
    if (usos > 0) {
      // si la borro esos movimientos quedarían sin categoría, así que no dejo
      mensajero.showSnackBar(SnackBar(
          content: Text('No se puede eliminar "${c.nombre}": '
              'tiene $usos transacción(es) asociada(s).')));
      return;
    }
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar la categoría "${c.nombre}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    await DatabaseHelper.instancia.eliminarCategoria(c.id!);
    _cargar();
  }

  // arma la lista de una pestaña filtrando por el tipo
  Widget _lista(String tipo) {
    final lista = _categorias.where((c) => c.tipo == tipo).toList();
    if (lista.isEmpty) {
      return const MensajeVacio(
          icono: Icons.category_outlined, texto: 'No hay categorías.');
    }
    return ListView.separated(
      // espacio abajo para que el botón flotante no tape la última
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: lista.length,
      separatorBuilder: (context, i) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final c = lista[i];
        final color = TemaApp.colorCategoria(c.color);
        return Container(
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              // el fondo es el mismo color pero bien transparente
              backgroundColor: color.withAlpha(40),
              child: Icon(TemaApp.icono(c.icono), color: color),
            ),
            title: Text(c.nombre,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(c.predefinida ? 'Predefinida' : 'Personalizada'),
            // a las predefinidas les pongo un candado en vez del botón de borrar
            trailing: c.predefinida
                ? const Icon(Icons.lock_outline,
                    size: 18, color: TemaApp.textoSuave)
                : IconButton(
                    tooltip: 'Eliminar',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _eliminar(c),
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      // el Builder es para tener un context que esté debajo del DefaultTabController
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Categorías'),
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(text: 'Gastos', icon: Icon(Icons.arrow_downward)),
                Tab(text: 'Ingresos', icon: Icon(Icons.arrow_upward)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              // veo en qué pestaña está para abrir el diálogo con ese tipo ya elegido
              final pestana = DefaultTabController.of(context).index;
              _agregar(pestana == 0
                  ? TipoMovimiento.gasto
                  : TipoMovimiento.ingreso);
            },
            icon: const Icon(Icons.add),
            label: const Text('Nueva categoría'),
          ),
          body: _cargando
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(children: [
                  _lista(TipoMovimiento.gasto),
                  _lista(TipoMovimiento.ingreso),
                ]),
        );
      }),
    );
  }
}

/// Diálogo para crear una categoría eligiendo nombre, tipo, color e ícono.
class _DialogoCategoria extends StatefulWidget {
  final String tipoInicial;
  const _DialogoCategoria({required this.tipoInicial});

  @override
  State<_DialogoCategoria> createState() => _DialogoCategoriaState();
}

class _DialogoCategoriaState extends State<_DialogoCategoria> {
  final _nombre = TextEditingController();
  // late me deja usar widget.tipoInicial al declarar la variable
  late String _tipo = widget.tipoInicial;
  int _color = 0;
  String _icono = 'otros';
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  // valido a mano porque aquí uso TextField y no un Form
  void _aceptar() {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'Ingrese un nombre');
      return;
    }
    if (nombre.length > 30) {
      setState(() => _error = 'Máximo 30 caracteres');
      return;
    }
    // cierro el diálogo devolviendo la categoría nueva
    Navigator.pop(
      context,
      Categoria(nombre: nombre, tipo: _tipo, icono: _icono, color: _color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva categoría'),
      // con el scroll no se desborda cuando sale el teclado en celulares chicos
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nombre,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nombre',
                // si _error es null no se muestra nada
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: TipoMovimiento.gasto, label: Text('Gasto')),
                ButtonSegment(
                    value: TipoMovimiento.ingreso, label: Text('Ingreso')),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
            const SizedBox(height: 14),
            const Text('Color'),
            const SizedBox(height: 6),
            // Wrap pasa los círculos a otra fila si no entran
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < TemaApp.paleta.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _color = i),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: TemaApp.paleta[i],
                      // al color elegido le pongo un check encima
                      child: _color == i
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const Text('Ícono'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // recorro el Map de íconos; e.key es la clave que se guarda en la BD
                for (final e in TemaApp.iconos.entries)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _icono = e.key),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      // el ícono elegido se resalta con el color que escogió
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: _icono == e.key
                            ? TemaApp.colorCategoria(_color).withAlpha(50)
                            : null,
                      ),
                      child: Icon(e.value,
                          color: _icono == e.key
                              ? TemaApp.colorCategoria(_color)
                              : TemaApp.textoSuave),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(onPressed: _aceptar, child: const Text('Guardar')),
      ],
    );
  }
}
