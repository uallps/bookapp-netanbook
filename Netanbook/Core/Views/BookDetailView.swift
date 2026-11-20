import SwiftUI

/// Detalle de un libro (Core).
///
/// Recibe un enlace (`@Binding`) al libro del listado: lo que se edita aquí
/// cambia el libro del ViewModel, sin copias. La vista no conoce el ViewModel.
struct BookDetailView: View {
    @Binding var book: Book
#if Notas
    /// ViewModel de F2: independiente del libro.
    var notesViewModel: BookNotesViewModel
    var showNotes: Bool
#endif

    var body: some View {
        Form {
            TextField("Título del libro", text: $book.title)
            Picker("Estado de lectura", selection: $book.status) {
                ForEach(ReadingStatus.allCases, id: \.self) { status in
                    Text(status.displayName).tag(status)
                }
            }
            Text("Autor: \(book.author ?? "Autor desconocido")")
                .bookCaption()
#if Notas
            if showNotes {
                BookNotesView(
                    notes: notesViewModel.notes(for: book.id),
                    add: { kind, text, page in
                        notesViewModel.addNote(bookID: book.id, kind: kind, text: text, page: page)
                    },
                    remove: { notesViewModel.removeNote(id: $0) }
                )
            }
#endif
        }
        .navigationTitle(book.title)
    }
}
