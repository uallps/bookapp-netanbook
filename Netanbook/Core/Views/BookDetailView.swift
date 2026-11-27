import SwiftUI

/// Detalle de un libro (Core).
///
/// Recibe un enlace (`@Binding`) al libro del listado: lo que se edita aquí
/// cambia el libro del ViewModel, sin copias. La vista no conoce el ViewModel.
/// Con F1, F2, F3, F4, O1, O2, O3 u O4 compiladas y su ajuste activado, añade su sección con
/// lo que le pasa el listado: closures para leer los datos y para cambiarlos,
/// nunca sus ViewModels. Cada sección lee sus datos en su propio `body` y se
/// vuelve a dibujar sola cuando cambian.
///
/// Debajo de todo, lo que añadan los plugins para este libro: el detalle no
/// sabe cuáles son.
struct BookDetailView: View {
    @Binding var book: Book
#if Progreso
    /// F1 · Progreso; `nil` si su ajuste está apagado.
    var progress: ProgressForBook? = nil
#endif
#if SesionesLectura
    /// O1 · Sesiones de lectura; `nil` si su ajuste está apagado.
    var sessions: SessionsForBook? = nil
#endif
#if Notas
    /// F2 · Notas y citas; `nil` si su ajuste está apagado.
    var notes: NotesForBook? = nil
#endif
#if Categorias
    /// F3 · Categorías; `nil` si su ajuste está apagado.
    var categories: CategoriesForBook? = nil
#endif
#if Valoraciones
    /// F4 · Valoraciones y reseñas; `nil` si su ajuste está apagado.
    var review: ReviewForBook? = nil
#endif
#if Prestamos
    /// O2 · Préstamos; `nil` si su ajuste está apagado.
    var loans: LoansForBook? = nil
#endif
#if ObjetivoAnual
    /// O4 · Objetivo anual; `nil` si su ajuste está apagado.
    var annualGoal: AnnualGoalForBook? = nil
#endif
#if AltaISBN
    /// O3 · ISBN con el que se dio de alta el libro; `nil` si no tiene o si su
    /// ajuste está apagado. Es un dato fijo: no hace falta una closure.
    var isbn: String? = nil
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
#if AltaISBN
            if let isbn {
                Text("ISBN: \(isbn)")
                    .bookCaption()
            }
#endif
#if Progreso
            if let progress {
                ReadingProgressEditView(data: progress)
            }
#endif
#if SesionesLectura
            if let sessions {
                ReadingSessionsView(data: sessions)
            }
#endif
#if Categorias
            if let categories {
                BookCategoriesView(data: categories)
            }
#endif
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
#if ObjetivoAnual
            if let annualGoal {
                BookCompletionGoalView(data: annualGoal)
            }
#endif
            ForEach(PluginRegistry.shared.bookDetailViews(for: book)) { pluginView in
                pluginView.view
            }
        }
        .navigationTitle(book.title)
    }
}
