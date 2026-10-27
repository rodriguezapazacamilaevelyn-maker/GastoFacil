# GastoFácil

Aplicación en Flutter para controlar gastos e ingresos personales. Permite registrar movimientos, definir un presupuesto mensual, repartirlo entre categorías y recibir alertas al acercarse o pasarse del límite. Funciona sin internet y guarda los datos en el dispositivo con SQLite.

Proyecto de la materia **Programación de Dispositivos Móviles II**.

## Funcionalidades

- Registro, edición y eliminación de ingresos y gastos.
- Categorías predefinidas y personalizadas (con color e ícono).
- Pantalla de inicio con balance del mes, gráfico por categoría y últimos movimientos.
- Historial con filtros por tipo, categoría y rango de fechas.
- Presupuesto mensual que se puede cambiar en cualquier momento.
- Límites por categoría repartidos del presupuesto total.
- Alertas cuando el gasto llega al 80 % o supera el límite.
- Reportes por mes: balance, distribución de gastos y presupuesto vs. gasto real.
- Copia de respaldo en JSON (crear y restaurar) en Android y Windows.
- Funciona en Android, Windows y Web.

## Tecnologías

- Flutter 3.41 y Dart 3.11
- SQLite: `sqflite` (móvil), `sqflite_common_ffi` (escritorio) y `sqflite_common_ffi_web` (web)
- `fl_chart` para los gráficos
- `intl` para formato de fechas y montos en español
- `path_provider` para la carpeta de respaldos

## Requisitos

- Flutter SDK 3.41 o superior
- Android Studio o un dispositivo Android (para la versión móvil)
- Visual Studio con "Desarrollo para el escritorio con C++" (para Windows)
- Google Chrome (para la versión web)

## Cómo ejecutar

```bash
flutter pub get          # descarga las dependencias
flutter run              # ejecuta la app en el dispositivo o emulador
flutter test             # corre las pruebas
flutter build apk --release   # genera el APK
```

Versión web:

```bash
dart run sqflite_common_ffi_web:setup   # copia los archivos de SQLite para web (solo la primera vez)
flutter run -d chrome
```

## Estructura del proyecto

```
lib/
  models/    modelos de datos (Transaccion, Categoria, Presupuesto...)
  db/        acceso a SQLite y configuración por plataforma
  services/  cálculos financieros y copia de respaldo
  screens/   pantallas de la app
  widgets/   componentes reutilizables (tarjetas, gráfico, filas)
  utils/     tema visual y formato de montos y fechas
  main.dart  punto de entrada
test/        pruebas unitarias y de interfaz
```

## Autora

Camila Evelyn Rodríguez Apaza
