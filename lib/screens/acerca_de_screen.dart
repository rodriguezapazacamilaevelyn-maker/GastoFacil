// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/screens/acerca_de_screen.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : Pantalla con los datos de la app, del proyecto y las tecnologías.
// ============================================================

import 'package:flutter/material.dart';

import '../db/plataforma_bd.dart';
import '../utils/tema.dart';
import '../widgets/tarjetas.dart';

/// Muestra la versión, la plataforma, mis datos y con qué hice la app.
class AcercaDeScreen extends StatelessWidget {
  const AcercaDeScreen({super.key});

  static const String version = '1.2.0';

  @override
  Widget build(BuildContext context) {
    // función local para no repetir el mismo ListTile en cada dato
    Widget dato(IconData icono, String titulo, String valor) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icono, color: TemaApp.primario),
          title: Text(titulo,
              style: const TextStyle(
                  fontSize: 13, color: TemaApp.textoSuave)),
          subtitle: Text(valor,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // el logo es un círculo con degradado y el ícono de billetera
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [TemaApp.primario, TemaApp.primarioOscuro],
                ),
              ),
              child: const Icon(Icons.account_balance_wallet,
                  color: Colors.white, size: 52),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text('GastoFácil',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          ),
          // nombrePlataforma sale del import condicional, en web dice "Web"
          Center(
            child: Text('Versión $version · ${nombrePlataforma()}',
                style: const TextStyle(color: TemaApp.textoSuave)),
          ),
          const SizedBox(height: 16),
          const TarjetaSeccion(
            titulo: '¿Qué es GastoFácil?',
            child: Text(
              'Aplicación para controlar tus gastos e ingresos personales: '
              'registra cada movimiento, define tu presupuesto del mes, '
              'repártelo entre categorías y recibe una alerta cuando te '
              'pases. Funciona sin internet y tus datos se guardan en tu '
              'dispositivo.',
              style: TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          TarjetaSeccion(
            titulo: 'Proyecto',
            child: Column(
              children: [
                dato(Icons.person_outline, 'Autora',
                    'Camila Evelyn Rodríguez Apaza'),
                dato(Icons.school_outlined, 'Institución',
                    'Instituto Técnico de Educación Comercial Americano "ITECA"'),
                dato(Icons.menu_book_outlined, 'Asignatura',
                    'Programación de Dispositivos Móviles II'),
                dato(Icons.badge_outlined, 'Docente',
                    'Ing. Alexander Pabón Pabón'),
                dato(Icons.calendar_month_outlined, 'Gestión', '2026'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TarjetaSeccion(
            titulo: 'Tecnologías',
            child: Column(
              children: [
                dato(Icons.flutter_dash, 'Framework y lenguaje',
                    'Flutter 3.41 + Dart 3.11'),
                dato(Icons.storage_outlined, 'Base de datos',
                    'SQLite local (sqflite)'),
                dato(Icons.devices_outlined, 'Plataformas',
                    'Android, Web y Windows'),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
