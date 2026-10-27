// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/screens/historial_screen.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Lista de todos los movimientos con filtros por tipo, categoría y fechas.
// ============================================================

import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/categoria.dart';
import '../models/transaccion.dart';
import '../services/finanzas_service.dart';
import '../utils/formato.dart';
import '../utils/tema.dart';
import '../widgets/item_transaccion.dart';
import '../widgets/tarjetas.dart';
import 'transaccion_form_screen.dart';

/// Todos los movimientos ordenados por fecha. Si toco uno se abre para
/// editar y si lo deslizo a la izquierda se elimina.
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<Transaccion> _lista = [];
  List<Categoria> _categorias = [];
  bool _cargando = true;
  String? _error;

  // cada filtro en null quiere decir que no está aplicado
  String? _filtroTipo;
  int? _filtroCategoria;
  DateTimeRange? _filtroFechas;

  // con esto sé si mostrar el botón de quitar filtros
  bool get _hayFiltros =>
      _filtroTipo != null || _filtroCategoria != null || _filtroFechas != null;

  @override
  void initState() {
    super.initState();
    // escucho los cambios de la base para recargar la lista sola
    DatabaseHelper.cambios.addListener(_cargar);
    _cargar();
  }

  @override
  void dispose() {
    DatabaseHelper.cambios.removeListener(_cargar);
    super.dispose();
  }

  /// Vuelvo a consultar pasándole a la BD los filtros que estén puestos.
  Future<void> _cargar() async {
    try {
      final db = DatabaseHelper.instancia;
      // los que están en null el helper simplemente no los agrega al WHERE
      final lista = await db.obtenerTransacciones(
        tipo: _filtroTipo,
        idCategoria: _filtroCategoria,
        desde: _filtroFechas?.start,
        hasta: _filtroFechas?.end,
      );
      final categorias = await db.obtenerCategorias();
      if (!mounted) return;
      setState(() {
        _lista = lista;
        _categorias = categorias;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo cargar el historial. ($e)';
      });
    }
  }

  void _quitarFiltros() {
    setState(() {
      _filtroTipo = null;
      _filtroCategoria = null;
      _filtroFechas = null;
    });
    _cargar();
  }

  /// Abro una hoja desde abajo con todas las categorías para elegir una.
  Future<void> _elegirCategoria() async {
    // uso -1 para "todas" porque null ya significa que cerró sin elegir
    final elegido = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          // shrinkWrap para que la hoja solo ocupe lo que necesita
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('Todas las categorías'),
              onTap: () => Navigator.pop(ctx, -1),
            ),
            for (final c in _categorias)
              ListTile(
                leading: Icon(TemaApp.icono(c.icono),
                    color: TemaApp.colorCategoria(c.color)),
                title: Text(c.nombre),
                subtitle: Text(c.tipo == TipoMovimiento.ingreso
                    ? 'Ingreso'
                    : 'Gasto'),
                // marco la que ya está filtrada
                selected: c.id == _filtroCategoria,
                onTap: () => Navigator.pop(ctx, c.id),
              ),
          ],
        ),
      ),
    );
    if (elegido == null) return;
    setState(() => _filtroCategoria = elegido == -1 ? null : elegido);
    _cargar();
  }

  Future<void> _elegirFechas() async {
    // el selector de rango me devuelve inicio y fin juntos
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _filtroFechas,
      helpText: 'Rango de fechas',
    );
    if (rango == null) return;
    setState(() => _filtroFechas = rango);
    _cargar();
  }

  // tipo en null es "Todos"
  void _cambiarTipo(String? tipo) {
    setState(() {
      _filtroTipo = tipo;
      // si tenía filtrada una categoría de gasto y elige ingresos, quito ese filtro
      // porque si no la lista saldría vacía siempre
      final cat = _categorias.where((c) => c.id == _filtroCategoria);
      if (tipo != null && cat.isNotEmpty && cat.first.tipo != tipo) {
        _filtroCategoria = null;
      }
    });
    _cargar();
  }

  /// Le pregunto antes de borrar; si cierra el diálogo sin elegir lo tomo como no.
  Future<bool> _confirmarEliminar(Transaccion t) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar transacción'),
        content: Text('¿Eliminar "${t.titulo}" por '
            '${formatoMoneda(t.monto)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: TemaApp.gasto),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    return r ?? false;
  }

  Future<void> _eliminar(Transaccion t) async {
    // el Dismissible necesita que lo saque de la lista enseguida, si no tira error;
    // después lo borro de la BD
    setState(() => _lista.remove(t));
    final mensajero = ScaffoldMessenger.of(context);
    await DatabaseHelper.instancia.eliminarTransaccion(t.id!);
    mensajero.showSnackBar(avisoExito('"${t.titulo}" eliminada',
        icono: Icons.delete_outline));
  }

  // sin parámetro es nuevo; con t es para editar ese movimiento
  void _abrirFormulario([Transaccion? t]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransaccionFormScreen(
          transaccion: t,
          tipoInicial: t?.tipo ?? TipoMovimiento.gasto,
        ),
      ),
    );
  }

  // el chip muestra el nombre de la categoría filtrada o solo "Categoría"
  String get _textoCategoria {
    final cat = _categorias.where((c) => c.id == _filtroCategoria);
    return cat.isEmpty ? 'Categoría' : cat.first.nombre;
  }

  String get _textoFechas {
    final r = _filtroFechas;
    if (r == null) return 'Fechas';
    return '${formatoFecha(r.start)} - ${formatoFecha(r.end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          if (_hayFiltros)
            IconButton(
              tooltip: 'Quitar filtros',
              icon: const Icon(Icons.filter_alt_off_outlined),
              onPressed: _quitarFiltros,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Registrar transacción',
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _barraFiltros(),
          if (!_cargando && _error == null) _resumenFiltrado(),
          // la lista va en Expanded para que use el espacio que sobra en la Column
          Expanded(child: _contenidoLista()),
        ],
      ),
    );
  }

  /// Los chips de filtro van en un scroll horizontal para que entren en pantallas angostas.
  Widget _barraFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('Todos'),
              selected: _filtroTipo == null,
              onSelected: (_) => _cambiarTipo(null),
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('Ingresos'),
              selected: _filtroTipo == TipoMovimiento.ingreso,
              onSelected: (_) => _cambiarTipo(TipoMovimiento.ingreso),
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('Gastos'),
              selected: _filtroTipo == TipoMovimiento.gasto,
              onSelected: (_) => _cambiarTipo(TipoMovimiento.gasto),
            ),
            const SizedBox(width: 12),
            // si el filtro está activo pinto el chip para que se note
            ActionChip(
              avatar: const Icon(Icons.category_outlined, size: 18),
              label: Text(_textoCategoria),
              backgroundColor:
                  _filtroCategoria != null ? TemaApp.primarioClaro : null,
              onPressed: _elegirCategoria,
            ),
            const SizedBox(width: 6),
            ActionChip(
              avatar: const Icon(Icons.date_range_outlined, size: 18),
              label: Text(_textoFechas),
              backgroundColor:
                  _filtroFechas != null ? TemaApp.primarioClaro : null,
              onPressed: _elegirFechas,
            ),
          ],
        ),
      ),
    );
  }

  // arriba de la lista muestro cuántos hay y cuánto suman con los filtros puestos
  Widget _resumenFiltrado() {
    final r = FinanzasService.calcularResumen(_lista);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Text('${_lista.length} movimientos',
              style: const TextStyle(color: TemaApp.textoSuave)),
          // Spacer empuja los totales hacia la derecha
          const Spacer(),
          Text('+${formatoMoneda(r.ingresos)}',
              style: const TextStyle(
                  color: TemaApp.ingreso, fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          Text('-${formatoMoneda(r.gastos)}',
              style: const TextStyle(
                  color: TemaApp.gasto, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _contenidoLista() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return MensajeVacio(icono: Icons.error_outline, texto: _error!);
    }
    // el mensaje cambia si está vacía por los filtros o porque no hay nada todavía
    if (_lista.isEmpty) {
      return MensajeVacio(
        icono: Icons.search_off,
        texto: _hayFiltros
            ? 'No hay transacciones que coincidan con los filtros.'
            : 'Aún no hay transacciones registradas.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: _lista.length,
      separatorBuilder: (context, indice) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final t = _lista[i];
        // Dismissible permite deslizar para borrar; la key tiene que ser única
        return Dismissible(
          key: ValueKey('transaccion_${t.id}'),
          direction: DismissDirection.endToStart,
          // si confirmDismiss devuelve false, la fila vuelve a su lugar
          confirmDismiss: (_) => _confirmarEliminar(t),
          onDismissed: (_) => _eliminar(t),
          // el fondo rojo con el tacho que se ve mientras desliza
          background: Container(
            color: TemaApp.gasto,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          child: Container(
            color: Colors.white,
            child: ItemTransaccion(
                transaccion: t, onTap: () => _abrirFormulario(t)),
          ),
        );
      },
    );
  }
}
