import SwiftUI

/// Pantalla principal (Core): la biblioteca agrupada por estado.
struct BookListView: View {
    @State private var viewModel: BookListViewModel
    /// La configuración la crea la app y llega por el entorno: es la misma que edita Ajustes.
    @Environment(AppConfig.self) private var config
#if Progreso
    /// ViewModel de F1: independiente del listado y del libro.
    @State private var progressViewModel = ReadingProgressViewModel()
#endif
#if Notas
    /// ViewModel de F2: independiente del listado y del libro.
    @State private var notesViewModel = BookNotesViewModel()
#endif
#if Valoraciones
    /// ViewModel de F4: independiente del listado y del libro.
    @State private var reviewsViewModel = BookReviewsViewModel()
#endif
#if Prestamos
    /// ViewModel de O2: independiente del listado y del libro.
    @State private var loansViewModel = BookLoansViewModel()
#endif
#if ObjetivoAnual
    /// ViewModel de O4: independiente del listado y del libro.
    @State private var annualGoalViewModel = AnnualGoalViewModel()
#endif

    init(viewModel: BookListViewModel = BookListViewModel()) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
#if ObjetivoAnual
                if config.showAnnualGoal {
                    let validIDs = Set(viewModel.books.map(\.id))
                    AnnualGoalSummaryView(
                        targetBooks: annualGoalViewModel.targetBooks,
                        completedBooks: annualGoalViewModel.completedCount(validBookIDs: validIDs),
                        onChangeTarget: { annualGoalViewModel.setTargetBooks($0) }
                    )
                }
#endif
                ForEach(ReadingStatus.allCases, id: \.self) { status in
                    Section(status.displayName) {
                        ForEach(viewModel.books(with: status)) { book in
                            bookRow(book: book)
                        }
                    }
                }
            }
            .toolbar {
                Button("Añadir libro") {
                    viewModel.addSampleBook()
                }
            }
            .navigationTitle("Libros")
        }
    }

    /// Una fila: enlace al detalle del libro, con menú contextual para borrarlo.
    private func bookRow(book: Book) -> some View {
        NavigationLink(destination: detail(for: book)) {
            rowContent(for: book)
                .contextMenu {
                    Button("Eliminar libro") {
                        removeBook(id: book.id)
                    }
                }
        }
    }

    /// Detalle del libro. Con F2, F4, O2 u O4 compiladas y su ajuste activado, le pasa
    /// closures para leer y cambiar sus datos.
    private func detail(for book: Book) -> BookDetailView {
#if Notas || Valoraciones || Prestamos || ObjetivoAnual
        var detail = BookDetailView(book: binding(for: book))
#if Notas
        if config.showNotes {
            detail.notes = NotesForBook(
                notes: { notesViewModel.notes(for: book.id) },
                add: { notesViewModel.addNote(bookID: book.id, kind: $0, text: $1, page: $2) },
                update: { notesViewModel.updateNote(id: $0, kind: $1, text: $2, page: $3) },
                remove: { notesViewModel.removeNote(id: $0) }
            )
        }
#endif
#if Valoraciones
        if config.showReviews {
            detail.review = ReviewForBook(
                review: { reviewsViewModel.review(for: book.id) },
                save: { reviewsViewModel.saveReview(bookID: book.id, rating: $0, text: $1) },
                remove: { reviewsViewModel.removeReview(bookID: book.id) }
            )
        }
#endif
#if Prestamos
        if config.showLoans {
            detail.loans = LoansForBook(
                openLoan: { loansViewModel.openLoan(for: book.id) },
                history: { loansViewModel.history(for: book.id) },
                lend: { loansViewModel.lend(bookID: book.id, to: $0, days: $1) },
                markReturned: { loansViewModel.markReturned(id: $0) }
            )
        }
#endif
#if ObjetivoAnual
        if config.showAnnualGoal {
            detail.annualGoal = AnnualGoalForBook(
                completionDate: { annualGoalViewModel.completionDate(for: book.id) },
                markCompletedToday: {
                    annualGoalViewModel.markCompleted(bookID: book.id, on: Date())
                    viewModel.changeStatus(id: book.id, to: .finished)
                },
                clearCompletion: {
                    annualGoalViewModel.clearCompletion(bookID: book.id)
                }
            )
        }
#endif
        return detail
#else
        return BookDetailView(book: binding(for: book))
#endif
    }

    /// Contenido de la fila: el libro, los flags y las acciones como closures.
    private func rowContent(for book: Book) -> BookRowView {
#if Progreso
        return BookRowView(
            book: book,
            showProgress: config.showProgress,
            progress: progressViewModel.progress(for: book.id),
            changeStatus: {
                viewModel.advanceStatus(id: book.id)
#if ObjetivoAnual
                if let updated = viewModel.book(id: book.id) {
                    annualGoalViewModel.syncBookStatus(bookID: book.id, status: updated.status)
                }
#endif
            },
            advanceProgress: { progressViewModel.advance(bookID: book.id) }
        )
#else
        return BookRowView(
            book: book,
            showProgress: config.showProgress,
            changeStatus: {
                viewModel.advanceStatus(id: book.id)
#if ObjetivoAnual
                if let updated = viewModel.book(id: book.id) {
                    annualGoalViewModel.syncBookStatus(bookID: book.id, status: updated.status)
                }
#endif
            }
        )
#endif
    }

    /// Un enlace (`Binding`) para que el detalle edite el libro.
    private func binding(for book: Book) -> Binding<Book> {
        Binding(
            get: { viewModel.book(id: book.id) ?? book },
            set: { updatedBook in
                viewModel.updateBook(updatedBook)
#if ObjetivoAnual
                annualGoalViewModel.syncBookStatus(bookID: updatedBook.id, status: updatedBook.status)
#endif
            }
        )
    }

    /// Borra el libro y limpia también sus datos asociados en todas las features activas.
    private func removeBook(id: UUID) {
        viewModel.removeBook(id: id)
#if Progreso
        progressViewModel.removeProgress(bookID: id)
#endif
#if Notas
        notesViewModel.removeNotes(bookID: id)
#endif
#if Valoraciones
        reviewsViewModel.removeReview(bookID: id)
#endif
#if Prestamos
        loansViewModel.removeLoans(bookID: id)
#endif
#if ObjetivoAnual
        annualGoalViewModel.clearCompletion(bookID: id)
#endif
    }
}

#Preview {
    BookListView(viewModel: BookListViewModel(storageProvider: MockBookStorageProvider()))
        .environment(AppConfig())
}