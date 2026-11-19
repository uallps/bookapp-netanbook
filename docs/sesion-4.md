# Sesión 4 · Un proyecto, varios productos y el primer feature flag

**Grupo Netanbook** · Líneas de Productos Software · Universidad de Almería · curso 2026-27

> Estado del código de esta entrega: etiqueta Git `sesion-4` (`git checkout sesion-4`).
> Seguimos la estructura del ejemplo del profesor, TaskApp-2026 (etiqueta `sesion-4`).

---

## 1. Estructura del proyecto

```
bookapp-netanbook/
├── BookApp.xcodeproj          // Mac: targets «BookApp» y «BookApp Progreso»
├── Package.swift              // Linux y Windows: trait Progreso
├── Package.resolved           // versión resuelta de SwiftOpenUI (se sube al repo)
├── Compat/SwiftUI/            // módulo «SwiftUI» = SwiftOpenUI + backend (GTK 4 / Win32)
└── BookApp/
    ├── Application/
    │   ├── BookApp.swift      // @main
    │   └── AppConfig.swift    // flags F1–F5 (@Observable, todos desactivados)
    ├── Core/
    │   ├── Models/            // Book, ReadingStatus, SampleLibrary
    │   ├── ViewModels/        // BookListViewModel: añadir, cambiar estado, eliminar
    │   └── Views/             // BookListView, BookRowView
    └── Features/
        ├── Progress/          // F1 (todo dentro de #if Progreso)
        │   ├── ReadingProgress.swift
        │   ├── ReadingProgressViewModel.swift
        │   └── BookProgressView.swift
        └── Notes/ Categories/ Reviews/ Statistics/   // bocetos F2–F5 (sesión 3)
```

Un único repositorio y una única carpeta de código para todos los productos:

- **En Mac** se abre `BookApp.xcodeproj` y se usa el SwiftUI de Apple.
- **En Linux y Windows** `Package.swift` compila la misma carpeta `BookApp/`. El módulo
  `Compat/SwiftUI` se llama `SwiftUI` y reexporta SwiftOpenUI, así que `import SwiftUI`
  funciona sin cambiar el código y no hace falta escribir ninguna vista dos veces.

## 2. Cómo se lanza cada producto

| Producto | Xcode (Mac) | Linux y Windows |
|---|---|---|
| Base (sin F1) | scheme `BookApp` | `swift run BookApp` |
| Con F1 Progreso | scheme `BookApp Progreso` | `swift run --traits Progreso BookApp` |

Equivalente por terminal en Mac, sin abrir Xcode:

```bash
xcodebuild -project BookApp.xcodeproj -scheme "BookApp Progreso" -destination 'platform=macOS' build
```

La CI (`.github/workflows/ci.yml`) compila los dos schemes en macOS y las dos variantes
(`swift build` y `swift build --traits Progreso`) en Linux y Windows en cada `push`.

## 3. Operaciones del Core

`BookListViewModel` es el único que modifica la biblioteca:

| Operación | Método | En la interfaz |
|---|---|---|
| Añadir | `addBook(title:author:)` (rechaza títulos vacíos) | Campo de texto + «Añadir libro» |
| Cambiar estado | `advanceStatus(id:)` (Pendiente → Leyendo → Terminado → …) | Icono de la fila |
| Eliminar | `deleteBook(id:)` | Botón «Eliminar» de la fila |

La fila se ha extraído a `BookRowView`: recibe el libro y las acciones como closures y no
conoce el ViewModel (igual que `TaskRowView` en TaskApp).

## 4. Feature flags: F1 Progreso como flag y como variable de compilación

**Flag en ejecución.** `AppConfig` declara los cinco flags comunes, todos a `false`:

```swift
@Observable
final class AppConfig {
    var enableProgress = false     // F1 · Progreso
    var enableNotes = false        // F2 · Notas y citas
    var enableCategories = false   // F3 · Categorías
    var enableReviews = false      // F4 · Valoraciones y reseñas
    var enableStatistics = false   // F5 · Estadísticas
}
```

El listado guarda `AppConfig` en un `@State` y muestra el botón **«F1 Progreso: Sí/No»**.
Solo si el flag está activo y el libro tiene datos de progreso, dibuja `BookProgressView`
(página actual, total, porcentaje y botones −10 / +10) debajo de la fila.

**F1 como componente independiente.** Sus datos (`ReadingProgress`: `bookID`, `totalPages`,
`currentPage`) y su ViewModel (`ReadingProgressViewModel`) están en `Features/Progress`.
`Book` y `BookListViewModel` no se han tocado: no saben que F1 existe. Al borrar un libro,
el listado avisa también a F1 (`removeProgress(for:)`) para no dejar datos huérfanos.

**Variable de compilación.** Todo el código de F1 está dentro de `#if Progreso`:

- **Xcode:** el target «BookApp Progreso» comparte la carpeta `BookApp/` con el target base
  y añade `Progreso` en *Build Settings → Swift Compiler → Active Compilation Conditions*.
  Xcode crea un scheme con el mismo nombre. Tiene su propio *bundle id*
  (`es.ual.netanbook.BookApp.Progreso`), así que las dos apps conviven instaladas.
- **SwiftPM:** `Package.swift` declara el trait `Progreso`; cada trait activo es una
  variable de compilación, así que `swift run --traits Progreso BookApp` activa los `#if`.

Sin la variable, el código de F1 no existe en el programa: el listado muestra
*«F1 Progreso: no incluida en este producto»* y el Core funciona igual.

Dos niveles de variabilidad: la **compilación** decide si el código de F1 existe; el
**flag**, en un producto que sí lo incluye, decide si se muestra.

## 5. Capturas

| Producto | Captura |
|---|---|
| Base · F1 sin compilar | _pendiente_ (`capturas/base.png`) |
| BookApp Progreso · flag desactivado | _pendiente_ (`capturas/progreso-off.png`) |
| BookApp Progreso · flag activado, progreso visible | _pendiente_ (`capturas/progreso-on.png`) |

## 6. Qué se comparte, qué es distinto y cómo se separan el Core y F1

Los productos comparten **todo** el código de la carpeta `BookApp/`: el libro, el estado de
lectura, el ViewModel del listado, la configuración de flags, las vistas y F1. Lo único que
cambia entre Mac y Linux/Windows es qué hay detrás de `import SwiftUI` (el SwiftUI de Apple o
SwiftOpenUI a través de `Compat/`), y entre el producto Base y el producto con F1 solo cambia
una variable de compilación (`Progreso`), que en Xcode pone el target «BookApp Progreso» y en
SwiftPM el trait del mismo nombre. El Core y F1 se separan en tres niveles: F1 tiene sus
propios datos y su propio ViewModel enlazados al libro por `bookID` (el libro no cambia); su
visibilidad depende del flag `enableProgress` de `AppConfig` en ejecución; y su existencia
depende de `#if Progreso` en compilación. Con F1 desactivada o sin compilar, la biblioteca se
sigue pudiendo consultar, añadir, cambiar de estado y borrar.

## 7. Comprobad vuestro diseño (respuestas)

**¿Qué ficheros importan el framework de interfaz y cuáles no? ¿Por qué el modelo no debe hacerlo?**
Solo las vistas (`BookApp.swift`, `BookListView`, `BookRowView`, `BookProgressView`) importan
`SwiftUI`. Los modelos (`Book`, `ReadingStatus`, `ReadingProgress`, bocetos F2–F5) solo usan
Foundation, y los ViewModels y `AppConfig` Foundation y Observation. Si el modelo importara la
interfaz quedaría atado a un framework concreto, no se podría probar sin pantalla y cualquier
cambio de interfaz obligaría a tocar los datos.

**¿Cómo se consigue que el mismo código funcione en Mac, Linux y Windows?**
En Mac, Xcode usa el SwiftUI de Apple. En Linux y Windows, `Package.swift` define un módulo
llamado `SwiftUI` (`Compat/SwiftUI`) que reexporta SwiftOpenUI con el backend del sistema
(GTK 4 o Win32). SwiftOpenUI solo se descarga al compilar con SwiftPM; Xcode no lo usa.

**¿En qué se parece un trait (o una variable de compilación) a un feature flag y en qué se diferencia?**
Los dos activan o desactivan una característica. El flag se decide **en ejecución**: el código
está en el programa y se cambia sin recompilar. La variable de compilación se decide **antes de
compilar**: si no está activa, el código no existe en el programa y para cambiarlo hay que
recompilar (otro scheme en Xcode u otro `--traits` en SwiftPM).

**Con F1 desactivada, ¿siguen funcionando la biblioteca y los datos del libro? ¿Y con F1 sin compilar?**
Sí en los dos casos. Con el flag a `false`, los datos de progreso siguen guardados en
`ReadingProgressViewModel` y solo dejan de mostrarse. Sin `Progreso`, `ReadingProgress` ni
siquiera existe, pero `Book` y `BookListViewModel` no dependen de él y la biblioteca funciona igual.

**¿Dónde viven los datos de progreso y por qué no en el libro?**
En `ReadingProgressViewModel` (`Features/Progress`), indexados por el id del libro. No están en
`Book` porque `Book` es el Core común a todas las variantes: meterlos ahí acoplaría el Core a F1,
obligaría a la variante Base a llevar datos que no usa y, sin `Progreso`, `Book` no compilaría
porque el tipo `ReadingProgress` no existiría.
