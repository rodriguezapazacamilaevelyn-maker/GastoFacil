// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/db/database_helper.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Todo lo que tiene que ver con SQLite lo hago en esta clase.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/categoria.dart';
import '../models/presupuesto.dart';
import '../models/presupuesto_categoria.dart';
import '../models/transaccion.dart';
import '../utils/formato.dart';

/// Las pantallas no tocan SQLite directo, todo pasa por aquí.
/// La hice singleton para tener una sola instancia y una sola conexión abierta.
class DatabaseHelper {
  // constructor privado, así solo existe la instancia de abajo
  DatabaseHelper._();
  static final DatabaseHelper instancia = DatabaseHelper._();

  static const String nombreArchivo = 'gastofacil.db';
  // la subí a 2 cuando agregué la tabla presupuestos_categoria
  static const int _version = 2;

  /// Es un contador que sube cada vez que guardo, edito o borro algo.
  /// Las pantallas le ponen un listener y así se recargan solas.
  static final ValueNotifier<int> cambios = ValueNotifier<int>(0);

  Database? _db;

  /// La primera vez abre la base y después reutilizo la misma conexión.
  Future<Database> get database async {
    // ??= solo asigna si _db todavía es null
    _db ??= await _abrir();
    return _db!;
  }

  Future<Database> _abrir() async {
    // en web no existe carpeta de bases de datos, ahí basta con el nombre
    final ruta = kIsWeb
        ? nombreArchivo
        : join(await getDatabasesPath(), nombreArchivo);
    return openDatabase(
      ruta,
      version: _version,
      // SQLite trae las claves foráneas apagadas, las activo en cada conexión
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      // onCreate corre solo cuando el archivo no existía
      onCreate: _crearTablas,
      // migración: si el usuario tenía la versión 1, creo la tabla nueva sin borrar sus datos
      onUpgrade: (db, versionAnterior, versionNueva) async {
        if (versionAnterior < 2) await _crearTablaPresupuestoCategoria(db);
      },
    );
  }

  // al cambiar value se avisa a todos los que están escuchando
  void _notificar() => cambios.value++;

  // ----- Creación de tablas y datos iniciales -----

  /// Creo las tablas la primera vez y meto las categorías que vienen por defecto.
  Future<void> _crearTablas(Database db, int version) async {
    // el UNIQUE (nombre, tipo) es para que no se repita una categoría
    await db.execute('''
      CREATE TABLE categorias (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre      TEXT    NOT NULL,
        tipo        TEXT    NOT NULL CHECK (tipo IN ('ingreso', 'gasto')),
        icono       TEXT    NOT NULL,
        color       INTEGER NOT NULL,
        predefinida INTEGER NOT NULL DEFAULT 0,
        UNIQUE (nombre, tipo)
      )''');

    // con RESTRICT no deja borrar una categoría que todavía tiene movimientos
    await db.execute('''
      CREATE TABLE transacciones (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo         TEXT    NOT NULL CHECK (tipo IN ('ingreso', 'gasto')),
        titulo       TEXT    NOT NULL,
        monto        REAL    NOT NULL CHECK (monto > 0),
        fecha        TEXT    NOT NULL,
        descripcion  TEXT,
        id_categoria INTEGER NOT NULL,
        FOREIGN KEY (id_categoria) REFERENCES categorias (id)
          ON DELETE RESTRICT
      )''');

    // casi siempre filtro por fecha, con el índice esas consultas van más rápido
    await db.execute(
        'CREATE INDEX idx_transacciones_fecha ON transacciones (fecha)');

    await db.execute('''
      CREATE TABLE presupuestos (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        periodo             TEXT    NOT NULL UNIQUE,
        monto               REAL    NOT NULL CHECK (monto > 0),
        fecha_actualizacion TEXT    NOT NULL
      )''');

    await _crearTablaPresupuestoCategoria(db);

    // con batch mando todos los insert juntos en vez de uno por uno
    final lote = db.batch();
    for (final c in categoriasPredefinidas) {
      lote.insert('categorias', c.toMap());
    }
    // noResult porque no necesito los ids que devuelve
    await lote.commit(noResult: true);
  }

  /// La separé en su propio método porque la llamo desde onCreate y desde la migración.
  /// Un solo límite por categoría y mes; si borran la categoría se borra con CASCADE.
  static Future<void> _crearTablaPresupuestoCategoria(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS presupuestos_categoria (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        periodo             TEXT    NOT NULL,
        id_categoria        INTEGER NOT NULL,
        monto               REAL    NOT NULL CHECK (monto > 0),
        fecha_actualizacion TEXT    NOT NULL,
        UNIQUE (periodo, id_categoria),
        FOREIGN KEY (id_categoria) REFERENCES categorias (id)
          ON DELETE CASCADE
      )''');
  }

  // las categorías con las que arranca la app, el color es el índice de la paleta
  static const List<Categoria> categoriasPredefinidas = [
    Categoria(nombre: 'Alimentación', tipo: TipoMovimiento.gasto, icono: 'comida', color: 0, predefinida: true),
    Categoria(nombre: 'Transporte', tipo: TipoMovimiento.gasto, icono: 'transporte', color: 1, predefinida: true),
    Categoria(nombre: 'Servicios', tipo: TipoMovimiento.gasto, icono: 'servicios', color: 2, predefinida: true),
    Categoria(nombre: 'Salud', tipo: TipoMovimiento.gasto, icono: 'salud', color: 4, predefinida: true),
    Categoria(nombre: 'Educación', tipo: TipoMovimiento.gasto, icono: 'educacion', color: 5, predefinida: true),
    Categoria(nombre: 'Entretenimiento', tipo: TipoMovimiento.gasto, icono: 'ocio', color: 8, predefinida: true),
    Categoria(nombre: 'Ropa', tipo: TipoMovimiento.gasto, icono: 'ropa', color: 6, predefinida: true),
    Categoria(nombre: 'Otros gastos', tipo: TipoMovimiento.gasto, icono: 'otros', color: 7, predefinida: true),
    Categoria(nombre: 'Salario', tipo: TipoMovimiento.ingreso, icono: 'trabajo', color: 3, predefinida: true),
    Categoria(nombre: 'Mesada', tipo: TipoMovimiento.ingreso, icono: 'billetera', color: 5, predefinida: true),
    Categoria(nombre: 'Ventas', tipo: TipoMovimiento.ingreso, icono: 'ventas', color: 1, predefinida: true),
    Categoria(nombre: 'Otros ingresos', tipo: TipoMovimiento.ingreso, icono: 'otros', color: 9, predefinida: true),
  ];

  // ----- Transacciones -----

  /// Traigo los movimientos con su categoría. Todos los filtros son opcionales,
  /// así uso el mismo método para el inicio, el historial y los reportes.
  Future<List<Transaccion>> obtenerTransacciones({
    DateTime? desde,
    DateTime? hasta,
    int? idCategoria,
    String? tipo,
    int? limite,
  }) async {
    final db = await database;
    // voy armando el WHERE solo con los filtros que me pasaron
    final condiciones = <String>[];
    final argumentos = <Object?>[];

    if (desde != null) {
      condiciones.add('t.fecha >= ?');
      argumentos.add(fechaParaBd(desde));
    }
    if (hasta != null) {
      condiciones.add('t.fecha <= ?');
      argumentos.add(fechaParaBd(hasta));
    }
    if (idCategoria != null) {
      condiciones.add('t.id_categoria = ?');
      argumentos.add(idCategoria);
    }
    if (tipo != null) {
      condiciones.add('t.tipo = ?');
      argumentos.add(tipo);
    }

    // si no hay filtros, el WHERE queda vacío y trae todo
    final where =
        condiciones.isEmpty ? '' : 'WHERE ${condiciones.join(' AND ')}';
    final limit = limite == null ? '' : 'LIMIT $limite';

    // los valores van en los "?" y sqflite los pasa aparte, así evito inyección SQL
    final filas = await db.rawQuery('''
      SELECT t.*, c.nombre AS categoria_nombre,
             c.color AS categoria_color, c.icono AS categoria_icono
      FROM transacciones t
      JOIN categorias c ON c.id = t.id_categoria
      $where
      ORDER BY t.fecha DESC, t.id DESC
      $limit''', argumentos);

    return filas.map(Transaccion.fromMap).toList();
  }

  Future<int> insertarTransaccion(Transaccion t) async {
    final db = await database;
    final mapa = t.toMap()..remove('id'); // quito el id para que SQLite ponga el suyo
    final id = await db.insert('transacciones', mapa);
    _notificar();
    return id;
  }

  Future<void> actualizarTransaccion(Transaccion t) async {
    final db = await database;
    // actualizo solo la fila que tiene ese id
    await db.update('transacciones', t.toMap(),
        where: 'id = ?', whereArgs: [t.id]);
    _notificar();
  }

  Future<void> eliminarTransaccion(int id) async {
    final db = await database;
    await db.delete('transacciones', where: 'id = ?', whereArgs: [id]);
    _notificar();
  }

  // ----- Categorías -----

  /// Primero salen las predefinidas y después las del usuario, por nombre.
  Future<List<Categoria>> obtenerCategorias({String? tipo}) async {
    final db = await database;
    final filas = await db.query(
      'categorias',
      // si no me pasan tipo, no filtro nada
      where: tipo == null ? null : 'tipo = ?',
      whereArgs: tipo == null ? null : [tipo],
      orderBy: 'predefinida DESC, nombre ASC',
    );
    return filas.map(Categoria.fromMap).toList();
  }

  /// Si ya hay una con el mismo nombre y tipo, el UNIQUE hace que tire error
  /// y ese error lo atrapo en la pantalla.
  Future<int> insertarCategoria(Categoria c) async {
    final db = await database;
    final mapa = c.toMap()..remove('id');
    final id = await db.insert('categorias', mapa);
    _notificar();
    return id;
  }

  /// Lo uso antes de borrar una categoría, para saber si tiene movimientos.
  Future<int> contarTransaccionesDeCategoria(int idCategoria) async {
    final db = await database;
    final r = await db.rawQuery(
        'SELECT COUNT(*) AS total FROM transacciones WHERE id_categoria = ?',
        [idCategoria]);
    return (r.first['total'] as int?) ?? 0;
  }

  Future<void> eliminarCategoria(int id) async {
    final db = await database;
    // el predefinida = 0 es un seguro extra para no borrar las que vienen con la app
    await db.delete('categorias',
        where: 'id = ? AND predefinida = 0', whereArgs: [id]);
    _notificar();
  }

  // ----- Presupuesto mensual -----

  /// Si ese mes no tiene presupuesto me da null.
  Future<Presupuesto?> obtenerPresupuesto(String periodo) async {
    final db = await database;
    final filas = await db.query('presupuestos',
        where: 'periodo = ?', whereArgs: [periodo], limit: 1);
    if (filas.isEmpty) return null;
    return Presupuesto.fromMap(filas.first);
  }

  /// Sirve para crear y para editar: intento el update y si no tocó
  /// ninguna fila es que no existía, entonces hago el insert.
  Future<void> guardarPresupuesto(String periodo, double monto) async {
    final db = await database;
    final datos = {
      'periodo': periodo,
      'monto': monto,
      'fecha_actualizacion': DateTime.now().toIso8601String(),
    };
    final actualizados = await db.update('presupuestos', datos,
        where: 'periodo = ?', whereArgs: [periodo]);
    if (actualizados == 0) {
      await db.insert('presupuestos', datos);
    }
    _notificar();
  }

  // ----- Presupuesto por categoría -----

  /// Los límites del mes con el nombre y color de la categoría (por el JOIN).
  Future<List<PresupuestoCategoria>> obtenerPresupuestosCategoria(
      String periodo) async {
    final db = await database;
    final filas = await db.rawQuery('''
      SELECT p.*, c.nombre AS categoria_nombre,
             c.color AS categoria_color, c.icono AS categoria_icono
      FROM presupuestos_categoria p
      JOIN categorias c ON c.id = p.id_categoria
      WHERE p.periodo = ?
      ORDER BY c.nombre''', [periodo]);
    return filas.map(PresupuestoCategoria.fromMap).toList();
  }

  /// Igual que guardarPresupuesto: primero update y si no había fila, insert.
  Future<void> guardarPresupuestoCategoria(
      String periodo, int idCategoria, double monto) async {
    final db = await database;
    final datos = {
      'periodo': periodo,
      'id_categoria': idCategoria,
      'monto': monto,
      'fecha_actualizacion': DateTime.now().toIso8601String(),
    };
    // acá busco por mes y categoría juntos, por eso van dos "?"
    final actualizados = await db.update('presupuestos_categoria', datos,
        where: 'periodo = ? AND id_categoria = ?',
        whereArgs: [periodo, idCategoria]);
    if (actualizados == 0) {
      await db.insert('presupuestos_categoria', datos);
    }
    _notificar();
  }

  Future<void> eliminarPresupuestoCategoria(int id) async {
    final db = await database;
    await db.delete('presupuestos_categoria', where: 'id = ?', whereArgs: [id]);
    _notificar();
  }

  // ----- Copia de respaldo -----

  /// Junto todas las tablas en un Map para después convertirlo a JSON.
  Future<Map<String, Object?>> exportarDatos() async {
    final db = await database;
    return {
      'categorias': await db.query('categorias'),
      'transacciones': await db.query('transacciones'),
      'presupuestos': await db.query('presupuestos'),
      'presupuestos_categoria': await db.query('presupuestos_categoria'),
    };
  }

  /// Cambio todos los datos por los de la copia. Lo hago dentro de una
  /// transacción para que, si algo falla a la mitad, no se pierda nada.
  Future<void> importarDatos(Map<String, dynamic> datos) async {
    final db = await database;
    // las copias viejas no tienen presupuestos_categoria, ahí uso lista vacía
    List<Map<String, Object?>> lista(String clave) =>
        ((datos[clave] as List?) ?? const [])
            .map((e) => Map<String, Object?>.from(e as Map))
            .toList();

    final categorias = lista('categorias');
    final transacciones = lista('transacciones');
    final presupuestos = lista('presupuestos');
    final presupuestosCategoria = lista('presupuestos_categoria');

    await db.transaction((txn) async {
      // por las claves foráneas borro primero las tablas hijas y al final categorías
      await txn.delete('presupuestos_categoria');
      await txn.delete('transacciones');
      await txn.delete('presupuestos');
      await txn.delete('categorias');
      // y al insertar es al revés: primero categorías para que existan los id
      for (final c in categorias) {
        await txn.insert('categorias', c);
      }
      for (final t in transacciones) {
        await txn.insert('transacciones', t);
      }
      for (final p in presupuestos) {
        await txn.insert('presupuestos', p);
      }
      for (final pc in presupuestosCategoria) {
        await txn.insert('presupuestos_categoria', pc);
      }
    });
    _notificar();
  }
}
