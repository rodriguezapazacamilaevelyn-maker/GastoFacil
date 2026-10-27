// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/widgets/item_transaccion.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : La fila que muestra cada movimiento en las listas.
// ============================================================

import 'package:flutter/material.dart';

import '../models/transaccion.dart';
import '../utils/formato.dart';
import '../utils/tema.dart';

/// Cada movimiento en Inicio e Historial. El monto sale verde si es
/// ingreso y rojo si es gasto.
class ItemTransaccion extends StatelessWidget {
  final Transaccion transaccion;
  final VoidCallback? onTap; // opcional, por si en algún lado no quiero que se toque

  const ItemTransaccion({super.key, required this.transaccion, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = transaccion;
    // si no vino el color de la categoría uso el 7 (gris azulado)
    final colorCat = TemaApp.colorCategoria(t.categoriaColor ?? 7);
    final colorMonto = t.esIngreso ? TemaApp.ingreso : TemaApp.gasto;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: colorCat.withAlpha(40),
        child: Icon(TemaApp.icono(t.categoriaIcono ?? 'otros'),
            color: colorCat, size: 22),
      ),
      // maxLines 1 con ellipsis para que un título largo no rompa la fila
      title: Text(t.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
          '${t.categoriaNombre ?? 'Sin categoría'} · ${formatoFecha(t.fecha)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: Text(
        formatoMontoConSigno(t.monto, t.esIngreso),
        style: TextStyle(
            color: colorMonto, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}
