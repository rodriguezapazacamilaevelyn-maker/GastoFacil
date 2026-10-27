// ============================================================
// Proyecto    : GastoFácil
// Archivo     : test/interfaz_test.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Pruebo que las tarjetas no se desborden en pantallas de distintos tamaños.
// ============================================================

// Dibujo las tarjetas principales con montos grandes en varios tamaños de pantalla.
// Si algún texto no entra, Flutter tira un error de overflow y la prueba falla.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastofacil/models/categoria.dart';
import 'package:gastofacil/models/presupuesto.dart';
import 'package:gastofacil/models/presupuesto_categoria.dart';
import 'package:gastofacil/models/transaccion.dart';
import 'package:gastofacil/services/finanzas_service.dart';
import 'package:gastofacil/utils/tema.dart';
import 'package:gastofacil/widgets/tarjetas.dart';

// los tamaños en dp, desde un celular chico hasta escritorio
const tamanos = <String, Size>{
  'Teléfono pequeño 320x568': Size(320, 568),
  'Teléfono 360x640': Size(360, 640),
  'Teléfono grande 411x914 (Medium Phone)': Size(411, 914),
  'Tablet 800x1280': Size(800, 1280),
  'Escritorio / web 1280x800': Size(1280, 800),
};

Transaccion _gasto(double monto, int idCat) => Transaccion(
      tipo: TipoMovimiento.gasto,
      titulo: 'Prueba',
      monto: monto,
      fecha: DateTime(2026, 10, 10),
      idCategoria: idCat,
      categoriaNombre: 'Cat $idCat',
      categoriaColor: idCat,
      categoriaIcono: 'otros',
    );

PresupuestoCategoria _pc(int id, String nombre, double monto) =>
    PresupuestoCategoria(
      periodo: '2026-10',
      idCategoria: id,
      monto: monto,
      fechaActualizacion: DateTime(2026, 10),
      categoriaNombre: nombre,
      categoriaColor: id,
      categoriaIcono: 'otros',
    );

/// Armo una pantalla con las tarjetas de Inicio, Presupuesto y Reportes.
/// Pongo montos grandes y un nombre largo a propósito para probar el peor caso.
Widget _pantalla() {
  final transacciones = [
    _gasto(12530.50, 1),
    _gasto(9870.25, 2),
    _gasto(4500, 3),
  ];
  final general = FinanzasService.calcularEstadoPresupuesto(
      Presupuesto(
          periodo: '2026-10',
          monto: 25000,
          fechaActualizacion: DateTime(2026, 10)),
      transacciones);
  // Alimentación se pasa de su límite, así también sale el panel de alertas
  final categorias = FinanzasService.calcularEstadosCategoria([
    _pc(1, 'Alimentación y supermercado', 12000),
    _pc(2, 'Transporte', 9000),
  ], transacciones);
  final distribucion = FinanzasService.calcularDistribucion(general, categorias);

  return MaterialApp(
    theme: TemaApp.claro(),
    home: Scaffold(
      // con scroll para que en pantallas bajas no falle por altura sino solo por ancho
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            PanelAlertas(
                alertas: FinanzasService.calcularAlertas(general, categorias)),
            const SizedBox(height: 12),
            const TarjetaBalance(
                resumen:
                    ResumenFinanciero(ingresos: 123456.78, gastos: 98765.43)),
            const SizedBox(height: 12),
            TarjetaSeccion(
              titulo: 'Distribución del presupuesto',
              child: TarjetaDistribucion(distribucion: distribucion),
            ),
            const SizedBox(height: 12),
            TarjetaSeccion(
              titulo: 'Presupuesto por categoría',
              child: Column(children: [
                // les paso callbacks vacíos para que también se dibuje la X
                for (final c in categorias)
                  ItemPresupuestoCategoria(
                      estado: c, onTap: () {}, onEliminar: () {}),
              ]),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  group('Pruebas de interfaz en distintos tamaños', () {
    // un testWidgets por cada tamaño de la lista
    for (final entrada in tamanos.entries) {
      testWidgets('sin desbordes en ${entrada.key}', (tester) async {
        // cambio el tamaño de la pantalla virtual; con ratio 1 los px son iguales a dp
        tester.view.physicalSize = entrada.value;
        tester.view.devicePixelRatio = 1.0;
        // al terminar dejo la vista como estaba para no afectar a la siguiente prueba
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_pantalla());
        await tester.pumpAndSettle();

        // si hubo overflow, takeException lo devuelve y aquí falla
        expect(tester.takeException(), isNull);
        expect(find.text('Distribución del presupuesto'), findsOneWidget);
        expect(find.textContaining('Sin asignar'), findsOneWidget);
      });
    }
  });
}
