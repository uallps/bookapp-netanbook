import Foundation

/// Libro del Core: solo los datos que comparten todas las variantes de Netanbook.
/// - `id`: identificador único y estable. Se puede pasar en el init para tener
///   libros de ejemplo con ids fijos (las features se enlazan a ellos).
/// - `title`: obligatorio. `author`: puede faltar. `status`: empieza en Pendiente.
///
/// No contiene progreso, notas, categorías ni valoraciones: esos datos son de
/// F1–F4 y viven en sus propios tipos, enlazados por `bookID`.
struct Book: Identifiable {
    let id: UUID
    var title: String
    var author: String?
    var status: ReadingStatus

    init(id: UUID = UUID(), title: String, author: String? = nil, status: ReadingStatus = .pendiente) {
        self.id = id
        self.title = title
        self.author = author
        self.status = status
    }
}
