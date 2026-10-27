// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/services/finanzas_service.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Aquí hago las cuentas: totales, presupuesto, alertas y reportes.
// ============================================================

import '../db/database_helper.dart';
import '../models/presupuesto.dart';
import '../models/presupuesto_categoria.dart';
import '../models/transaccion.dart';
import '../utils/formato.dart';

// Las funciones "calcular..." solo reciben listas y no tocan la BD,
// así las pude probar en los tests sin abrir SQLite.

/// Lo que entró y lo que salió en un período.
class ResumenFinanciero {
  final double ingresos;
  final double gastos;
  const ResumenFinanciero({required this.ingresos, required this.gastos});

  // el balance no lo guardo, lo calculo cada vez con un getter
  double get balance => ingresos - gastos;
}

/// Cuánto se gastó en una categoría y qué parte es del gasto del mes.
class GastoPorCategoria {
  final String nombre;
  final int color;
  final String icono;
  final double total;
  final double porcentaje; // va de 0 a 100

  const GastoPorCategoria({
    required this.nombre,
    required this.color,
    required this.icono,
    required this.total,
    required this.porcentaje,
  });
}

// con este enum decido el color de la barra y si muestro alerta
enum NivelPresupuesto { sinPresupuesto, normal, cercaDelLimite, excedido }

/// Cómo va el presupuesto general del mes.
class EstadoPresupuesto {
  final double? montoPresupuesto; // si es null es que no puso presupuesto
  final double gastado;
  final DateTime? ultimaReformulacion; // la última vez que lo creó o cambió

  const EstadoPresupuesto(
      {this.montoPresupuesto, required this.gastado, this.ultimaReformulacion});

  bool get existe => montoPresupuesto != null;

  // lo que le queda: presupuesto menos lo gastado (puede salir negativo)
  double get disponible => (montoPresupuesto ?? 0) - gastado;

  /// 0.5 quiere decir 50 %. Si se pasó del presupuesto da más de 1.
  double get fraccionUsada {
    final p = montoPresupuesto;
    // controlo el null y el cero para no dividir entre cero
    if (p == null || p <= 0) return 0;
    return gastado / p;
  }

  /// Excedido si gastó más que el monto; desde el 80 % lo tomo como cerca del límite.
  NivelPresupuesto get nivel {
    if (!existe) return NivelPresupuesto.sinPresupuesto;
    if (gastado > montoPresupuesto!) return NivelPresupuesto.excedido;
    if (fraccionUsada >= 0.8) return NivelPresupuesto.cercaDelLimite;
    return NivelPresupuesto.normal;
  }
}

/// Lo mismo pero para una categoría: cuánto se asignó y cuánto se gastó.
class EstadoCategoria {
  final PresupuestoCategoria presupuesto;
  final double gastado;

  const EstadoCategoria({required this.presupuesto, required this.gastado});

  String get nombre => presupuesto.categoriaNombre ?? 'Categoría';
  double get disponible => presupuesto.monto - gastado;
  double get fraccionUsada =>
      presupuesto.monto <= 0 ? 0 : gastado / presupuesto.monto;

  // en vez de repetir las reglas del nivel, armo un EstadoPresupuesto y uso el suyo
  EstadoPresupuesto get comoEstado =>
      EstadoPresupuesto(montoPresupuesto: presupuesto.monto, gastado: gastado);
  NivelPresupuesto get nivel => comoEstado.nivel;
}

/// Cómo se reparte el presupuesto del mes entre las categorías.
/// Lo que no asigno a ninguna queda como bolsa para las que no tienen límite.
class DistribucionPresupuesto {
  final double? total; // presupuesto del mes, null si no hay
  final List<EstadoCategoria> categorias;
  final double gastadoTotal; // todo lo que se gastó en el mes

  const DistribucionPresupuesto(
      {this.total, required this.categorias, required this.gastadoTotal});

  bool get existe => total != null;

  // con fold sumo los límites de todas las categorías empezando desde 0
  double get asignado =>
      categorias.fold<double>(0, (s, c) => s + c.presupuesto.monto);

  // lo que sobra del total después de repartir
  double get sinAsignar => (total ?? 0) - asignado;

  double get gastadoEnCategorias =>
      categorias.fold<double>(0, (s, c) => s + c.gastado);

  // lo gastado en categorías sin límite propio, eso sale de la bolsa sin asignar
  double get gastadoOtros => gastadoTotal - gastadoEnCategorias;

  // lo que queda en la bolsa de "Otros gastos"
  double get disponibleOtros => sinAsignar - gastadoOtros;

  double get porcentajeAsignado =>
      (total == null || total! <= 0) ? 0 : asignado * 100 / total!;

  // no debería pasar, pero lo controlo; el 0.001 es por los decimales de los double
  bool get excedeTotal => existe && asignado > total! + 0.001;

  /// Cuánto más puedo darle a una categoría. Si la estoy editando,
  /// su monto actual se suma porque lo voy a reemplazar.
  double disponibleParaCategoria({double montoActual = 0}) =>
      sinAsignar + montoActual;
}

/// Un aviso para el usuario; excedido en true lo pinto rojo, si no naranja.
class AlertaPresupuesto {
  final String mensaje;
  final bool excedido;
  const AlertaPresupuesto(this.mensaje, {required this.excedido});
}

/// Todo lo que necesita la pantalla de Reportes para un mes.
class ReporteMensual {
  final DateTime mes;
  final List<Transaccion> transacciones;
  final ResumenFinanciero resumen;
  final List<GastoPorCategoria> gastosPorCategoria;
  final EstadoPresupuesto presupuesto;
  final List<EstadoCategoria> presupuestosCategoria;

  const ReporteMensual({
    required this.mes,
    required this.transacciones,
    required this.resumen,
    required this.gastosPorCategoria,
    required this.presupuesto,
    this.presupuestosCategoria = const [],
  });

  // la distribución y las alertas las saco con los mismos métodos del servicio
  DistribucionPresupuesto get distribucion =>
      FinanzasService.calcularDistribucion(presupuesto, presupuestosCategoria);

  List<AlertaPresupuesto> get alertas => FinanzasService.calcularAlertas(
      presupuesto, presupuestosCategoria);
}

/// Junté aquí todos los cálculos como métodos estáticos, no hace falta instanciar.
class FinanzasService {
  FinanzasService._();

  /// Recorro la lista y voy sumando a ingresos o a gastos según el tipo.
  static ResumenFinanciero calcularResumen(List<Transaccion> lista) {
    double ingresos = 0;
    double gastos = 0;
    for (final t in lista) {
      if (t.esIngreso) {
        ingresos += t.monto;
      } else {
        gastos += t.monto;
      }
    }
    return ResumenFinanciero(ingresos: ingresos, gastos: gastos);
  }

  /// Agrupo los gastos por categoría, saco el porcentaje y los ordeno de mayor a menor.
  static List<GastoPorCategoria> calcularGastosPorCategoria(
      List<Transaccion> lista) {
    // uso el id de la categoría como clave del Map para ir acumulando
    final totales = <int, double>{};
    final ejemplo = <int, Transaccion>{}; // guardo una transacción para sacar nombre y color
    double totalGeneral = 0;

    for (final t in lista.where((t) => t.esGasto)) {
      totales[t.idCategoria] = (totales[t.idCategoria] ?? 0) + t.monto;
      ejemplo[t.idCategoria] = t;
      totalGeneral += t.monto;
    }

    final resultado = totales.entries.map((e) {
      final t = ejemplo[e.key]!;
      return GastoPorCategoria(
        nombre: t.categoriaNombre ?? 'Sin categoría',
        color: t.categoriaColor ?? 7,
        icono: t.categoriaIcono ?? 'otros',
        total: e.value,
        // si no hay gastos evito dividir entre cero
        porcentaje: totalGeneral == 0 ? 0 : e.value * 100 / totalGeneral,
      );
    }).toList();

    // comparo b con a para que quede de mayor a menor
    resultado.sort((a, b) => b.total.compareTo(a.total));
    return resultado;
  }

  /// Junto el presupuesto del mes con lo que ya se gastó.
  static EstadoPresupuesto calcularEstadoPresupuesto(
      Presupuesto? presupuesto, List<Transaccion> transaccionesDelMes) {
    final gastado = calcularResumen(transaccionesDelMes).gastos;
    return EstadoPresupuesto(
      montoPresupuesto: presupuesto?.monto,
      gastado: gastado,
      ultimaReformulacion: presupuesto?.fechaActualizacion,
    );
  }

  /// Para cada límite de categoría busco los gastos de esa categoría y los sumo.
  static List<EstadoCategoria> calcularEstadosCategoria(
      List<PresupuestoCategoria> presupuestos,
      List<Transaccion> transaccionesDelMes) {
    return presupuestos.map((p) {
      // filtro solo gastos de esa categoría y con fold sumo los montos
      final gastado = transaccionesDelMes
          .where((t) => t.esGasto && t.idCategoria == p.idCategoria)
          .fold<double>(0, (suma, t) => suma + t.monto);
      return EstadoCategoria(presupuesto: p, gastado: gastado);
    }).toList();
  }

  /// Armo la lista de avisos del mes. Las de excedido (rojo) quedan
  /// arriba y después las de cerca del límite (naranja, desde 80 %).
  static List<AlertaPresupuesto> calcularAlertas(
      EstadoPresupuesto general, List<EstadoCategoria> categorias) {
    final alertas = <AlertaPresupuesto>[];
    // primero reviso el presupuesto general del mes
    if (general.nivel == NivelPresupuesto.excedido) {
      // disponible sale negativo, por eso le cambio el signo para mostrarlo
      alertas.add(AlertaPresupuesto(
          '¡Te pasaste de tu presupuesto del mes por '
          '${formatoMoneda(-general.disponible)}!',
          excedido: true));
    } else if (general.nivel == NivelPresupuesto.cercaDelLimite) {
      alertas.add(AlertaPresupuesto(
          'Cuidado: ya usaste el ${(general.fraccionUsada * 100).toStringAsFixed(0)} % '
          'de tu presupuesto del mes.',
          excedido: false));
    }
    // también aviso si lo repartido en categorías ya pasa el total del mes
    final repartido =
        categorias.fold<double>(0, (s, c) => s + c.presupuesto.monto);
    if (general.existe && repartido > general.montoPresupuesto! + 0.001) {
      alertas.add(AlertaPresupuesto(
          'Tus categorías suman ${formatoMoneda(repartido)}, más que tu '
          'presupuesto del mes (${formatoMoneda(general.montoPresupuesto!)}).',
          excedido: false));
    }
    // y después reviso categoría por categoría con las mismas reglas
    for (final c in categorias) {
      if (c.nivel == NivelPresupuesto.excedido) {
        alertas.add(AlertaPresupuesto(
            '¡Te pasaste en ${c.nombre} por ${formatoMoneda(-c.disponible)}!',
            excedido: true));
      } else if (c.nivel == NivelPresupuesto.cercaDelLimite) {
        alertas.add(AlertaPresupuesto(
            '${c.nombre}: ya usaste el ${(c.fraccionUsada * 100).toStringAsFixed(0)} % '
            'de su presupuesto.',
            excedido: false));
      }
    }
    // convierto el bool a 1 o 0 para ordenar y que las rojas salgan primero
    alertas.sort((a, b) => (b.excedido ? 1 : 0) - (a.excedido ? 1 : 0));
    return alertas;
  }

  static DistribucionPresupuesto calcularDistribucion(
      EstadoPresupuesto general, List<EstadoCategoria> categorias) {
    return DistribucionPresupuesto(
      total: general.montoPresupuesto,
      categorias: categorias,
      gastadoTotal: general.gastado,
    );
  }

  /// El límite de una categoría no puede pasar lo que queda por repartir.
  /// Le doy 0.001 de margen para que no falle al comparar doubles con decimales.
  static String? validarMontoCategoria(double monto, double disponible) {
    if (monto <= 0) return 'El monto debe ser mayor a cero';
    if (monto > disponible + 0.001) {
      // si lo disponible es negativo muestro 0 para que no se vea raro
      return 'Supera lo disponible para repartir '
          '(${formatoMoneda(disponible < 0 ? 0 : disponible)})';
    }
    return null;
  }

  /// Al bajar el total del mes no dejo que quede por debajo de lo ya repartido.
  static String? validarTotalMes(double monto, double yaAsignado) {
    if (monto <= 0) return 'El monto debe ser mayor a cero';
    if (monto + 0.001 < yaAsignado) {
      return 'No puede ser menor a lo ya repartido en categorías '
          '(${formatoMoneda(yaAsignado)})';
    }
    return null;
  }

  /// El reporte no lo guardo en ninguna tabla, lo armo cada vez leyendo la BD.
  static Future<ReporteMensual> generarReporte(DateTime mes) async {
    final db = DatabaseHelper.instancia;
    // traigo solo los movimientos entre el primer y el último día del mes
    final transacciones = await db.obtenerTransacciones(
      desde: inicioMes(mes),
      hasta: finMes(mes),
    );
    final presupuesto = await db.obtenerPresupuesto(periodoDe(mes));
    final porCategoria = await db.obtenerPresupuestosCategoria(periodoDe(mes));

    return ReporteMensual(
      mes: mes,
      transacciones: transacciones,
      resumen: calcularResumen(transacciones),
      gastosPorCategoria: calcularGastosPorCategoria(transacciones),
      presupuesto: calcularEstadoPresupuesto(presupuesto, transacciones),
      presupuestosCategoria:
          calcularEstadosCategoria(porCategoria, transacciones),
    );
  }
}
