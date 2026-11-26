#if AltaISBN
import Foundation
import Observation

/// ViewModel de O3 · Alta por ISBN.
///
/// Guarda el formulario de alta (ISBN, título y autor), busca el ISBN en el
/// catálogo y recuerda el ISBN de cada libro dado de alta. No conoce el
/// ViewModel del listado: para añadir el libro recibe una closure, así que el
/// Core no sabe que O3 existe.
@Observable
final class ISBNAddViewModel {
    /// En qué punto está el alta; decide el mensaje que ve el usuario.
    enum Status: Equatable {
        case idle
        case searching
        case found
        case notFound
        case failed
        case invalidISBN
        case duplicate
        case missingTitle
        case added(title: String)
    }

    // Formulario. La vista los edita directamente.
    var isbnText = ""
    var title = ""
    var author = ""

    private(set) var status: Status = .idle

    /// ISBN de los libros dados de alta con O3. Solo este ViewModel los modifica.
    private(set) var records: [BookISBN] = []

    @ObservationIgnored private let catalog: BookCatalog
    @ObservationIgnored private let storage: BookISBNStorage

    init(catalog: BookCatalog = OpenLibraryCatalog(),
         storage: BookISBNStorage = JSONBookISBNStorage()) {
        self.catalog = catalog
        self.storage = storage
        records = (try? storage.loadRecords()) ?? []
    }

    private func save() {
        do {
            try storage.saveRecords(records)
        } catch {
            print("No se han guardado los ISBN: \(error)")
        }
    }

    /// Texto que explica el estado actual.
    var message: String {
        switch status {
        case .idle: return "Escribe el ISBN (10 o 13 cifras) y pulsa Buscar"
        case .searching: return "Buscando en Open Library…"
        case .found: return "Encontrado: revisa los datos y pulsa Añadir"
        case .notFound: return "No está en el catálogo: escribe el título y el autor a mano"
        case .failed: return "No se ha podido consultar el catálogo; puedes escribir los datos a mano"
        case .invalidISBN: return "El ISBN no es válido: revisa las cifras"
        case .duplicate: return "Ya tienes un libro con ese ISBN"
        case .missingTitle: return "Escribe el título del libro"
        case .added(let title): return "«\(title)» se ha añadido a Pendientes"
        }
    }

    var isSearching: Bool { status == .searching }

    // MARK: - Consultas

    /// ISBN de un libro, si se dio de alta con O3.
    func isbn(for bookID: UUID) -> String? {
        records.first { $0.bookID == bookID }?.isbn
    }

    // MARK: - Acciones

    /// Busca en el catálogo el ISBN escrito y, si lo encuentra, rellena el
    /// título y el autor. Un ISBN no válido no llega a consultarse.
    func search() async {
        guard !isSearching else { return }
        guard let isbn = ISBN.normalized(isbnText) else {
            status = .invalidISBN
            return
        }
        status = .searching
        do {
            let info = try await catalog.lookup(isbn: isbn)
            // Si mientras se buscaba se ha cambiado el ISBN, esta respuesta ya no vale.
            guard ISBN.normalized(isbnText) == isbn else {
                status = .idle
                return
            }
            if let info {
                title = info.title
                author = info.author ?? ""
                status = .found
            } else {
                status = .notFound
            }
        } catch {
            print("No se ha podido consultar el catálogo: \(error)")
            status = .failed
        }
    }

    /// Da de alta el libro con el título y el autor del formulario y guarda su
    /// ISBN. `existingBookIDs` son los libros que siguen en el listado: un ISBN
    /// solo cuenta como repetido si su libro todavía existe. `add` es la
    /// closure del listado que añade el libro y devuelve su `id` (o `nil`).
    /// Devuelve `true` si se ha añadido.
    @discardableResult
    func addBook(existingBookIDs: Set<UUID>, add: (String, String?) -> UUID?) -> Bool {
        guard !isSearching else { return false }
        guard let isbn = ISBN.normalized(isbnText) else {
            status = .invalidISBN
            return false
        }
        guard !records.contains(where: { $0.isbn == isbn && existingBookIDs.contains($0.bookID) }) else {
            status = .duplicate
            return false
        }
        guard Book.isValidTitle(title) else {
            status = .missingTitle
            return false
        }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let bookID = add(cleanTitle, author) else {
            status = .missingTitle
            return false
        }
        // Un ISBN que apuntaba a un libro ya borrado se sustituye.
        records.removeAll { $0.isbn == isbn || $0.bookID == bookID }
        records.append(BookISBN(bookID: bookID, isbn: isbn))
        save()
        isbnText = ""
        title = ""
        author = ""
        status = .added(title: cleanTitle)
        return true
    }

    /// Olvida el ISBN de un libro (cuando el libro se elimina del listado). Si
    /// el libro no tenía ISBN, no toca el fichero.
    func removeISBN(bookID: UUID) {
        let before = records.count
        records.removeAll { $0.bookID == bookID }
        if records.count != before { save() }
    }
}
#endif
