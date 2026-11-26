import SwiftUI

/// Detalle de un libro (Core).
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
#if ObjetivoAnual
    /// O4 · Objetivo anual; `nil` si su ajuste está apagado.
    var annualGoal: AnnualGoalForBook? = nil
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
#if ObjetivoAnual
            if let annualGoal {
                BookCompletionGoalView(data: annualGoal)
            }
#endif
        }
        .navigationTitle(book.title)
    }
}