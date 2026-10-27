// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/models/transaccion.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Modelo de cada movimiento, sea ingreso o gasto.
// ============================================================

import 'categoria.dart';

/// Cada ingreso o gasto que registra el usuario.
class Transaccion {
  final int? id;
  final String tipo; // 'ingreso' o 'gasto'
  final String titulo;
  final double monto; // lo guardo siempre positivo, el tipo dice si suma o resta
  final DateTime fecha;
  final String? descripcion; // es opcional
  final int idCategoria; // apunta a categorias.id

  // vienen del JOIN para mostrar la categoría, no son columnas de transacciones
  final String? categoriaNombre;
  final int? categoriaColor;
  final String? categoriaIcono;

  const Transaccion({
    this.id,
    required this.tipo,
    required this.titulo,
    required this.monto,
    required this.fecha,
    this.descripcion,
    required this.idCategoria,
    this.categoriaNombre,
    this.categoriaColor,
    this.categoriaIcono,
  });

  // atajos para no comparar el texto del tipo en cada pantalla
  bool get esIngreso => tipo == TipoMovimiento.ingreso;
  bool get esGasto => tipo == TipoMovimiento.gasto;

  /// Lo paso a Map para la tabla; la fecha va sin hora, como "AAAA-MM-DD".
  Map<String, Object?> toMap() => {
        'id': id,
        'tipo': tipo,
        'titulo': titulo,
        'monto': monto,
        'fecha': _fechaTexto(fecha),
        'descripcion': descripcion,
        'id_categoria': idCategoria,
      };

  /// Leo la fila; si la consulta tenía JOIN también me llegan los datos de la categoría.
  factory Transaccion.fromMap(Map<String, Object?> mapa) => Transaccion(
        id: mapa['id'] as int?,
        tipo: mapa['tipo'] as String,
        titulo: mapa['titulo'] as String,
        monto: (mapa['monto'] as num).toDouble(),
        fecha: DateTime.parse(mapa['fecha'] as String),
        descripcion: mapa['descripcion'] as String?,
        idCategoria: mapa['id_categoria'] as int,
        categoriaNombre: mapa['categoria_nombre'] as String?,
        categoriaColor: mapa['categoria_color'] as int?,
        categoriaIcono: mapa['categoria_icono'] as String?,
      );

  // relleno con ceros (padLeft) para que las fechas se ordenen bien como texto
  static String _fechaTexto(DateTime f) =>
      '${f.year.toString().padLeft(4, '0')}-'
      '${f.month.toString().padLeft(2, '0')}-'
      '${f.day.toString().padLeft(2, '0')}';
}
