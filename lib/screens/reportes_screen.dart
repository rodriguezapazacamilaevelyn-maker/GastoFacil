// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/screens/reportes_screen.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Pantalla de reportes donde se ve cómo fue cada mes.
// ============================================================

import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../services/finanzas_service.dart';
import '../utils/formato.dart';
import '../utils/tema.dart';
import '../widgets/grafico_categorias.dart';
import '../widgets/tarjetas.dart';
// del archivo de presupuesto solo necesito el selector de mes
import 'presupuesto_screen.dart' show SelectorMes;

/// El reporte de un mes: balance, gastos por categoría y
/// cuánto se presupuestó contra lo que realmente se gastó.
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  // arranco en el mes actual, siempre desde el día 1
  DateTime _mes = inicioMes(DateTime.now());
  ReporteMensual? _reporte;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // si registran algo en otra pestaña, el reporte se recalcula solo
    DatabaseHelper.cambios.addListener(_cargar);
    _cargar();
  }

  @override
  void dispose() {
    DatabaseHelper.cambios.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final r = await FinanzasService.generarReporte(_mes);
      if (!mounted) return;
      setState(() {
        _reporte = r;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo generar el reporte. ($e)';
      });
    }
  }

  // delta es +1 para el mes siguiente o -1 para el anterior
  void _cambiarMes(int delta) {
    setState(() => _mes = sumarMeses(_mes, delta));
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes financieros')),
      body: _cuerpo(),
    );
  }

  Widget _cuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return MensajeVacio(icono: Icons.error_outline, texto: _error!);
    }
    final r = _reporte!;
    // cuento ingresos y los gastos son el resto, así recorro la lista una sola vez
    final cantIngresos = r.transacciones.where((t) => t.esIngreso).length;
    final cantGastos = r.transacciones.length - cantIngresos;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SelectorMes(mes: _mes, onCambiar: _cambiarMes),
        const SizedBox(height: 12),
        TarjetaBalance(resumen: r.resumen, titulo: 'Balance del período'),
        const SizedBox(height: 12),
        // con Expanded las dos tarjetitas se reparten el ancho por igual
        Row(
          children: [
            Expanded(
                child: _Indicador(
                    titulo: 'Ingresos',
                    valor: '$cantIngresos',
                    icono: Icons.arrow_upward,
                    color: TemaApp.ingreso)),
            const SizedBox(width: 12),
            Expanded(
                child: _Indicador(
                    titulo: 'Gastos',
                    valor: '$cantGastos',
                    icono: Icons.arrow_downward,
                    color: TemaApp.gasto)),
          ],
        ),
        const SizedBox(height: 12),
        // aquí el gráfico sí muestra los montos, en el inicio no
        TarjetaSeccion(
          titulo: 'Distribución de gastos',
          child: GraficoCategorias(
              datos: r.gastosPorCategoria, mostrarMontos: true),
        ),
        const SizedBox(height: 12),
        TarjetaSeccion(
          titulo: 'Presupuesto vs. gasto real',
          child: r.presupuesto.existe
              ? _ComparacionPresupuesto(estado: r.presupuesto)
              : const MensajeVacio(
                  icono: Icons.savings_outlined,
                  texto: 'No hay un presupuesto registrado para este período.'),
        ),
        const SizedBox(height: 12),
        // cómo quedó repartido el total del mes entre las categorías
        TarjetaSeccion(
          titulo: 'Distribución del presupuesto',
          child: TarjetaDistribucion(distribucion: r.distribucion),
        ),
        const SizedBox(height: 12),
        // y una fila por cada categoría que tiene límite
        TarjetaSeccion(
          titulo: 'Presupuesto por categoría',
          child: r.presupuestosCategoria.isEmpty
              ? const MensajeVacio(
                  icono: Icons.category_outlined,
                  texto: 'No hay presupuestos por categoría en este período.')
              : Column(
                  children: [
                    for (final e in r.presupuestosCategoria)
                      ItemPresupuestoCategoria(estado: e),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Tarjetita con cuántos ingresos o gastos se registraron.
class _Indicador extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _Indicador(
      {required this.titulo,
      required this.valor,
      required this.icono,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: TemaApp.bordeTarjeta(),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(35),
              child: Icon(icono, color: color),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valor,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text('$titulo registrados',
                    style: const TextStyle(
                        fontSize: 12, color: TemaApp.textoSuave)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dos barras, una del presupuesto y otra del gasto real, para compararlas.
class _ComparacionPresupuesto extends StatelessWidget {
  final EstadoPresupuesto estado;
  const _ComparacionPresupuesto({required this.estado});

  @override
  Widget build(BuildContext context) {
    final presupuesto = estado.montoPresupuesto!;
    // el más grande de los dos ocupa la barra llena y el otro va en proporción
    final maximo =
        presupuesto > estado.gastado ? presupuesto : estado.gastado;
    final dentro = estado.nivel != NivelPresupuesto.excedido;

    // armo cada barra con su etiqueta y su monto encima
    Widget barra(String etiqueta, double valor, Color color) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(etiqueta)),
                  Text(formatoMoneda(valor),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              // ClipRRect para que la barra tenga las puntas redondeadas
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  // si los dos son 0 evito la división entre cero
                  value: maximo == 0 ? 0 : valor / maximo,
                  minHeight: 14,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        barra('Presupuesto', presupuesto, TemaApp.primario),
        // la barra del gasto cambia de color según el nivel (verde, naranja o rojo)
        barra('Gasto real', estado.gastado,
            BarraPresupuesto.colorDe(estado.nivel)),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(dentro ? Icons.check_circle : Icons.cancel,
                color: dentro ? TemaApp.ingreso : TemaApp.gasto, size: 20),
            const SizedBox(width: 6),
            // Expanded para que el texto baje de línea y no se salga en celulares chicos
            Expanded(
              child: Text(
                dentro
                    ? 'Dentro del límite (${(estado.fraccionUsada * 100).toStringAsFixed(0)} % usado)'
                    : 'Fuera del límite por ${formatoMoneda(-estado.disponible)}',
                style: TextStyle(
                    color: dentro ? TemaApp.ingreso : TemaApp.gasto,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
