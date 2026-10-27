// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/utils/formato.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Funciones para mostrar montos y fechas y para validar montos.
// ============================================================

import 'package:intl/intl.dart';

// Las puse sueltas (sin clase) porque las uso en casi todas las pantallas.

// con 'es' sale punto para miles y coma para decimales
final NumberFormat _numero = NumberFormat('#,##0.00', 'es');

/// 1150.5  ->  "Bs 1.150,50"
String formatoMoneda(double monto) => 'Bs ${_numero.format(monto)}';

// los ingresos los muestro con "+" y los gastos con "-"
String formatoMontoConSigno(double monto, bool esIngreso) =>
    '${esIngreso ? '+' : '-'} ${formatoMoneda(monto)}';

/// 2026-09-29  ->  "29/09/2026"
String formatoFecha(DateTime fecha) => DateFormat('dd/MM/yyyy').format(fecha);

/// 2026-09-29  ->  "Septiembre 2026"
String nombreMes(DateTime fecha) {
  final texto = DateFormat('MMMM yyyy', 'es').format(fecha);
  // intl devuelve el mes en minúscula, así que pongo la primera letra en mayúscula
  return texto[0].toUpperCase() + texto.substring(1);
}

/// Así guardo la fecha en SQLite: "2026-09-29". Con el orden año-mes-día
/// puedo comparar fechas como texto en el WHERE.
String fechaParaBd(DateTime fecha) => DateFormat('yyyy-MM-dd').format(fecha);

// el período del presupuesto es solo año y mes, por ejemplo "2026-09"
String periodoDe(DateTime fecha) => DateFormat('yyyy-MM').format(fecha);

DateTime inicioMes(DateTime fecha) => DateTime(fecha.year, fecha.month, 1);

// truco: el día 0 del mes siguiente es el último día de este mes
DateTime finMes(DateTime fecha) => DateTime(fecha.year, fecha.month + 1, 0);

/// sumarMeses(sep-2026, -1) da ago-2026. DateTime solo corrige el año si paso de 12.
DateTime sumarMeses(DateTime fecha, int meses) =>
    DateTime(fecha.year, fecha.month + meses, 1);

/// Paso el texto a número aceptando "25,50" o "25.50"; si no se puede, null.
double? leerMonto(String? texto) {
  if (texto == null) return null;
  // cambio la coma por punto porque double solo entiende el punto
  final limpio = texto.trim().replaceAll(',', '.');
  if (limpio.isEmpty) return null;
  return double.tryParse(limpio);
}

/// Es el validator de los campos de monto: si está bien devuelvo null,
/// si no, el mensaje que se muestra debajo del campo.
String? validarMonto(String? texto) {
  if (texto == null || texto.trim().isEmpty) return 'Ingrese el monto';
  final valor = leerMonto(texto);
  if (valor == null) return 'El monto debe ser un número válido';
  if (valor <= 0) return 'El monto debe ser mayor a cero';
  // puse un tope para que no metan un número absurdo
  if (valor > 99999999) return 'El monto es demasiado alto';
  return null;
}
