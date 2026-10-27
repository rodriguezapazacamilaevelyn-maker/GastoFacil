// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/screens/presupuesto_screen.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Aquí se pone el presupuesto del mes y se reparte entre categorías.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/database_helper.dart';
import '../models/categoria.dart';
import '../services/finanzas_service.dart';
import '../utils/formato.dart';
import '../utils/tema.dart';
import '../widgets/tarjetas.dart';

/// En esta pantalla el usuario define o cambia su presupuesto y ve cuánto le queda.
/// Los límites por categoría salen del total, sin pasarse de lo disponible.
class PresupuestoScreen extends StatefulWidget {
  const PresupuestoScreen({super.key});

  @override
  State<PresupuestoScreen> createState() => _PresupuestoScreenState();
}

class _PresupuestoScreenState extends State<PresupuestoScreen> {
  DateTime _mes = inicioMes(DateTime.now());
  ReporteMensual? _reporte;
  List<Categoria> _categoriasGasto = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // cuando registran un gasto en otra pestaña, aquí se ve al tiro el nuevo saldo
    DatabaseHelper.cambios.addListener(_cargar);
    _cargar();
  }

  @override
  void dispose() {
    DatabaseHelper.cambios.removeListener(_cargar);
    super.dispose();
  }

  /// Reutilizo el reporte del mes porque ya trae el presupuesto, lo gastado y las alertas.
  Future<void> _cargar() async {
    try {
      final r = await FinanzasService.generarReporte(_mes);
      // solo las de gasto, porque a un ingreso no se le pone límite
      final cats = await DatabaseHelper.instancia
          .obtenerCategorias(tipo: TipoMovimiento.gasto);
      if (!mounted) return;
      setState(() {
        _reporte = r;
        _categoriasGasto = cats;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo cargar el presupuesto. ($e)';
      });
    }
  }

  void _cambiarMes(int delta) {
    setState(() => _mes = sumarMeses(_mes, delta));
    _cargar();
  }

  /// Sirve para poner el presupuesto la primera vez o para reformularlo.
  Future<void> _establecer() async {
    final actual = _reporte?.presupuesto.montoPresupuesto;
    // le paso lo ya repartido para que el diálogo no deje bajar el total de eso
    final yaAsignado = _reporte?.distribucion.asignado ?? 0;
    final monto = await showDialog<double>(
      context: context,
      builder: (_) => _DialogoMonto(
          montoActual: actual, mes: _mes, yaAsignado: yaAsignado),
    );
    if (monto == null || !mounted) return;
    final mensajero = ScaffoldMessenger.of(context);
    await DatabaseHelper.instancia.guardarPresupuesto(periodoDe(_mes), monto);
    // el mensaje cambia si era la primera vez o si lo estaba cambiando
    mensajero.showSnackBar(avisoExito(actual == null
        ? 'Presupuesto inicial establecido: ${formatoMoneda(monto)}'
        : 'Presupuesto reformulado: ${formatoMoneda(monto)}'));
  }

  /// Para ponerle límite a una categoría o cambiar el que ya tenía.
  Future<void> _asignarCategoria({EstadoCategoria? existente}) async {
    if (_categoriasGasto.isEmpty) return;
    final distribucion = _reporte!.distribucion;
    // si no hay presupuesto total no hay de dónde repartir, entonces aviso
    if (!distribucion.existe) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: TemaApp.alerta,
          content: Text('Primero establece el presupuesto total del mes; '
              'las categorías se reparten de ese total.')));
      return;
    }
    final resultado = await showDialog<_ResultadoCategoria>(
      context: context,
      builder: (_) => _DialogoPresupuestoCategoria(
        categorias: _categoriasGasto,
        idInicial: existente?.presupuesto.idCategoria,
        montoActual: existente?.presupuesto.monto,
        sinAsignar: distribucion.sinAsignar,
        // armo un Map id -> monto para saber cuánto tiene ya cada categoría
        asignados: {
          for (final c in distribucion.categorias)
            c.presupuesto.idCategoria: c.presupuesto.monto
        },
      ),
    );
    if (resultado == null || !mounted) return;
    final mensajero = ScaffoldMessenger.of(context);
    try {
      await DatabaseHelper.instancia.guardarPresupuestoCategoria(
          periodoDe(_mes), resultado.idCategoria, resultado.monto);
      mensajero.showSnackBar(avisoExito(existente == null
          ? 'Presupuesto por categoría asignado: ${formatoMoneda(resultado.monto)}'
          : 'Presupuesto de la categoría reformulado: ${formatoMoneda(resultado.monto)}'));
    } catch (e) {
      mensajero.showSnackBar(SnackBar(
          backgroundColor: TemaApp.gasto,
          content: Text('No se pudo guardar: $e')));
    }
  }

  Future<void> _quitarCategoria(EstadoCategoria e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar presupuesto'),
        content: Text('¿Quitar el presupuesto de "${e.nombre}" de este mes?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Quitar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final mensajero = ScaffoldMessenger.of(context);
    await DatabaseHelper.instancia
        .eliminarPresupuestoCategoria(e.presupuesto.id!);
    // al quitarlo, ese monto vuelve solito a la parte sin asignar
    mensajero.showSnackBar(avisoExito(
        'Presupuesto de "${e.nombre}" eliminado; '
        '${formatoMoneda(e.presupuesto.monto)} vuelven a "sin asignar"',
        icono: Icons.delete_outline));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presupuesto')),
      body: _cuerpo(),
    );
  }

  Widget _cuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return MensajeVacio(icono: Icons.error_outline, texto: _error!);
    }
    final estado = _reporte!.presupuesto;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SelectorMes(mes: _mes, onCambiar: _cambiarMes),
        const SizedBox(height: 12),
        // con el ...[] meto varios widgets dentro del if
        if (_reporte!.alertas.isNotEmpty) ...[
          PanelAlertas(alertas: _reporte!.alertas),
          const SizedBox(height: 12),
        ],
        // si todavía no hay presupuesto muestro el botón para crearlo
        if (!estado.existe)
          TarjetaSeccion(
            titulo: 'Sin presupuesto',
            child: Column(
              children: [
                const MensajeVacio(
                  icono: Icons.savings_outlined,
                  texto: 'Aún no estableciste un presupuesto para este mes.\n'
                      'Define cuánto quieres gastar como máximo.',
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  onPressed: _establecer,
                  icon: const Icon(Icons.add),
                  label: const Text('Establecer presupuesto inicial'),
                ),
              ],
            ),
          )
        else
          _tarjetaEstado(estado),
        const SizedBox(height: 12),
        // cuánto del total ya está repartido y cuánto queda libre
        TarjetaSeccion(
          titulo: 'Distribución del presupuesto',
          child: TarjetaDistribucion(distribucion: _reporte!.distribucion),
        ),
        const SizedBox(height: 12),
        TarjetaSeccion(
          titulo: 'Presupuesto por categoría',
          accion: TextButton.icon(
            onPressed: () => _asignarCategoria(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Asignar'),
          ),
          child: _reporte!.presupuestosCategoria.isEmpty
              ? const MensajeVacio(
                  icono: Icons.category_outlined,
                  texto: 'Asigna un límite a categorías como Alimentación '
                      'o Transporte para controlarlas por separado.')
              : Column(
                  children: [
                    // tocar edita el límite y el tacho lo quita
                    for (final e in _reporte!.presupuestosCategoria)
                      ItemPresupuestoCategoria(
                        estado: e,
                        onTap: () => _asignarCategoria(existente: e),
                        onEliminar: () => _quitarCategoria(e),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        TarjetaSeccion(
          titulo: 'Gasto acumulado por categoría',
          child: _reporte!.gastosPorCategoria.isEmpty
              ? const MensajeVacio(
                  icono: Icons.receipt_long_outlined,
                  texto: 'No hay gastos en este mes.')
              : Column(
                  children: [
                    for (final g in _reporte!.gastosPorCategoria)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(TemaApp.icono(g.icono),
                            color: TemaApp.colorCategoria(g.color)),
                        title: Text(g.nombre),
                        trailing: Text(formatoMoneda(g.total),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  /// La tarjeta principal: cuánto puse, cuánto gasté, cuánto queda y un mensaje.
  Widget _tarjetaEstado(EstadoPresupuesto e) {
    final porcentaje = (e.fraccionUsada * 100).toStringAsFixed(0);
    final color = BarraPresupuesto.colorDe(e.nivel);
    // el mensaje depende del nivel que calculé en el servicio
    final String mensaje;
    switch (e.nivel) {
      case NivelPresupuesto.excedido:
        mensaje = 'Presupuesto excedido por ${formatoMoneda(-e.disponible)}';
        break;
      case NivelPresupuesto.cercaDelLimite:
        mensaje = 'Cuidado: ya usaste el $porcentaje % de tu presupuesto';
        break;
      default:
        mensaje = 'Vas bien: tu gasto está dentro del presupuesto';
    }

    return TarjetaSeccion(
      titulo: 'Estado del presupuesto',
      accion: TextButton.icon(
        onPressed: _establecer,
        icon: const Icon(Icons.edit, size: 18),
        label: const Text('Reformular'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fila('Presupuesto establecido', e.montoPresupuesto!,
              TemaApp.primario),
          _fila('Gasto acumulado', e.gastado, TemaApp.gasto),
          // si el saldo es negativo cambio el texto y muestro el valor sin signo con abs()
          _fila(e.disponible >= 0 ? 'Saldo disponible' : 'Saldo excedido',
              e.disponible.abs(), e.disponible >= 0 ? TemaApp.ingreso : TemaApp.gasto),
          const SizedBox(height: 12),
          BarraPresupuesto(estado: e),
          const SizedBox(height: 6),
          Text('$porcentaje % utilizado',
              style: const TextStyle(color: TemaApp.textoSuave)),
          if (e.ultimaReformulacion != null)
            Text(
                'Última definición/reformulación: '
                '${formatoFecha(e.ultimaReformulacion!)}',
                style: const TextStyle(
                    color: TemaApp.textoSuave, fontSize: 12)),
          const SizedBox(height: 12),
          // cajita de color con el mensaje; double.infinity para que ocupe todo el ancho
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                    e.nivel == NivelPresupuesto.normal
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    color: color),
                const SizedBox(width: 8),
                // sin el Expanded el mensaje largo se salía por la derecha
                Expanded(
                    child: Text(mensaje,
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // fila con la etiqueta a la izquierda y el monto pegado a la derecha
  Widget _fila(String etiqueta, double monto, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta)),
          Text(formatoMoneda(monto),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

/// Las flechas para cambiar de mes. La dejé pública porque Reportes también la usa.
class SelectorMes extends StatelessWidget {
  final DateTime mes;
  final ValueChanged<int> onCambiar;
  const SelectorMes({super.key, required this.mes, required this.onCambiar});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: TemaApp.bordeTarjeta(),
      child: Row(
        children: [
          // -1 para ir al mes anterior
          IconButton(
            tooltip: 'Mes anterior',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onCambiar(-1),
          ),
          Expanded(
            child: Text(nombreMes(mes),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            tooltip: 'Mes siguiente',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onCambiar(1),
          ),
        ],
      ),
    );
  }
}

/// Diálogo donde se escribe el monto total del mes.
class _DialogoMonto extends StatefulWidget {
  final double? montoActual;
  final DateTime mes;
  final double yaAsignado; // lo que ya está repartido en categorías
  const _DialogoMonto(
      {this.montoActual, required this.mes, this.yaAsignado = 0});

  @override
  State<_DialogoMonto> createState() => _DialogoMontoState();
}

class _DialogoMontoState extends State<_DialogoMonto> {
  final _formKey = GlobalKey<FormState>();
  // si está reformulando, el campo ya aparece con el monto anterior
  late final TextEditingController _control = TextEditingController(
      text: widget.montoActual?.toStringAsFixed(2) ?? '');

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  void _aceptar() {
    if (!_formKey.currentState!.validate()) return;
    // devuelvo el monto ya convertido a double
    Navigator.pop(context, leerMonto(_control.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.montoActual == null
          ? 'Presupuesto inicial - ${nombreMes(widget.mes)}'
          : 'Reformular presupuesto - ${nombreMes(widget.mes)}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _control,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
          ],
          // con copyWith le agrego el texto de ayuda sin rehacer toda la decoración
          decoration: TemaApp.campo('Monto máximo a gastar', Icons.savings,
                  prefijo: 'Bs ')
              .copyWith(
                  helperText: widget.yaAsignado > 0
                      ? 'Ya repartido en categorías: '
                          '${formatoMoneda(widget.yaAsignado)}'
                      : null),
          // con ?? encadeno: si validarMonto da null (está bien) recién reviso lo repartido
          validator: (v) =>
              validarMonto(v) ??
              FinanzasService.validarTotalMes(
                  leerMonto(v ?? '')!, widget.yaAsignado),
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

// clase chiquita para devolver dos datos juntos desde el diálogo
class _ResultadoCategoria {
  final int idCategoria;
  final double monto;
  const _ResultadoCategoria(this.idCategoria, this.monto);
}

/// Diálogo para elegir la categoría de gasto y escribir su límite del mes.
class _DialogoPresupuestoCategoria extends StatefulWidget {
  final List<Categoria> categorias;
  final int? idInicial;
  final double? montoActual;
  final double sinAsignar; // lo que sobra del total sin repartir
  final Map<int, double> asignados; // el límite que ya tiene cada categoría
  const _DialogoPresupuestoCategoria(
      {required this.categorias,
      this.idInicial,
      this.montoActual,
      required this.sinAsignar,
      this.asignados = const {}});

  @override
  State<_DialogoPresupuestoCategoria> createState() =>
      _DialogoPresupuestoCategoriaState();
}

class _DialogoPresupuestoCategoriaState
    extends State<_DialogoPresupuestoCategoria> {
  final _formKey = GlobalKey<FormState>();
  // si no viene una categoría, arranco con la primera de la lista
  late int? _idCategoria = widget.idInicial ?? widget.categorias.first.id;
  late final TextEditingController _control = TextEditingController(
      text: widget.montoActual?.toStringAsFixed(2) ?? '');

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  // lo que puedo darle = lo sin asignar + lo que esa categoría ya tenía,
  // porque al cambiarlo ese monto anterior se libera
  double get _disponible =>
      widget.sinAsignar + (widget.asignados[_idCategoria] ?? 0);

  void _aceptar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
        context, _ResultadoCategoria(_idCategoria!, leerMonto(_control.text)!));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.montoActual == null
          ? 'Presupuesto por categoría'
          : 'Reformular presupuesto de categoría'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _idCategoria,
              isExpanded: true,
              decoration: TemaApp.campo('Categoría', Icons.category_outlined),
              items: [
                for (final c in widget.categorias)
                  DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        Icon(TemaApp.icono(c.icono),
                            color: TemaApp.colorCategoria(c.color), size: 20),
                        const SizedBox(width: 8),
                        // Flexible con ellipsis: si el nombre es largo se corta con "..."
                        Flexible(
                            child: Text(c.nombre,
                                overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
              ],
              // al reformular dejo la categoría fija; onChanged en null desactiva el dropdown
              onChanged: widget.montoActual != null
                  ? null
                  : (id) => setState(() => _idCategoria = id),
              validator: (v) => v == null ? 'Seleccione una categoría' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _control,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
              ],
              // si sale negativo muestro 0 en la ayuda, para no confundir
              decoration: TemaApp.campo('Límite del mes', Icons.savings,
                      prefijo: 'Bs ')
                  .copyWith(
                      helperText: 'Disponible para repartir: '
                          '${formatoMoneda(_disponible < 0 ? 0 : _disponible)}'),
              // primero que sea un número válido y después que no pase lo disponible
              validator: (v) =>
                  validarMonto(v) ??
                  FinanzasService.validarMontoCategoria(
                      leerMonto(v ?? '')!, _disponible),
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
