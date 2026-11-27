# Netanbook · BookApp

Proyecto de grupo de **Líneas de Productos Software** (Universidad de Almería, curso 2026-27).

Netanbook es una biblioteca personal de libros con seguimiento de lectura, construida como una **línea de productos software**: un Core común y características opcionales que se incluyen o no en cada producto.

## Equipo y reparto

| Integrante | Feature común | Original 1 | Original 2 |
|---|---|---|---|
| Maria Camila Soto Zapata | F1 · Progreso y F5 · Estadísticas | O1 · Sesiones de lectura | O5 · Recordatorio de lectura *(en desarrollo)* |
| Marcos Sánchez García | F2 · Notas y citas | O2 · Préstamos | O6 · Lista de deseos *(en desarrollo)* |
| Javier Zúñiga Carmona | F3 · Categorías | O3 · Alta por ISBN | O7 · Exportar e importar CSV *(en desarrollo)* |
| Daniel Arévalo Almendros | F4 · Valoraciones y reseñas | O4 · Objetivo anual | O8 · Formato del libro *(en desarrollo)* |

El modelo de características y sus restricciones están en [docs/sesion-3.md](docs/sesion-3.md) y en [docs/modelo-caracteristicas.puml](docs/modelo-caracteristicas.puml) ([PNG](docs/modelo-caracteristicas.png)).

## Características

- **Core (obligatorio):** libros con identificador, título no vacío, autor opcional y estado de lectura (Pendiente, Leyendo, Terminado). Se pueden añadir, consultar, editar, cambiar de estado y eliminar. Se guardan en local (JSON).
- **Comunes (opcionales):** F1 Progreso, F2 Notas y citas, F3 Categorías, F4 Valoraciones y reseñas, F5 Estadísticas.
- **Originales (opcionales):** O1 Sesiones de lectura (**requiere F1**), O2 Préstamos, O3 Alta por ISBN, O4 Objetivo anual.

Cada característica se activa en dos momentos:

1. **Al compilar:** con un *trait* de `Package.swift` (Linux y Windows) o un target de Xcode (macOS). Sin su trait, su código no está en el ejecutable (`#if <Trait>`).
2. **Al ejecutar:** con su interruptor en **Ajustes**, que se guarda en `UserDefaults` y se conserva al reiniciar.

| Característica | Trait | Target de Xcode |
|---|---|---|
| F1 Progreso | `Progreso` | Netanbook Progreso |
| F2 Notas y citas | `Notas` | Netanbook Notas |
| F3 Categorías | `Categorias` | Netanbook Categorias |
| F4 Valoraciones y reseñas | `Valoraciones` | — |
| F5 Estadísticas | `Estadisticas` | — |
| O1 Sesiones de lectura | `SesionesLectura` (activa también `Progreso`) | — |
| O2 Préstamos | `Prestamos` | Netanbook Prestamos |
| O3 Alta por ISBN | `AltaISBN` (usa la red) | Netanbook AltaISBN |
| O4 Objetivo anual | `ObjetivoAnual` | — |

## Ejecutar

El mismo código de la carpeta `Netanbook/` funciona en los tres sistemas:

| Sistema | Cómo se ejecuta | Interfaz |
|---|---|---|
| macOS | Abrir `Netanbook.xcodeproj` en Xcode, elegir el scheme y pulsar ▶ | SwiftUI de Apple |
| Linux | `swift run Netanbook` (necesita `libgtk-4-dev` y `libfontconfig-dev`) | [SwiftOpenUI](https://github.com/uallps/SwiftOpenUI) con GTK 4 |
| Windows | `swift run Netanbook` (Swift 6.3.3) | SwiftOpenUI con Win32 |

Ejemplos de productos:

```sh
swift run Netanbook                                   # Base: solo el Core
swift run Netanbook --traits Progreso                 # Core + F1
swift run Netanbook --traits Progreso,Notas,Categorias,Valoraciones,Estadisticas    # Común: Core + F1–F5
swift run Netanbook --traits Progreso,Notas,Categorias,Valoraciones,Estadisticas,SesionesLectura,Prestamos,AltaISBN,ObjetivoAnual   # Completo
```

> **Windows:** si la ruta del proyecto tiene tildes o espacios y `swift build` falla con `I/O error (code: 514)`, compila con la carpeta de compilación en otra ruta:
> `swift build --scratch-path C:/nb-build --product Netanbook --traits Estadisticas`

## Pruebas

Las pruebas de los ViewModels usan almacenamiento en memoria (`MockBookStorageProvider` y los Mock de cada característica):

                    # Core
swift test --traits Progreso,Notas,Categorias,Valoraciones,Estadisticas,SesionesLectura,Prestamos,AltaISBN,ObjetivoAnual   # todo
```

## Estructura

```
bookapp-netanbook/
├── Netanbook.xcodeproj           // macOS: targets por producto (SwiftUI de Apple)
├── Package.swift                 // Linux y Windows: un trait por característica
├── Compat/SwiftUI/               // módulo «SwiftUI» que reexporta SwiftOpenUI
├── Netanbook/                    // el MISMO código para los tres sistemas
│   ├── Application/              // @main, AppConfig (flags), Theme
│   ├── Core/                     // Book, ReadingStatus, BookListViewModel y vistas
│   ├── Features/                 // una carpeta por característica + Ajustes
│   └── Infrastructure/
│       ├── Persistence/          // BookStorageProvider: JSON y Mock
│       └── Plugins/              // PluginRegistry
├── Tests/NetanbookTests/         // pruebas de los ViewModels
├── scripts/                      // pruebas de interfaz en Windows (CI)
└── docs/                         // documentación de cada sesión
```

Cada característica guarda sus datos en su propio fichero JSON, fuera de `Book`, enlazados por el id del libro. Al borrar un libro se borran también sus datos.

## Integración continua

`.github/workflows/ci.yml` se ejecuta en cada push:

- **macOS:** compila los schemes del proyecto de Xcode.
- **Linux:** compila el producto base y cada característica, comprueba que el código de F1 solo está en el producto que la lleva, arranca la app y pasa las pruebas con cada combinación de traits y con todos a la vez.
- **Windows:** compila los productos y prueba la interfaz (editar, Ajustes, reiniciar y comprobar que todo se conserva).

## Documentación

| Sesión | Contenido |
|---|---|
| 3 | [Modelo de características, MVVM y reparto](docs/sesion-3.md) · [versión de Marcos](docs/sesion-3/Sesion3_Netanbook_MVVM.md) |
| 4 | [Productos y feature flags](docs/sesion-4.md) · [versión de Marcos](docs/sesion-4/Sesion4_Netanbook_Productos.md) |
| 5 | [Navegación y detalle del libro](docs/sesion-5/Sesion5_Netanbook_Navegacion.md) |
| 6 | [Persistencia, Ajustes y tema](docs/sesion-6/Sesion6_Netanbook_Persistencia.md) |
| — | [Notas de parche](docs/notas-de-parche/Notas_de_parche.md) |
