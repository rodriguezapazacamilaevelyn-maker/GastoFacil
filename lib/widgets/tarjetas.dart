// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/widgets/tarjetas.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Tarjetas que reutilizo en varias pantallas (balance, presupuesto, alertas).
// ============================================================

import 'package:flutter/material.dart';

import '../services/finanzas_service.dart';
import '../utils/formato.dart';
import '../utils/tema.dart';

// Estas tarjetas salen en Inicio, Presupuesto y Reportes; las hice
// una sola vez aquí para no copiar el mismo código en cada pantalla.

/// La tarjeta verde de arriba con el balance, los ingresos y los gastos.
class TarjetaBalance extends StatelessWidget {
  final ResumenFinanciero resumen;
  final String titulo;

  const TarjetaBalance(
      {super.key, required this.resumen, this.titulo = 'Balance del mes'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // degradado en diagonal con los dos verdes del tema
        gradient: const LinearGradient(
          colors: [TemaApp.primario, TemaApp.primarioOscuro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(titulo,
              style: const TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 6),
          // FittedBox achica el número si es muy grande, así no se sale de la tarjeta
          FittedBox(
            child: Text(
              formatoMoneda(resumen.balance),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniTotal(
                    etiqueta: 'Ingresos',
                    monto: resumen.ingresos,
                    icono: Icons.arrow_upward,
                    color: const Color(0xFFA5D6A7)),
              ),
              // la rayita blanca que separa ingresos de gastos
              Container(width: 1, height: 36, color: Colors.white24),
              Expanded(
                child: _MiniTotal(
                    etiqueta: 'Gastos',
                    monto: resumen.gastos,
                    icono: Icons.arrow_downward,
                    color: const Color(0xFFFFAB91)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// el total chiquito de ingresos o gastos que va dentro de la tarjeta de balance
class _MiniTotal extends StatelessWidget {
  final String etiqueta;
  final double monto;
  final IconData icono;
  final Color color;

  const _MiniTotal(
      {required this.etiqueta,
      required this.monto,
      required this.icono,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 16, color: color),
            const SizedBox(width: 4),
            // con Flexible la etiqueta se corta con "..." si no cabe en celulares chicos
            Flexible(
              child: Text(etiqueta,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 2),
        FittedBox(
          child: Text(formatoMoneda(monto),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

/// Tarjeta blanca con un título arriba; la uso para agrupar cada sección.
class TarjetaSeccion extends StatelessWidget {
  final String titulo;
  final Widget child;
  final Widget? accion; // botón opcional que va a la derecha del título

  const TarjetaSeccion(
      {super.key, required this.titulo, required this.child, this.accion});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: TemaApp.bordeTarjeta(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // el Expanded deja al título ocupar lo que sobra y el botón queda a la derecha
                Expanded(
                  child: Text(titulo,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                if (accion != null) accion!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Barra de avance del presupuesto: verde normal, naranja desde 80 % y roja si se pasó.
class BarraPresupuesto extends StatelessWidget {
  final EstadoPresupuesto estado;
  const BarraPresupuesto({super.key, required this.estado});

  // la hice static para usar el mismo color en textos de otras pantallas
  static Color colorDe(NivelPresupuesto nivel) {
    switch (nivel) {
      case NivelPresupuesto.excedido:
        return TemaApp.gasto;
      case NivelPresupuesto.cercaDelLimite:
        return TemaApp.alerta;
      default:
        return TemaApp.primario;
    }
  }

  @override
  Widget build(BuildContext context) {
    // con clamp la barra no pasa de llena aunque se haya gastado más del 100 %
    final valor = estado.fraccionUsada.clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: valor,
        minHeight: 12,
        backgroundColor: const Color(0xFFE5E7EB),
        valueColor: AlwaysStoppedAnimation<Color>(colorDe(estado.nivel)),
      ),
    );
  }
}

/// Versión corta del presupuesto para el inicio; al tocarla va a la pestaña Presupuesto.
class TarjetaPresupuesto extends StatelessWidget {
  final EstadoPresupuesto estado;
  final VoidCallback onTap;

  const TarjetaPresupuesto(
      {super.key, required this.estado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final porcentaje = (estado.fraccionUsada * 100).toStringAsFixed(0);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: TarjetaSeccion(
        titulo: 'Presupuesto del mes',
        accion: const Icon(Icons.chevron_right, color: TemaApp.textoSuave),
        // si no hay presupuesto solo invito a crearlo
        child: !estado.existe
            ? const Text(
                'Aún no estableciste tu presupuesto inicial. Toca aquí para definirlo.',
                style: TextStyle(color: TemaApp.textoSuave))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatoMoneda(estado.gastado)} de '
                    '${formatoMoneda(estado.montoPresupuesto!)} usados ($porcentaje %)',
                    style: const TextStyle(color: TemaApp.textoSuave),
                  ),
                  const SizedBox(height: 10),
                  BarraPresupuesto(estado: estado),
                  const SizedBox(height: 8),
                  // disponible negativo quiere decir que se pasó, por eso cambio el texto
                  Text(
                    estado.disponible >= 0
                        ? 'Disponible: ${formatoMoneda(estado.disponible)}'
                        : 'Excedido por: ${formatoMoneda(-estado.disponible)}',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: BarraPresupuesto.colorDe(estado.nivel)),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Lo muestro cuando una lista está vacía o cuando algo falló al cargar.
class MensajeVacio extends StatelessWidget {
  final IconData icono;
  final String texto;
  const MensajeVacio({super.key, required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Icon(icono, size: 48, color: TemaApp.primarioClaro),
          const SizedBox(height: 8),
          Text(texto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: TemaApp.textoSuave)),
        ],
      ),
    );
  }
}

/// Cuadro de avisos cuando el usuario se pasó o está cerca de su límite.
class PanelAlertas extends StatelessWidget {
  final List<AlertaPresupuesto> alertas;
  const PanelAlertas({super.key, required this.alertas});

  @override
  Widget build(BuildContext context) {
    // SizedBox.shrink es un widget vacío que no ocupa espacio
    if (alertas.isEmpty) return const SizedBox.shrink();
    // con que haya una de excedido, todo el panel va en rojo
    final hayExceso = alertas.any((a) => a.excedido);
    final color = hayExceso ? TemaApp.gasto : TemaApp.alerta;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color),
              const SizedBox(width: 8),
              // con Expanded el título usa solo el espacio libre y no se sale en pantallas chicas
              Expanded(
                child: Text(
                    hayExceso ? '¡Alerta de presupuesto!' : 'Atención',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // cada alerta con su propio ícono: la X roja si se pasó, la i naranja si está cerca
          for (final a in alertas)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(a.excedido ? Icons.cancel : Icons.info_outline,
                      size: 16,
                      color: a.excedido ? TemaApp.gasto : TemaApp.alerta),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(a.mensaje,
                          style: const TextStyle(fontSize: 13.5))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Una categoría con límite: cuánto gastó de cuánto, su barra y lo que le queda.
class ItemPresupuestoCategoria extends StatelessWidget {
  final EstadoCategoria estado;
  final VoidCallback? onTap;
  final VoidCallback? onEliminar; // en Reportes no lo paso y no sale la X

  const ItemPresupuestoCategoria(
      {super.key, required this.estado, this.onTap, this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final p = estado.presupuesto;
    final colorCat = TemaApp.colorCategoria(p.categoriaColor ?? 7);
    final colorNivel = BarraPresupuesto.colorDe(estado.nivel);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorCat.withAlpha(40),
                  child: Icon(TemaApp.icono(p.categoriaIcono ?? 'otros'),
                      color: colorCat, size: 18),
                ),
                const SizedBox(width: 10),
                // antes el nombre y los montos iban en una sola fila y se desbordaban;
                // ahora van en dos líneas dentro del Expanded
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(estado.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                          '${formatoMoneda(estado.gastado)} de '
                          '${formatoMoneda(p.monto)}',
                          style: const TextStyle(
                              fontSize: 13, color: TemaApp.textoSuave)),
                    ],
                  ),
                ),
                if (onEliminar != null)
                  IconButton(
                    tooltip: 'Quitar presupuesto',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onEliminar,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // comoEstado convierte la categoría en EstadoPresupuesto para reusar la barra
            BarraPresupuesto(estado: estado.comoEstado),
            const SizedBox(height: 4),
            Text(
              estado.disponible >= 0
                  ? 'Disponible: ${formatoMoneda(estado.disponible)}'
                  : 'Te pasaste por ${formatoMoneda(-estado.disponible)}',
              style: TextStyle(
                  fontSize: 12.5,
                  color: colorNivel,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// SnackBar verde para confirmar que algo se guardó, cambió o borró.
SnackBar avisoExito(String texto, {IconData icono = Icons.check_circle}) {
  return SnackBar(
    backgroundColor: TemaApp.ingreso,
    // floating hace que flote un poco arriba y no tape la barra de abajo
    behavior: SnackBarBehavior.floating,
    content: Row(
      children: [
        Icon(icono, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(texto)),
      ],
    ),
  );
}

/// Muestra cómo se repartió el total del mes: una barra de colores
/// (gris es lo sin asignar) y abajo el detalle con los montos.
class TarjetaDistribucion extends StatelessWidget {
  final DistribucionPresupuesto distribucion;
  const TarjetaDistribucion({super.key, required this.distribucion});

  @override
  Widget build(BuildContext context) {
    final d = distribucion;
    if (!d.existe) {
      return const MensajeVacio(
        icono: Icons.pie_chart_outline,
        texto: 'Primero establece el presupuesto del mes. Luego podrás '
            'repartirlo entre tus categorías.',
      );
    }
    final total = d.total!;
    // si se repartió de más, lo libre lo tomo como 0 para no dibujar algo negativo
    final libre = d.sinAsignar > 0 ? d.sinAsignar : 0.0;
    final base = d.asignado + libre; // esto es el 100 % del ancho de la barra

    // fila del detalle: algo a la izquierda (ícono o punto), el texto y el monto
    Widget fila(Widget inicio, String texto, String monto,
            {Color? color, bool negrita = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              inicio,
              const SizedBox(width: 8),
              Expanded(
                  child: Text(texto,
                      style: TextStyle(
                          fontWeight:
                              negrita ? FontWeight.bold : FontWeight.normal))),
              Text(monto,
                  style: TextStyle(
                      color: color,
                      fontWeight: negrita ? FontWeight.bold : FontWeight.w600)),
            ],
          ),
        );

    // el puntito de color de cada categoría
    Widget punto(Color c) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle));

    // porcentaje de un monto sobre el total, entre paréntesis
    String pct(double v) =>
        total <= 0 ? '' : ' (${(v * 100 / total).toStringAsFixed(0)} %)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // barra apilada: cada franja es un Expanded y el flex es su parte del total
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 18,
            child: Row(
              children: [
                for (final c in d.categorias)
                  if (base > 0 && c.presupuesto.monto > 0)
                    Expanded(
                      // flex tiene que ser entero, por eso multiplico por 1000;
                      // el clamp en 1 es para que una franja muy chica igual se vea
                      flex: (c.presupuesto.monto * 1000 / base).round().clamp(1, 1000).toInt(),
                      child: Container(
                          color: TemaApp.colorCategoria(
                              c.presupuesto.categoriaColor ?? 7)),
                    ),
                // al final va la parte gris que todavía no se asignó
                if (libre > 0 && base > 0)
                  Expanded(
                    flex: (libre * 1000 / base).round().clamp(1, 1000).toInt(),
                    child: Container(color: const Color(0xFFD1D5DB)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        fila(const Icon(Icons.account_balance_wallet_outlined, size: 18),
            'Presupuesto total del mes', formatoMoneda(total),
            negrita: true, color: TemaApp.primario),
        // a cada categoría la muestro como una resta del total
        for (final c in d.categorias)
          fila(
            punto(TemaApp.colorCategoria(c.presupuesto.categoriaColor ?? 7)),
            '${c.nombre}${pct(c.presupuesto.monto)}',
            '− ${formatoMoneda(c.presupuesto.monto)}',
          ),
        const Divider(),
        // lo que sobra; si se repartió de más lo pinto en rojo
        fila(
          punto(const Color(0xFFD1D5DB)),
          d.excedeTotal ? 'Repartido de más' : 'Sin asignar (otros gastos)',
          formatoMoneda(d.sinAsignar.abs()),
          negrita: true,
          color: d.excedeTotal ? TemaApp.gasto : TemaApp.ingreso,
        ),
        // estas dos filas solo salen si hubo gastos en categorías sin límite propio
        if (d.gastadoOtros > 0)
          fila(const SizedBox(width: 12), 'Gastado en otras categorías',
              '− ${formatoMoneda(d.gastadoOtros)}'),
        if (d.gastadoOtros > 0)
          fila(
            const SizedBox(width: 12),
            d.disponibleOtros >= 0
                ? 'Queda para otros gastos'
                : 'Otros gastos se pasaron por',
            formatoMoneda(d.disponibleOtros.abs()),
            color: d.disponibleOtros >= 0 ? TemaApp.ingreso : TemaApp.gasto,
            negrita: true,
          ),
        const SizedBox(height: 8),
        // texto de resumen; cuido el singular y plural de "categoría"
        Text(
          d.categorias.isEmpty
              ? 'Aún no repartiste tu presupuesto. Usa "Asignar" para darle '
                  'una parte a cada categoría.'
              : 'Repartiste el ${d.porcentajeAsignado.toStringAsFixed(0)} % '
                  'de tu presupuesto en ${d.categorias.length} '
                  '${d.categorias.length == 1 ? 'categoría' : 'categorías'}.',
          style: const TextStyle(color: TemaApp.textoSuave, fontSize: 12.5),
        ),
      ],
    );
  }
}
