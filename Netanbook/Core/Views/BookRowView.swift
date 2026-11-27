import SwiftUI

/// Fila de un libro.
///
/// No conoce ningún ViewModel: recibe el libro, los flags y las acciones como
/// closures. Quien la crea decide qué hace cada acción. Debajo, lo que añadan
/// los plugins para este libro.
struct BookRowView: View {
    let book: Book
    /// Flag de F1 en ejecución (`AppConfig.showProgress`).
    let showProgress: Bool
#if Progreso
    /// Datos de F1 para este libro. Solo existen en el producto con Progreso.
    let progress: ReadingProgress?
#endif
    /// Acción del botón de estado.
    let changeStatus: () -> Void
#if Progreso
    /// Acción del botón de F1 para avanzar páginas.
    let advanceProgress: () -> Void
#endif
#if Categorias
    /// Nombres de las categorías del libro (F3); vacío si su ajuste está apagado.
    var categoryNames: [String] = []
#endif

    var body: some View {
        HStack {
            Button(action: changeStatus) {
                Image(systemName: book.status.symbolName)
                    .foregroundColor(book.status.color)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading) {
                Text(book.title)
                Text(book.author ?? "Autor desconocido")
                    .bookCaption()
                ForEach(PluginRegistry.shared.bookRowViews(for: book)) { pluginView in
                    pluginView.view
                }
#if Categorias
                if !categoryNames.isEmpty {
                    Text(categoryNames.joined(separator: " · "))
                        .bookCaption(color: .bookAccent)
                }
#endif
#if Progreso
                if showProgress {
                    ReadingProgressView(progress: progress, advance: advanceProgress)
                }
#endif
            }
        }
    }
}
