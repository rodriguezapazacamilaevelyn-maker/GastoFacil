// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/models/presupuesto_categoria.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Modelo para el límite que pongo a cada categoría en un mes.
// ============================================================

/// Límite de una categoría en un mes, por ejemplo Alimentación con
/// máximo Bs 600 en "2026-10".
class PresupuestoCategoria {
  final int? id;
  final String periodo; // "AAAA-MM"
  final int idCategoria; // apunta a categorias.id
  final double monto;
  final DateTime fechaActualizacion;

  // estos tres llegan del JOIN con categorias, los uso solo para mostrar
  final String? categoriaNombre;
  final int? categoriaColor;
  final String? categoriaIcono;

  const PresupuestoCategoria({
    this.id,
    required this.periodo,
    required this.idCategoria,
    required this.monto,
    required this.fechaActualizacion,
    this.categoriaNombre,
    this.categoriaColor,
    this.categoriaIcono,
  });

  // en el Map no meto los datos del JOIN porque no son columnas de esta tabla
  Map<String, Object?> toMap() => {
        'id': id,
        'periodo': periodo,
        'id_categoria': idCategoria,
        'monto': monto,
        'fecha_actualizacion': fechaActualizacion.toIso8601String(),
      };

  factory PresupuestoCategoria.fromMap(Map<String, Object?> mapa) =>
      PresupuestoCategoria(
        id: mapa['id'] as int?,
        periodo: mapa['periodo'] as String,
        idCategoria: mapa['id_categoria'] as int,
        monto: (mapa['monto'] as num).toDouble(),
        fechaActualizacion:
            DateTime.parse(mapa['fecha_actualizacion'] as String),
        // si la consulta no hizo JOIN estos quedan en null y no pasa nada
        categoriaNombre: mapa['categoria_nombre'] as String?,
        categoriaColor: mapa['categoria_color'] as int?,
        categoriaIcono: mapa['categoria_icono'] as String?,
      );
}
