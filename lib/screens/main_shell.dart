// ============================================================
// Proyecto    : GastoFácil
// Archivo     : lib/screens/main_shell.dart
// Autora      : Camila Evelyn Rodríguez Apaza
// Descripción : La barra de abajo para moverse entre las 4 pestañas.
// ============================================================

import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'historial_screen.dart';
import 'presupuesto_screen.dart';
import 'reportes_screen.dart';

/// Pantalla base con la barra inferior: Inicio, Historial, Presupuesto y Reportes.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _indice = 0; // la pestaña que está abierta

  // con setState cambio el índice y se redibuja la pestaña elegida
  void _irA(int indice) => setState(() => _indice = indice);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // uso IndexedStack para que las pantallas sigan vivas al cambiar de pestaña
      // y no se pierdan los filtros que el usuario ya puso
      body: IndexedStack(
        index: _indice,
        children: [
          // al inicio le paso _irA para que sus botones puedan cambiar de pestaña
          DashboardScreen(onCambiarPestana: _irA),
          const HistorialScreen(),
          const PresupuestoScreen(),
          const ReportesScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: _irA,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Historial'),
          NavigationDestination(
              icon: Icon(Icons.savings_outlined),
              selectedIcon: Icon(Icons.savings),
              label: 'Presupuesto'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Reportes'),
        ],
      ),
    );
  }
}
