# BookApp · Netanbook

Proyecto de grupo de **Líneas de Productos Software** (Universidad de Almería, curso 2026-27).
Netanbook es una biblioteca personal de libros con seguimiento de lectura, construida como una
línea de productos: un Core común y características que se incluyen o no en cada variante.

Cada sesión tiene una etiqueta con el estado del código al terminarla:

| Etiqueta | Contenido | Documentación |
|---|---|---|
| `sesion-3` | Modelo de características y listado de libros con MVVM (`@Observable`) | [docs/sesion-3.md](docs/sesion-3.md) |
| `sesion-4` | `AppConfig` con F1–F5, fila `BookRowView`, añadir y eliminar, F1 Progreso como flag y como variable de compilación | [docs/sesion-4.md](docs/sesion-4.md) |

```sh
git checkout sesion-4
```

Modelo de características: [docs/modelo-caracteristicas.puml](docs/modelo-caracteristicas.puml) · [PNG](docs/modelo-caracteristicas.png)

## Ejecutar

El mismo código de la carpeta `BookApp/` funciona en los tres sistemas:

| Sistema | Cómo se ejecuta | Interfaz |
|---|---|---|
| macOS | Abrir `BookApp.xcodeproj` en Xcode y pulsar ▶ | SwiftUI de Apple |
| Linux | `swift run BookApp` (necesita `libgtk-4-dev` y `libfontconfig-dev`) | [SwiftOpenUI](https://github.com/uallps/SwiftOpenUI) con GTK 4 |
| Windows | `swift run BookApp` | SwiftOpenUI con Win32 |

En Linux y Windows, `Package.swift` añade un módulo llamado `SwiftUI` (carpeta `Compat/`)
que reexporta SwiftOpenUI, así que `import SwiftUI` funciona sin cambiar el código.

## Estructura

```
BookApp/
├── Application/      @main y AppConfig (feature flags)
├── Core/             obligatorio en todas las variantes
│   ├── Models/       Book, ReadingStatus, SampleLibrary
│   ├── ViewModels/   BookListViewModel
│   └── Views/        BookListView, BookRowView
├── Features/         un punto de variación por carpeta (F1 Progreso, con #if Progreso)
└── Infrastructure/   persistencia y plugins (se crea en próximas sesiones)
```

## Productos (desde la sesión 4)

| Producto | Xcode (Mac) | Linux y Windows |
|---|---|---|
| Base | scheme `BookApp` | `swift run BookApp` |
| Con F1 Progreso | scheme `BookApp Progreso` (target con `Progreso` en *Active Compilation Conditions*) | `swift run --traits Progreso BookApp` |
