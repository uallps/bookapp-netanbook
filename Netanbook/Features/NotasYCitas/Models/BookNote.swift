#if Notas
import Foundation

// F2 · Notas y citas (opcional). Solo se compila con la variable `Notas`:
// `--traits Notas` en SwiftPM.
//
// Relación con el libro: 1 libro → 0..N anotaciones.
// Cada anotación apunta a su libro con `bookID`; el libro no conoce sus notas.

/// Tipo de anotación.
enum NoteKind: String, CaseIterable, Codable {
    case note = "Nota"
    case quote = "Cita"
}

/// Anotación personal (nota o cita) vinculada a un libro.
struct BookNote: Identifiable, Codable {
    let id: UUID

    /// Libro al que pertenece (`Book.id`).
    let bookID: UUID

    var kind: NoteKind

    /// Texto de la nota o de la cita. Obligatorio y no vacío.
    var text: String

    /// Página de la cita, si se conoce. Si existe, es mayor que 0.
    var page: Int?

    let createdAt: Date

    init(
        id: UUID = UUID(),
        bookID: UUID,
        kind: NoteKind = .note,
        text: String,
        page: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.bookID = bookID
        self.kind = kind
        self.text = text
        self.page = page
        self.createdAt = createdAt
    }

    /// El texto es válido si no está vacío ni son solo espacios.
    static func isValidText(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Página que se guarda: la indicada si es mayor que 0; si no, ninguna.
    static func validPage(_ page: Int?) -> Int? {
        guard let page, page > 0 else { return nil }
        return page
    }
}

extension BookNote {
    /// Anotaciones de ejemplo de los libros de ejemplo del Core.
    static let samples: [BookNote] = [
        BookNote(bookID: Book.SampleID.cienAnos, kind: .quote,
                 text: "Muchos años después, frente al pelotón de fusilamiento…", page: 9),
        BookNote(bookID: Book.SampleID.nombreDelViento, kind: .note,
                 text: "Releer la escena de la taberna."),
    ]
}
#endif
