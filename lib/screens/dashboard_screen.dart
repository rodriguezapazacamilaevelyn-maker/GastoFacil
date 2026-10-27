// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/screens/dashboard_screen.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Pantalla de inicio con el resumen del mes, alertas y lo último registrado.
// ============================================================

import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../db/plataforma_bd.dart';
import '../models/categoria.dart';
import '../models/transaccion.dart';
import '../services/finanzas_service.dart';
import '../utils/formato.dart';
import '../utils/tema.dart';
import '../widgets/grafico_categorias.dart';
import '../widgets/item_transaccion.dart';
import '../widgets/tarjetas.dart';
import 'acerca_de_screen.dart';
import 'categorias_screen.dart';
import 'respaldo_screen.dart';
import 'transaccion_form_screen.dart';

/// Lo primero que ve el usuario: balance, presupuesto, gráfico
/// por categoría y los últimos movimientos.
class DashboardScreen extends StatefulWidget {
  /// Me lo pasa MainShell para poder saltar a otra pestaña desde aquí.
  final ValueChanged<int> onCambiarPestana;

  const DashboardScreen({super.key, required this.onCambiarPestana});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  ReporteMensual? _reporte;
  List<Transaccion> _recientes = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // me suscribo a los cambios de la BD, así el resumen se actualiza solo
    DatabaseHelper.cambios.addListener(_cargar);
    _cargar();
  }

  @override
  void dispose() {
    // si no quito el listener seguiría llamando a _cargar con la pantalla cerrada
    DatabaseHelper.cambios.removeListener(_cargar);
    super.dispose();
  }

  /// Traigo el reporte del mes actual y los 5 movimientos más nuevos.
  Future<void> _cargar() async {
    try {
      final reporte = await FinanzasService.generarReporte(DateTime.now());
      final recientes =
          await DatabaseHelper.instancia.obtenerTransacciones(limite: 5);
      if (!mounted) return; // por si la pantalla se cerró mientras esperaba
      setState(() {
        _reporte = reporte;
        _recientes = recientes;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      // si algo falla no se queda cargando, muestro el error en pantalla
      setState(() {
        _cargando = false;
        _error = 'No se pudieron cargar los datos. ($e)';
      });
    }
  }

  // si le paso t es para editar; si no, es un registro nuevo del tipo indicado
  void _abrirFormulario({String tipo = TipoMovimiento.gasto, Transaccion? t}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TransaccionFormScreen(tipoInicial: tipo, transaccion: t),
      ),
    );
  }

  void _abrir(Widget pantalla) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GastoFácil',
            style: TextStyle(fontWeight: FontWeight.bold)),
        // botones de arriba para categorías, respaldo y acerca de
        actions: [
          IconButton(
            tooltip: 'Categorías',
            icon: const Icon(Icons.category_outlined),
            onPressed: () => _abrir(const CategoriasScreen()),
          ),
          IconButton(
            tooltip: 'Copia de respaldo',
            icon: const Icon(Icons.backup_outlined),
            onPressed: () => _abrir(const RespaldoScreen()),
          ),
          IconButton(
            tooltip: 'Acerca de',
            icon: const Icon(Icons.info_outline),
            onPressed: () => _abrir(const AcercaDeScreen()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: _construirCuerpo(),
    );
  }

  // según el estado muestro el circulito de carga, el error o el resumen
  Widget _construirCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return MensajeVacio(icono: Icons.error_outline, texto: _error!);
    }
    final r = _reporte!;

    // con RefreshIndicator se puede jalar hacia abajo para recargar
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        // dejo 96 abajo para que el botón flotante no tape lo último
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text('Resumen de ${nombreMes(r.mes)}',
              style: const TextStyle(
                  color: TemaApp.textoSuave, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          // el panel de alertas solo aparece si hay alguna
          if (r.alertas.isNotEmpty) ...[
            PanelAlertas(alertas: r.alertas),
            const SizedBox(height: 12),
          ],
          TarjetaBalance(resumen: r.resumen),
          const SizedBox(height: 12),
          // al tocar la tarjeta del presupuesto voy a la pestaña 2
          TarjetaPresupuesto(
            estado: r.presupuesto,
            onTap: () => widget.onCambiarPestana(2),
          ),
          const SizedBox(height: 12),
          TarjetaSeccion(
            titulo: 'Gastos por categoría',
            child: GraficoCategorias(datos: r.gastosPorCategoria),
          ),
          const SizedBox(height: 12),
          // botones rápidos que abren el formulario con el tipo ya puesto;
          // con Expanded los dos ocupan la mitad del ancho
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: TemaApp.ingreso,
                      minimumSize: const Size.fromHeight(50)),
                  onPressed: () =>
                      _abrirFormulario(tipo: TipoMovimiento.ingreso),
                  icon: const Icon(Icons.arrow_upward),
                  label: const Text('Ingreso'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: TemaApp.gasto,
                      minimumSize: const Size.fromHeight(50)),
                  onPressed: () => _abrirFormulario(tipo: TipoMovimiento.gasto),
                  icon: const Icon(Icons.arrow_downward),
                  label: const Text('Gasto'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
            onPressed: () => widget.onCambiarPestana(3),
            icon: const Icon(Icons.bar_chart),
            label: const Text('Ver reportes'),
          ),
          const SizedBox(height: 16),
          TarjetaSeccion(
            titulo: 'Últimos movimientos',
            accion: TextButton(
              onPressed: () => widget.onCambiarPestana(1),
              child: const Text('Ver todo'),
            ),
            child: _recientes.isEmpty
                ? const MensajeVacio(
                    icono: Icons.receipt_long_outlined,
                    texto:
                        'Todavía no registraste movimientos.\nToca "Registrar" para empezar.')
                : Column(
                    children: [
                      // al tocar un movimiento se abre el formulario para editarlo
                      for (final t in _recientes)
                        ItemTransaccion(
                          transaccion: t,
                          onTap: () => _abrirFormulario(tipo: t.tipo, t: t),
                        ),
                    ],
                  ),
          ),
          // abajo de todo pongo la versión y en qué plataforma está corriendo
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 72),
            child: Text(
              'GastoFácil v1.2 · ${nombrePlataforma()}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: TemaApp.textoSuave, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
