// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/models/categoria.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Modelo de las categorías y las constantes de ingreso/gasto.
// ============================================================

/// Puse los tipos como constantes para no escribir 'gasto' a mano y equivocarme.
class TipoMovimiento {
  // el constructor privado es para que nadie haga TipoMovimiento()
  TipoMovimiento._();
  static const String ingreso = 'ingreso';
  static const String gasto = 'gasto';
}

/// Una categoría como Alimentación o Salario. Algunas vienen con la app
/// y otras las crea el usuario.
class Categoria {
  final int? id; // queda en null hasta que SQLite le asigna uno
  final String nombre;
  final String tipo; // 'ingreso' o 'gasto'
  final String icono; // es la clave que busco en TemaApp.iconos
  final int color; // posición del color en TemaApp.paleta
  final bool predefinida;

  const Categoria({
    this.id,
    required this.nombre,
    required this.tipo,
    required this.icono,
    required this.color,
    this.predefinida = false,
  });

  /// Paso la categoría a Map para guardarla; SQLite no tiene bool, así que uso 1 y 0.
  Map<String, Object?> toMap() => {
        'id': id,
        'nombre': nombre,
        'tipo': tipo,
        'icono': icono,
        'color': color,
        'predefinida': predefinida ? 1 : 0,
      };

  /// Armo la categoría desde la fila que me devuelve la consulta.
  factory Categoria.fromMap(Map<String, Object?> mapa) => Categoria(
        id: mapa['id'] as int?,
        nombre: mapa['nombre'] as String,
        tipo: mapa['tipo'] as String,
        icono: mapa['icono'] as String,
        color: mapa['color'] as int,
        // si viene null lo tomo como 0, o sea creada por el usuario
        predefinida: (mapa['predefinida'] as int? ?? 0) == 1,
      );
}
