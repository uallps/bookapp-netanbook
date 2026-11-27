# Cómo pasar una feature a plugin

El sistema de plugins está en `Netanbook/Infrastructure/Plugins/`. **F5 Estadísticas** ya está migrada y sirve de ejemplo (`Features/Estadisticas/StatisticsPlugin.swift`). El diagrama de clases está en `docs/sesion-8/diagramas/sistema-plugins.puml`.

## Qué protocolo cumple tu plugin

| Si tu feature… | Cumple | Ejemplos |
|---|---|---|
| guarda datos ligados a un libro | `DataPlugin`: `willDeleteBook` borra sus datos del libro | F1, F2, F3, F4, O1, O2, O3, O4 |
| reacciona al cambio de estado o título | `DataPlugin.didUpdateBook` | O4 (fecha de finalización) |
| muestra algo | `ViewPlugin`: `isEnabled` + los huecos que use + `settingsView` | todas |
| oculta libros del listado | `BookFilterPlugin.includes` | F3 (filtro por categoría) |

Un plugin puede cumplir varios: `final class NotesPlugin: DataPlugin, ViewPlugin`.

## Los cuatro huecos de `ViewPlugin`

| Hueco | Dónde sale | Recibe |
|---|---|---|
| `libraryHeaderView(library:)` | Encima de los libros del listado | `LibraryContext`: todos los libros y `addBook(título, autor)` |
| `bookRowView(for:)` | En la fila, bajo el autor | el `Book` |
| `bookDetailView(for:)` | Al final del detalle | el `Book` |
| `settingsView()` | En Ajustes (**obligatorio**: es tu interruptor) | — |

Solo implementas los que usas. Los demás quedan vacíos y no aparecen en pantalla.

## Pasos

1. **Crea `Features/<TuFeature>/<Nombre>Plugin.swift`** dentro de `#if <TuTrait>`. Normalmente el plugin envuelve al ViewModel que ya tienes:

   ```swift
   #if Notas
   import SwiftUI

   final class NotesPlugin: DataPlugin, ViewPlugin {
       let name = "F2 · Notas y citas"
       private let config: AppConfig
       private let viewModel: BookNotesViewModel   // el que ya existe

       init(config: AppConfig, viewModel: BookNotesViewModel = BookNotesViewModel()) {
           self.config = config
           self.viewModel = viewModel
       }

       // DataPlugin: al borrar un libro, fuera sus notas.
       func willDeleteBook(_ book: Book) { viewModel.removeNotes(bookID: book.id) }

       // ViewPlugin
       var isEnabled: Bool { config.showNotes }

       func bookDetailView(for book: Book) -> some View {
           BookNotesView(data: NotesForBook(
               notes: { self.viewModel.notes(for: book.id) },
               add: { self.viewModel.addNote(bookID: book.id, kind: $0, text: $1, page: $2) },
               update: { self.viewModel.updateNote(id: $0, kind: $1, text: $2, page: $3) },
               remove: { self.viewModel.removeNote(id: $0) }
           ))
       }

       func settingsView() -> some View {
           Toggle("Mostrar notas y citas", isOn: Binding(
               get: { self.config.showNotes },
               set: { self.config.showNotes = $0 }
           ))
       }
   }
   #endif
   ```

2. **Regístralo** en `Application/NetanbookApp.swift`, en el `init()`:

   ```swift
   #if Notas
           PluginRegistry.shared.register(NotesPlugin(config: config))
   #endif
   ```

   Si dependes de otro plugin (O1 necesita F1), créalos los dos ahí y pásale uno al otro en el `init`.

3. **Borra tu feature del núcleo.** Quita tus bloques `#if <TuTrait>` de:
   - `Core/Views/BookListView.swift`: el `@State` de tu ViewModel, tu parte de `detail(for:)` o `rowContent(for:)`, y tu línea en `removeBook(id:)`;
   - `Core/Views/BookDetailView.swift` y `Core/Views/BookRowView.swift`: tu propiedad y tu vista;
   - `Features/Settings/Views/SettingsView.swift`: tu `Toggle`, y tu trait en la condición `#if !(…)` del final.

4. **Compruébalo:**
   - `swift build --product Netanbook` (base) y `swift build --product Netanbook --traits <TuTrait>`;
   - `swift test --traits <TuTrait>`;
   - busca el nombre de tu tipo fuera de tu carpeta. En `Core/` y `Features/Settings/` no debe salir. En `Application/` solo puede salir en el registro, en tu flag de `AppConfig` y en `Product.name`:
     ```sh
     grep -rn "NotesPlugin\|BookNotes" Netanbook/Core Netanbook/Features/Settings Netanbook/Application
     ```
   - en la app: tu interruptor sigue en Ajustes, con él apagado tus vistas desaparecen, y al borrar un libro se borran tus datos de tu JSON.

**Para no pisarnos:** migrad de uno en uno y haced `git pull` antes de empezar. Todos tocamos `BookListView.swift`, `BookDetailView.swift` y `SettingsView.swift`, aunque cada uno solo quita sus bloques.

## En Windows

Si `swift build` da `I/O error (code: 514)` en `.build`, compila con la carpeta de compilación en otro sitio, sin tildes:

```sh
swift build --scratch-path C:/nb-build --product Netanbook --traits Estadisticas
```
