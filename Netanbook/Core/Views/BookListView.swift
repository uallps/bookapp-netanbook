import SwiftUI

/// Pantalla principal (Core): la biblioteca agrupada por estado.
///
/// La vista guarda los ViewModels en `@State`, dibuja el listado y delega las
/// acciones. Desde cada fila se navega al detalle del libro.
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
#if Categorias
    /// ViewModel de F3: independiente del listado y del libro.
    @State private var categoriesViewModel = BookCategoriesViewModel()
    /// Categoría por la que se filtra el listado; `nil` para ver todos los libros.
    @State private var categoryFilter: UUID?
#endif
#if Prestamos
    /// ViewModel de O2: independiente del listado y del libro.
    @State private var loansViewModel = BookLoansViewModel()
#endif

    /// Por defecto, el ViewModel guarda en JSON. Las vistas previas le pasan
    /// uno con `MockBookStorageProvider`.
    init(viewModel: BookListViewModel = BookListViewModel()) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
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

    /// Detalle del libro. Con F2, F3 u O2 compiladas y su ajuste activado, le
    /// pasa closures para leer y cambiar sus datos, igual que el enlace al libro:
    /// el detalle no conoce los ViewModels.
    private func detail(for book: Book) -> BookDetailView {
#if Notas || Categorias || Prestamos
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
            changeStatus: { viewModel.advanceStatus(id: book.id) },
            advanceProgress: { progressViewModel.advance(bookID: book.id) }
        )
#else
        let row = BookRowView(
            book: book,
            showProgress: config.showProgress,
            changeStatus: { viewModel.advanceStatus(id: book.id) }
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

    /// Un enlace (`Binding`) para que el detalle edite el libro. No toca los
    /// datos: leer y escribir se traducen a métodos del ViewModel.
    private func binding(for book: Book) -> Binding<Book> {
        Binding(
            get: { viewModel.book(id: book.id) ?? book },
            set: { viewModel.updateBook($0) }
        )
    }

    /// Borra el libro y, si F1, F2, F3 u O2 están compiladas, también su
    /// progreso, sus notas, sus categorías y sus préstamos: el Core no sabe que
    /// esos datos existen.
    private func removeBook(id: UUID) {
        viewModel.removeBook(id: id)
#if Progreso
        progressViewModel.removeProgress(bookID: id)
#endif
#if Notas
        notesViewModel.removeNotes(bookID: id)
#endif
#if Categorias
        categoriesViewModel.removeAssignments(bookID: id)
#endif
#if Prestamos
        loansViewModel.removeLoans(bookID: id)
#endif
    }
}

// Vista previa con almacenamiento en memoria: no lee ni escribe el JSON real.
#Preview {
    BookListView(viewModel: BookListViewModel(storageProvider: MockBookStorageProvider()))
        .environment(AppConfig())
}
