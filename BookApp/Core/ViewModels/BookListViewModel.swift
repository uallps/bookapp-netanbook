import Foundation
import Observation

/// ViewModel del listado (Core). Es el único que guarda y modifica la colección
/// de libros: la vista lee `books` y le comunica lo que pulsa el usuario.
/// No sabe nada de F1–F5: el Core funciona aunque todas estén desactivadas.
@Observable
final class BookListViewModel {
    private(set) var books: [Book] = SampleLibrary.books

    /// Añade un libro. Devuelve false si el título está vacío (el título es obligatorio).
    @discardableResult
    func addBook(title: String, author: String? = nil) -> Bool {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return false }
        let cleanAuthor = author?.trimmingCharacters(in: .whitespacesAndNewlines)
        books.append(Book(title: cleanTitle, author: (cleanAuthor?.isEmpty ?? true) ? nil : cleanAuthor))
        return true
    }

    /// Pasa el libro al siguiente estado de lectura.
    func advanceStatus(id: UUID) {
        guard let index = books.firstIndex(where: { $0.id == id }) else { return }
        books[index].status = books[index].status.next
    }

    func deleteBook(id: UUID) {
        books.removeAll { $0.id == id }
    }
}
