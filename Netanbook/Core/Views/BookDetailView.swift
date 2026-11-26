import SwiftUI

/// Detalle de un libro (Core).
///
/// Recibe un enlace (`@Binding`) al libro del listado: lo que se edita aquí
/// cambia el libro del ViewModel, sin copias. La vista no conoce el ViewModel.
/// Con F2, F4 u O2 compiladas y su ajuste activado, añade su sección con lo que le
/// pasa el listado: closures para leer los datos y para cambiarlos, nunca sus
/// ViewModels. Cada sección lee sus datos en su propio `body` y se vuelve a
/// dibujar sola cuando cambian.
struct BookDetailView: View {
    @Binding var book: Book
#if Notas
    /// F2 · Notas y citas; `nil` si su ajuste está apagado.
    var notes: NotesForBook? = nil
#endif
#if Valoraciones
    /// F4 · Valoraciones y reseñas; `nil` si su ajuste está apagado.
    var review: ReviewForBook? = nil
#endif
#if Prestamos
    /// O2 · Préstamos; `nil` si su ajuste está apagado.
    var loans: LoansForBook? = nil
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
            if let notes {
                BookNotesView(data: notes)
            }
#endif
#if Valoraciones
            if let review {
                BookReviewView(data: review)
            }
#endif
#if Prestamos
            if let loans {
                BookLoansView(data: loans)
            }
#endif
        }
        .navigationTitle(book.title)
    }
}