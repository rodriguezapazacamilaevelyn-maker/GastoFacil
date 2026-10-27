// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/utils/tema.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Los colores, íconos y el tema que uso en toda la app.
// ============================================================

import 'package:flutter/material.dart';

/// Tengo los colores e íconos en un solo lugar para que todas las
/// pantallas se vean iguales y si cambio algo, cambia en todas.
class TemaApp {
  TemaApp._(); // solo guarda constantes, no hace falta crear objetos

  // ---------- Colores principales ----------
  static const Color primario = Color(0xFF00796B); // verde azulado
  static const Color primarioOscuro = Color(0xFF004D40);
  static const Color primarioClaro = Color(0xFFB2DFDB);
  static const Color ingreso = Color(0xFF2E7D32); // verde
  static const Color gasto = Color(0xFFC62828); // rojo
  static const Color alerta = Color(0xFFEF6C00); // naranja
  static const Color fondo = Color(0xFFF4F7F6);
  static const Color textoSuave = Color(0xFF6B7280);

  // colores para las categorías; en la BD no guardo el color, solo su posición
  static const List<Color> paleta = [
    Color(0xFFE67E22), // 0 naranja
    Color(0xFF3498DB), // 1 azul
    Color(0xFF9B59B6), // 2 morado
    Color(0xFF2ECC71), // 3 verde
    Color(0xFFE74C3C), // 4 rojo
    Color(0xFF1ABC9C), // 5 turquesa
    Color(0xFFF1C40F), // 6 amarillo
    Color(0xFF34495E), // 7 gris azulado
    Color(0xFFEC407A), // 8 rosado
    Color(0xFF8D6E63), // 9 café
  ];

  // uso abs y el módulo para que un índice raro no se salga de la lista
  static Color colorCategoria(int indice) =>
      paleta[indice.abs() % paleta.length];

  // en la BD queda la clave (por ejemplo 'comida') y aquí la paso al ícono
  static const Map<String, IconData> iconos = {
    'comida': Icons.restaurant,
    'transporte': Icons.directions_bus,
    'servicios': Icons.bolt,
    'salud': Icons.local_hospital,
    'educacion': Icons.school,
    'ocio': Icons.movie,
    'ropa': Icons.checkroom,
    'hogar': Icons.home,
    'telefono': Icons.phone_android,
    'mascota': Icons.pets,
    'regalo': Icons.card_giftcard,
    'trabajo': Icons.work,
    'billetera': Icons.account_balance_wallet,
    'ventas': Icons.storefront,
    'ahorro': Icons.savings,
    'otros': Icons.more_horiz,
  };

  // si la clave no existe pongo una etiqueta genérica para que no se rompa
  static IconData icono(String clave) => iconos[clave] ?? Icons.label;

  /// Tema con Material 3; a partir del color primario se arma el resto del esquema.
  static ThemeData claro() {
    final esquema = ColorScheme.fromSeed(
      seedColor: primario,
      primary: primario,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: fondo,
      appBarTheme: const AppBarTheme(
        backgroundColor: primario,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }

  /// La decoración que comparten todos los campos de los formularios.
  static InputDecoration campo(String etiqueta, IconData icono,
      {String? prefijo, String? ayuda}) {
    return InputDecoration(
      labelText: etiqueta,
      prefixIcon: Icon(icono),
      prefixText: prefijo,
      helperText: ayuda,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // borde redondeado con línea gris suave para las tarjetas
  static RoundedRectangleBorder bordeTarjeta() => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE0E6E4)),
      );
}
