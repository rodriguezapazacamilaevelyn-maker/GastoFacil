// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/screens/transaccion_form_screen.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : El formulario donde se registra o se edita un ingreso o gasto.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/database_helper.dart';
import '../models/categoria.dart';
import '../models/transaccion.dart';
import '../services/finanzas_service.dart';
import '../utils/formato.dart';
import '../utils/tema.dart';
import '../widgets/tarjetas.dart';
import 'categorias_screen.dart';

/// Uso la misma pantalla para nuevo y para editar: si me llega
/// [transaccion] es edición y también se puede eliminar.
class TransaccionFormScreen extends StatefulWidget {
  final Transaccion? transaccion; // si es null es un registro nuevo
  final String tipoInicial;

  const TransaccionFormScreen({
    super.key,
    this.transaccion,
    this.tipoInicial = TipoMovimiento.gasto,
  });

  @override
  State<TransaccionFormScreen> createState() => _TransaccionFormScreenState();
}

class _TransaccionFormScreenState extends State<TransaccionFormScreen> {
  // con esta key puedo validar todos los campos del Form de una sola vez
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _monto;
  late final TextEditingController _descripcion;

  late String _tipo;
  late DateTime _fecha;
  int? _idCategoria;
  List<Categoria> _categorias = [];
  bool _guardando = false;

  bool get _esEdicion => widget.transaccion != null;

  @override
  void initState() {
    super.initState();
    final t = widget.transaccion;
    // si estoy editando relleno los campos con lo que ya tenía, si no quedan vacíos
    _tipo = t?.tipo ?? widget.tipoInicial;
    _fecha = t?.fecha ?? DateTime.now();
    _idCategoria = t?.idCategoria;
    _titulo = TextEditingController(text: t?.titulo ?? '');
    _monto = TextEditingController(
        text: t == null ? '' : t.monto.toStringAsFixed(2));
    _descripcion = TextEditingController(text: t?.descripcion ?? '');
    _cargarCategorias();
  }

  @override
  void dispose() {
    // los controllers hay que liberarlos o se queda memoria ocupada
    _titulo.dispose();
    _monto.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    final lista = await DatabaseHelper.instancia.obtenerCategorias();
    // como hubo un await, reviso que la pantalla siga abierta antes del setState
    if (!mounted) return;
    setState(() {
      _categorias = lista;
      _ajustarCategoria();
    });
  }

  // en el desplegable solo muestro las categorías del tipo elegido
  List<Categoria> get _categoriasDelTipo =>
      _categorias.where((c) => c.tipo == _tipo).toList();

  /// Si cambian de gasto a ingreso, la categoría anterior ya no sirve
  /// y pongo la primera que sí corresponda.
  void _ajustarCategoria() {
    final lista = _categoriasDelTipo;
    if (!lista.any((c) => c.id == _idCategoria)) {
      _idCategoria = lista.isEmpty ? null : lista.first.id;
    }
  }

  Future<void> _elegirFecha() async {
    // el calendario deja elegir desde 2020 hasta un año adelante
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Fecha de la transacción',
    );
    // si cancela, elegida llega null y dejo la fecha como estaba
    if (elegida != null) setState(() => _fecha = elegida);
  }

  /// Valido, guardo en la BD y si es gasto reviso si se pasó del presupuesto.
  Future<void> _guardar() async {
    // validate() corre todos los validator; si alguno falla muestra el error y no sigo
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    final descripcion = _descripcion.text.trim();
    final transaccion = Transaccion(
      id: widget.transaccion?.id,
      tipo: _tipo,
      titulo: _titulo.text.trim(),
      // aquí ya pasó el validator, por eso uso ! sin miedo
      monto: leerMonto(_monto.text)!,
      fecha: _fecha,
      // si la descripción está vacía la guardo como null
      descripcion: descripcion.isEmpty ? null : descripcion,
      idCategoria: _idCategoria!,
    );

    // agarro el messenger y el navigator antes del await, porque después
    // del pop el context ya no sirve y el SnackBar sale en la pantalla anterior
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    try {
      if (_esEdicion) {
        await DatabaseHelper.instancia.actualizarTransaccion(transaccion);
      } else {
        await DatabaseHelper.instancia.insertarTransaccion(transaccion);
      }
      // solo los gastos pueden pasar el presupuesto, los ingresos no
      if (transaccion.esGasto) {
        await _revisarPresupuesto(transaccion);
      }
      // guardo primero en la BD y recién después aviso con el SnackBar
      mensajero.showSnackBar(avisoExito(_esEdicion
          ? 'Cambios guardados: "${transaccion.titulo}" se actualizó'
          : (transaccion.esIngreso
              ? 'Ingreso agregado: ${formatoMoneda(transaccion.monto)}'
              : 'Gasto agregado: ${formatoMoneda(transaccion.monto)}')));
      navegador.pop(true);
    } catch (e) {
      // si hubo error muestro el mensaje en vez de cerrar, así no pierde lo que escribió
      if (!mounted) return;
      setState(() => _guardando = false);
      mensajero.showSnackBar(SnackBar(
        backgroundColor: TemaApp.gasto,
        content: Text('No se pudo guardar: $e'),
      ));
    }
  }

  /// Después de guardar un gasto, si pasó o está cerca del límite
  /// (del mes o de su categoría) le muestro un diálogo de alerta.
  Future<void> _revisarPresupuesto(Transaccion t) async {
    // uso el mes de la fecha del gasto, no necesariamente el mes actual
    final reporte = await FinanzasService.generarReporte(t.fecha);
    // de las categorías me quedo solo con la del gasto, las otras no vienen al caso
    final alertas = FinanzasService.calcularAlertas(
      reporte.presupuesto,
      reporte.presupuestosCategoria
          .where((c) => c.presupuesto.idCategoria == t.idCategoria)
          .toList(),
    );
    if (alertas.isEmpty || !mounted) return;
    // si alguna es de excedido, todo el diálogo sale en rojo
    final excedido = alertas.any((a) => a.excedido);
    final color = excedido ? TemaApp.gasto : TemaApp.alerta;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: color, size: 48),
        title: Text(excedido
            ? '¡Te pasaste de tu presupuesto!'
            : 'Estás cerca de tu límite',
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        content: Column(
          // min para que el diálogo no ocupe toda la altura
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final a in alertas)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(a.mensaje, textAlign: TextAlign.center),
              ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: color),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminar() async {
    // primero pregunto, porque borrar no tiene vuelta atrás
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar transacción'),
        content: Text(
            '¿Seguro que deseas eliminar "${widget.transaccion!.titulo}"? '
            'Esta acción no se puede deshacer.'),
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
    if (confirmar != true || !mounted) return;
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    await DatabaseHelper.instancia
        .eliminarTransaccion(widget.transaccion!.id!);
    mensajero.showSnackBar(avisoExito(
        'Transacción "${widget.transaccion!.titulo}" eliminada',
        icono: Icons.delete_outline));
    navegador.pop(true);
  }

  Future<void> _gestionarCategorias() async {
    // espero a que vuelva de la pantalla de categorías
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const CategoriasScreen()));
    _cargarCategorias(); // recargo por si creó una categoría nueva
  }

  @override
  Widget build(BuildContext context) {
    // el color del botón guardar cambia según sea ingreso o gasto
    final esIngreso = _tipo == TipoMovimiento.ingreso;
    final colorTipo = esIngreso ? TemaApp.ingreso : TemaApp.gasto;

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar transacción' : 'Nueva transacción'),
        actions: [
          // el botón de borrar solo aparece cuando estoy editando
          if (_esEdicion)
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: _eliminar,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---- Selector de tipo (Ingreso / Gasto) ----
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: TipoMovimiento.ingreso,
                    label: Text('Ingreso'),
                    icon: Icon(Icons.arrow_upward)),
                ButtonSegment(
                    value: TipoMovimiento.gasto,
                    label: Text('Gasto'),
                    icon: Icon(Icons.arrow_downward)),
              ],
              selected: {_tipo},
              // al cambiar el tipo también corrijo la categoría elegida
              onSelectionChanged: (seleccion) => setState(() {
                _tipo = seleccion.first;
                _ajustarCategoria();
              }),
            ),
            const SizedBox(height: 20),

            // ---- Título ----
            TextFormField(
              controller: _titulo,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 60,
              decoration: TemaApp.campo('Título', Icons.edit_outlined,
                  ayuda: 'Ejemplo: Almuerzo, Pasaje, Sueldo'),
              // con trim no deja pasar un título de puros espacios
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingrese un título'
                  : null,
            ),
            const SizedBox(height: 8),

            // ---- Monto ----
            TextFormField(
              controller: _monto,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              // el filtro no deja escribir letras, solo números, punto y coma
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
              ],
              decoration: TemaApp.campo('Monto', Icons.payments_outlined,
                  prefijo: 'Bs '),
              validator: validarMonto,
            ),
            const SizedBox(height: 16),

            // ---- Categoría ----
            // le cambio la key con el tipo para que el dropdown se reconstruya
            // de cero, si no se quedaba con el valor viejo
            DropdownButtonFormField<int>(
              key: ValueKey('categoria_${_tipo}_${_categorias.length}'),
              // solo pongo el valor si está en la lista, si no el dropdown da error
              initialValue: _categoriasDelTipo.any((c) => c.id == _idCategoria)
                  ? _idCategoria
                  : null,
              isExpanded: true,
              decoration: TemaApp.campo('Categoría', Icons.category_outlined),
              items: [
                for (final c in _categoriasDelTipo)
                  DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        Icon(TemaApp.icono(c.icono),
                            color: TemaApp.colorCategoria(c.color), size: 20),
                        const SizedBox(width: 10),
                        Text(c.nombre),
                      ],
                    ),
                  ),
              ],
              onChanged: (id) => setState(() => _idCategoria = id),
              validator: (v) => v == null ? 'Seleccione una categoría' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _gestionarCategorias,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva categoría'),
              ),
            ),

            // ---- Fecha ----
            // uso InputDecorator para que la fecha se vea igual que los otros campos
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _elegirFecha,
              child: InputDecorator(
                decoration:
                    TemaApp.campo('Fecha', Icons.calendar_today_outlined),
                child: Text(formatoFecha(_fecha),
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),

            // ---- Descripción (opcional) ----
            TextFormField(
              controller: _descripcion,
              maxLines: 2,
              maxLength: 120,
              decoration: TemaApp.campo(
                  'Descripción (opcional)', Icons.notes_outlined),
            ),
            const SizedBox(height: 16),

            // ---- Botón guardar ----
            // mientras guarda lo desactivo y muestro el circulito, así no lo tocan dos veces
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colorTipo,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check),
              label: Text(_esEdicion
                  ? 'Guardar cambios'
                  : (esIngreso ? 'Guardar ingreso' : 'Guardar gasto')),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
