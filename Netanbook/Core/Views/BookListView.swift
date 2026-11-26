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
#if SesionesLectura
    /// ViewModel de O1: independiente del listado, del libro y de F1.
    @State private var sessionsViewModel = ReadingSessionsViewModel()
#endif
#if Notas
    /// ViewModel de F2: independiente del listado y del libro.
    @State private var notesViewModel = BookNotesViewModel()
#endif
#if Categorias
    /// ViewModel de F3: independiente del listado y del libro.
    @State private var categoriesViewModel = BookCategoriesViewModel()
    /// Categoría por la que se filtra el listado; `nil` para ver todos los libros.
    @State private var categoryFilter: UUID?
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
#if Estadisticas
                if config.showStatistics {
                    // F5 se calcula con todos los libros del Core, sin filtros.
                    LibraryStatisticsView(statistics: LibraryStatistics(books: viewModel.books))
                }
#endif
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
#if Categorias
                if config.showCategories {
                    CategoryFilterView(
                        categories: categoriesViewModel.sortedCategories(),
                        selected: activeCategoryFilter,
                        select: { categoryFilter = $0 }
                    )
                }
#endif
                ForEach(ReadingStatus.allCases, id: \.self) { status in
                    Section(status.displayName) {
                        ForEach(visibleBooks(with: status)) { book in
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

    /// Libros de un estado que se muestran: todos, o con F3 activada y una
    /// categoría elegida, solo los que la tienen.
    private func visibleBooks(with status: ReadingStatus) -> [Book] {
        let books = viewModel.books(with: status)
#if Categorias
        if let categoryID = activeCategoryFilter {
            let ids = categoriesViewModel.bookIDs(in: categoryID)
            return books.filter { ids.contains($0.id) }
        }
#endif
        return books
    }

#if Categorias
    /// El filtro solo cuenta con el ajuste de F3 activado y si la categoría
    /// elegida sigue existiendo (se puede borrar desde el detalle).
    private var activeCategoryFilter: UUID? {
        guard config.showCategories, let categoryFilter,
              categoriesViewModel.category(id: categoryFilter) != nil else { return nil }
        return categoryFilter
    }
#endif

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

    /// Detalle del libro. Con F1, F2, F3, F4, O1, O2 u O4 compiladas y su ajuste activado,
    /// le pasa closures para leer y cambiar sus datos, igual que el enlace al libro:
    /// el detalle no conoce los ViewModels.
    private func detail(for book: Book) -> BookDetailView {
#if Progreso || Notas || Categorias || Valoraciones || Prestamos || ObjetivoAnual
        var detail = BookDetailView(book: binding(for: book))
#if Progreso
        if config.showProgress {
            detail.progress = ProgressForBook(
                progress: { progressViewModel.progress(for: book.id) },
                save: { progressViewModel.setProgress(bookID: book.id, currentPage: $0, totalPages: $1) }
            )
        }
#endif
#if SesionesLectura
        if config.showReadingSessions {
            // O1 requiere F1: la sesión empieza en la página actual de F1 y, al
            // terminarla, la página final pasa a ser la página actual de F1.
            detail.sessions = SessionsForBook(
                active: { sessionsViewModel.activeSession(for: book.id) },
                history: { sessionsViewModel.history(for: book.id) },
                currentPage: { progressViewModel.progress(for: book.id)?.currentPage ?? 0 },
                totalPages: { progressViewModel.progress(for: book.id)?.totalPages },
                start: {
                    let page = progressViewModel.progress(for: book.id)?.currentPage ?? 0
                    return sessionsViewModel.start(bookID: book.id, fromPage: page)
                },
                stop: { endPage in
                    if let total = progressViewModel.progress(for: book.id)?.totalPages, endPage > total {
                        return false
                    }
                    guard sessionsViewModel.stop(bookID: book.id, atPage: endPage) != nil else { return false }
                    progressViewModel.setCurrentPage(bookID: book.id, page: endPage)
                    return true
                },
                cancel: { sessionsViewModel.cancel(bookID: book.id) },
                remove: { sessionsViewModel.removeSession(id: $0) }
            )
        }
#endif
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
#if Categorias
        if config.showCategories {
            detail.categories = CategoriesForBook(
                all: { categoriesViewModel.sortedCategories() },
                isAssigned: { categoriesViewModel.isAssigned(bookID: book.id, categoryID: $0) },
                setAssigned: { categoriesViewModel.setAssigned($1, bookID: book.id, categoryID: $0) },
                nameExists: { categoriesViewModel.nameExists($0, excluding: $1) },
                create: { name in
                    guard let category = categoriesViewModel.addCategory(name: name) else { return false }
                    categoriesViewModel.setAssigned(true, bookID: book.id, categoryID: category.id)
                    return true
                },
                rename: { categoriesViewModel.renameCategory(id: $0, to: $1) },
                remove: { categoriesViewModel.removeCategory(id: $0) }
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
        let row = BookRowView(
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
        let row = BookRowView(
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
#if Categorias
        // Con F3 activada, la fila muestra también las categorías del libro.
        var categorized = row
        if config.showCategories {
            categorized.categoryNames = categoriesViewModel.categories(for: book.id).map(\.name)
        }
        return categorized
#else
        return row
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

    /// Borra el libro y, si F1, F2, F3, F4, O1, O2 u O4 están compiladas, también su
    /// progreso, sus notas, sus categorías, su valoración, sus sesiones de lectura,
    /// sus préstamos y su fecha de finalización: el Core no sabe que esos datos existen.
    /// (F5 no guarda nada: se vuelve a calcular sola.)
    private func removeBook(id: UUID) {
        viewModel.removeBook(id: id)
#if Progreso
        progressViewModel.removeProgress(bookID: id)
#endif
#if SesionesLectura
        sessionsViewModel.removeSessions(bookID: id)
#endif
#if Notas
        notesViewModel.removeNotes(bookID: id)
#endif
#if Categorias
        categoriesViewModel.removeAssignments(bookID: id)
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
