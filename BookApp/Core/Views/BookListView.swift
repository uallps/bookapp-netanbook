import Foundation
import SwiftUI

/// Listado de la biblioteca. Crea el ViewModel y la configuración con @State y
/// solo les llama: la colección y su lógica están en `BookListViewModel`.
struct BookListView: View {
    @State private var viewModel = BookListViewModel()
    @State private var config = AppConfig()
    @State private var newTitle = ""
#if Progreso
    @State private var progress = ReadingProgressViewModel()
#endif

    var body: some View {
        VStack {
            // Puntos de activación de las features (flags en ejecución).
            HStack {
#if Progreso
                Button("F1 Progreso: \(config.enableProgress ? "Sí" : "No")") {
                    config.enableProgress.toggle()
                }
#else
                Text("F1 Progreso: no incluida en este producto")
                    .font(.caption)
#endif
            }
            .padding(.top)

            List(viewModel.books) { book in
                VStack(alignment: .leading) {
                    BookRowView(
                        book: book,
                        advanceStatus: { viewModel.advanceStatus(id: book.id) },
                        delete: { deleteBook(id: book.id) }
                    )
#if Progreso
                    if config.enableProgress, let bookProgress = progress.progress(for: book.id) {
                        BookProgressView(progress: bookProgress) { delta in
                            progress.changePage(by: delta, for: book.id)
                        }
                    }
#endif
                }
            }

            HStack {
                TextField("Título del nuevo libro", text: $newTitle)
                Button("Añadir libro") {
                    if viewModel.addBook(title: newTitle) {
                        newTitle = ""
                    }
                }
            }
            .padding()
        }
    }

    /// El Core borra el libro; si F1 está compilada, también su progreso.
    private func deleteBook(id: UUID) {
        viewModel.deleteBook(id: id)
#if Progreso
        progress.removeProgress(for: id)
#endif
    }
}
