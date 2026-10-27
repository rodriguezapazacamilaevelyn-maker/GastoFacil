// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/widgets/grafico_categorias.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : El gráfico de pastel que muestra en qué categorías se va la plata.
// ============================================================

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/finanzas_service.dart';
import '../utils/formato.dart';
import '../utils/tema.dart';
import 'tarjetas.dart';

/// Pastel de gastos con su leyenda al lado, hecho con fl_chart.
/// Lo uso en Inicio y en Reportes.
class GraficoCategorias extends StatelessWidget {
  final List<GastoPorCategoria> datos;
  final bool mostrarMontos; // en Reportes pongo los montos en vez del %

  const GraficoCategorias(
      {super.key, required this.datos, this.mostrarMontos = false});

  @override
  Widget build(BuildContext context) {
    // sin gastos el pastel saldría vacío, mejor muestro un mensaje
    if (datos.isEmpty) {
      return const MensajeVacio(
        icono: Icons.pie_chart_outline,
        texto: 'Aún no hay gastos registrados en este período.',
      );
    }

    final grafico = SizedBox(
      width: 150,
      height: 150,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          // el hueco del centro lo hace ver como dona
          centerSpaceRadius: 32,
          sections: [
            // una porción por categoría; fl_chart calcula el tamaño con value
            for (final d in datos)
              PieChartSectionData(
                value: d.total,
                color: TemaApp.colorCategoria(d.color),
                radius: 42,
                // en porciones muy chicas el % no entra, así que lo dejo vacío
                title: d.porcentaje >= 8
                    ? '${d.porcentaje.toStringAsFixed(0)}%'
                    : '',
                titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
          ],
        ),
      ),
    );

    final leyenda = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final d in datos)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                // cuadradito con el color de la categoría
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: TemaApp.colorCategoria(d.color),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                // si el nombre es largo se corta con "..." y no empuja el monto
                Expanded(
                  child: Text(d.nombre,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13)),
                ),
                Text(
                  mostrarMontos
                      ? formatoMoneda(d.total)
                      : '${d.porcentaje.toStringAsFixed(0)} %',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );

    // con LayoutBuilder veo cuánto ancho tengo: si alcanza pongo gráfico y
    // leyenda lado a lado, si la pantalla es angosta uno debajo del otro
    return LayoutBuilder(
      builder: (context, restricciones) {
        if (restricciones.maxWidth >= 330) {
          return Row(
            children: [
              grafico,
              const SizedBox(width: 16),
              Expanded(child: leyenda),
            ],
          );
        }
        return Column(
          children: [grafico, const SizedBox(height: 12), leyenda],
        );
      },
    );
  }
}
