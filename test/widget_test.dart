// ============================================================
// Proyecto    : GastoFácil
// Archivo     : test/widget_test.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Pruebas de los cálculos y validaciones, sin abrir la app.
// ============================================================

// Aquí pruebo los cálculos, las validaciones y los modelos sin abrir la app ni la BD.
// Para correrlas uso: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:gastofacil/models/categoria.dart';
import 'package:gastofacil/models/presupuesto.dart';
import 'package:gastofacil/models/presupuesto_categoria.dart';
import 'package:gastofacil/models/transaccion.dart';
import 'package:gastofacil/services/finanzas_service.dart';
import 'package:gastofacil/utils/formato.dart';

// atajo para armar transacciones de prueba sin escribir todos los campos
Transaccion _t(String tipo, double monto, int idCat, String nombreCat) =>
    Transaccion(
      tipo: tipo,
      titulo: 'Prueba',
      monto: monto,
      fecha: DateTime(2026, 9, 15),
      idCategoria: idCat,
      categoriaNombre: nombreCat,
      categoriaColor: idCat,
      categoriaIcono: 'otros',
    );

void main() {
  // datos de ejemplo: 3000 de ingreso y 1250 de gasto (1000 en comida y 250 en pasajes)
  final datos = [
    _t(TipoMovimiento.ingreso, 3000, 9, 'Salario'),
    _t(TipoMovimiento.gasto, 600, 1, 'Alimentación'),
    _t(TipoMovimiento.gasto, 400, 1, 'Alimentación'),
    _t(TipoMovimiento.gasto, 250, 2, 'Transporte'),
  ];

  group('Resumen financiero', () {
    test('suma ingresos, gastos y calcula el balance', () {
      final r = FinanzasService.calcularResumen(datos);
      expect(r.ingresos, 3000);
      expect(r.gastos, 1250);
      expect(r.balance, 1750);
    });

    test('lista vacía da todo en cero', () {
      final r = FinanzasService.calcularResumen([]);
      expect(r.balance, 0);
    });
  });

  group('Gastos por categoría', () {
    test('agrupa, calcula porcentajes y ordena de mayor a menor', () {
      final g = FinanzasService.calcularGastosPorCategoria(datos);
      expect(g.length, 2);
      expect(g.first.nombre, 'Alimentación');
      expect(g.first.total, 1000);
      // uso closeTo porque con doubles comparar exacto puede fallar
      expect(g.first.porcentaje, closeTo(80, 0.01));
      expect(g.last.porcentaje, closeTo(20, 0.01));
    });
  });

  group('Presupuesto', () {
    Presupuesto p(double monto) => Presupuesto(
        periodo: '2026-09', monto: monto, fechaActualizacion: DateTime(2026));

    // con 1250 gastados voy cambiando el presupuesto para caer en cada nivel
    test('dentro del presupuesto', () {
      final e = FinanzasService.calcularEstadoPresupuesto(p(3000), datos);
      expect(e.disponible, 1750);
      expect(e.nivel, NivelPresupuesto.normal);
    });

    test('cerca del límite (80 % o más)', () {
      // 1250 de 1500 es más o menos el 83 %
      final e = FinanzasService.calcularEstadoPresupuesto(p(1500), datos);
      expect(e.nivel, NivelPresupuesto.cercaDelLimite);
    });

    test('excedido', () {
      final e = FinanzasService.calcularEstadoPresupuesto(p(1000), datos);
      expect(e.disponible, -250);
      expect(e.nivel, NivelPresupuesto.excedido);
    });

    test('sin presupuesto registrado', () {
      final e = FinanzasService.calcularEstadoPresupuesto(null, datos);
      expect(e.existe, false);
      expect(e.nivel, NivelPresupuesto.sinPresupuesto);
    });
  });

  group('Validación de montos', () {
    // isNotNull quiere decir que el validator devolvió un mensaje de error
    test('rechaza vacío, texto, cero y negativos', () {
      expect(validarMonto(''), isNotNull);
      expect(validarMonto('abc'), isNotNull);
      expect(validarMonto('0'), isNotNull);
      expect(validarMonto('-5'), isNotNull);
    });

    test('acepta punto o coma decimal', () {
      expect(validarMonto('25.50'), isNull);
      expect(validarMonto('25,50'), isNull);
      expect(leerMonto('25,50'), 25.5);
    });
  });

  group('Modelos', () {
    // reviso que al pasar a Map y volver no se pierda nada
    test('Transaccion toMap / fromMap conserva los datos', () {
      final original = _t(TipoMovimiento.gasto, 12.5, 1, 'Alimentación');
      final mapa = original.toMap();
      expect(mapa['fecha'], '2026-09-15');
      final copia = Transaccion.fromMap(mapa);
      expect(copia.monto, 12.5);
      expect(copia.tipo, TipoMovimiento.gasto);
      expect(copia.fecha, DateTime(2026, 9, 15));
    });

    test('Categoria guarda "predefinida" como 1/0', () {
      const c = Categoria(
          nombre: 'Mascotas',
          tipo: TipoMovimiento.gasto,
          icono: 'mascota',
          color: 3,
          predefinida: false);
      expect(c.toMap()['predefinida'], 0);
      expect(Categoria.fromMap({...c.toMap(), 'id': 1}).predefinida, false);
    });
  });

  group('Fechas y períodos', () {
    // febrero 2026 tiene 28 días y de diciembre debe pasar a enero del otro año
    test('período, inicio y fin de mes', () {
      final f = DateTime(2026, 2, 10);
      expect(periodoDe(f), '2026-02');
      expect(inicioMes(f), DateTime(2026, 2, 1));
      expect(finMes(f), DateTime(2026, 2, 28));
      expect(sumarMeses(DateTime(2026, 12, 5), 1), DateTime(2027, 1, 1));
    });
  });

  group('Presupuesto por categoría y alertas', () {
    PresupuestoCategoria pc(int idCat, String nombre, double monto) =>
        PresupuestoCategoria(
            periodo: '2026-09',
            idCategoria: idCat,
            monto: monto,
            fechaActualizacion: DateTime(2026),
            categoriaNombre: nombre);

    test('calcula lo gastado en cada categoría', () {
      final e = FinanzasService.calcularEstadosCategoria(
          [pc(1, 'Alimentación', 800), pc(2, 'Transporte', 200)], datos);
      expect(e[0].gastado, 1000);
      expect(e[0].nivel, NivelPresupuesto.excedido);
      expect(e[1].gastado, 250);
      expect(e[1].disponible, -50);
    });

    // el general queda cerca (naranja) y Alimentación excedida (rojo), la roja va primero
    test('genera alertas: excedidos primero', () {
      final general = FinanzasService.calcularEstadoPresupuesto(
          Presupuesto(
              periodo: '2026-09',
              monto: 1500,
              fechaActualizacion: DateTime(2026)),
          datos);
      final cats = FinanzasService.calcularEstadosCategoria(
          [pc(1, 'Alimentación', 800)], datos);
      final alertas = FinanzasService.calcularAlertas(general, cats);
      expect(alertas.length, 2);
      expect(alertas.first.excedido, true);
      expect(alertas.first.mensaje, contains('Alimentación'));
    });

    test('sin presupuestos no hay alertas', () {
      final general = FinanzasService.calcularEstadoPresupuesto(null, datos);
      expect(FinanzasService.calcularAlertas(general, []), isEmpty);
    });
  });

  group('Distribución del presupuesto', () {
    PresupuestoCategoria pc(int idCat, String nombre, double monto) =>
        PresupuestoCategoria(
            periodo: '2026-09',
            idCategoria: idCat,
            monto: monto,
            fechaActualizacion: DateTime(2026),
            categoriaNombre: nombre);
    EstadoPresupuesto general(double monto) =>
        FinanzasService.calcularEstadoPresupuesto(
            Presupuesto(
                periodo: '2026-09',
                monto: monto,
                fechaActualizacion: DateTime(2026)),
            datos);

    // de 1500 reparto 800 + 200, así que tienen que quedar 500 sin asignar
    test('las categorías se descuentan del total del mes', () {
      final cats = FinanzasService.calcularEstadosCategoria(
          [pc(1, 'Alimentación', 800), pc(2, 'Transporte', 200)], datos);
      final d = FinanzasService.calcularDistribucion(general(1500), cats);
      expect(d.asignado, 1000);
      expect(d.sinAsignar, 500);
      expect(d.porcentajeAsignado, closeTo(66.67, 0.01));
      expect(d.gastadoOtros, 0);
      expect(d.disponibleOtros, 500);
      expect(d.excedeTotal, false);
    });

    test('al reformular, el monto actual vuelve a estar disponible', () {
      final cats = FinanzasService.calcularEstadosCategoria(
          [pc(1, 'Alimentación', 800)], datos);
      final d = FinanzasService.calcularDistribucion(general(1500), cats);
      expect(d.disponibleParaCategoria(), 700);
      expect(d.disponibleParaCategoria(montoActual: 800), 1500);
    });

    // pruebo justo en el borde: 500 de 500 sí tiene que pasar
    test('no se puede asignar más de lo que queda por repartir', () {
      expect(FinanzasService.validarMontoCategoria(600, 500), isNotNull);
      expect(FinanzasService.validarMontoCategoria(500, 500), isNull);
      expect(FinanzasService.validarMontoCategoria(0, 500), isNotNull);
    });

    test('el total no puede ser menor a lo ya repartido', () {
      expect(FinanzasService.validarTotalMes(900, 1000), isNotNull);
      expect(FinanzasService.validarTotalMes(1000, 1000), isNull);
    });

    test('alerta si las categorías suman más que el total', () {
      final cats = FinanzasService.calcularEstadosCategoria(
          [pc(1, 'Alimentación', 1200), pc(2, 'Transporte', 400)], datos);
      final g = general(1500);
      expect(FinanzasService.calcularDistribucion(g, cats).excedeTotal, true);
      final alertas = FinanzasService.calcularAlertas(g, cats);
      expect(alertas.any((a) => a.mensaje.contains('Tus categorías suman')),
          true);
    });

    test('sin presupuesto total no hay distribución', () {
      final d = FinanzasService.calcularDistribucion(
          FinanzasService.calcularEstadoPresupuesto(null, datos), []);
      expect(d.existe, false);
      expect(d.porcentajeAsignado, 0);
    });
  });
}
