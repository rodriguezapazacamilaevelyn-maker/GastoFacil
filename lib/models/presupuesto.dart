// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/models/presupuesto.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Modelo del presupuesto que el usuario pone para cada mes.
// ============================================================

/// El tope de gasto de un mes. El mes lo guardo como texto "AAAA-MM".
class Presupuesto {
  final int? id;
  final String periodo; // por ejemplo "2026-09"
  final double monto;
  final DateTime fechaActualizacion;

  const Presupuesto({
    this.id,
    required this.periodo,
    required this.monto,
    required this.fechaActualizacion,
  });

  // la fecha la guardo en ISO para que SQLite la tenga como texto
  Map<String, Object?> toMap() => {
        'id': id,
        'periodo': periodo,
        'monto': monto,
        'fecha_actualizacion': fechaActualizacion.toIso8601String(),
      };

  factory Presupuesto.fromMap(Map<String, Object?> mapa) => Presupuesto(
        id: mapa['id'] as int?,
        periodo: mapa['periodo'] as String,
        // uso num porque a veces SQLite devuelve int si el monto no tiene decimales
        monto: (mapa['monto'] as num).toDouble(),
        fechaActualizacion:
            DateTime.parse(mapa['fecha_actualizacion'] as String),
      );
}
