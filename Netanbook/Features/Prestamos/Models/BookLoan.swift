#if Prestamos
import Foundation

// O2 · Préstamos (original, opcional). Solo se compila con la variable
// `Prestamos`: `--traits Prestamos` en SwiftPM.
// Saber a quién se ha prestado un libro físico, cuándo y si ya se ha devuelto.
//
// Relación con el libro: 1 libro → 0..N préstamos (como mucho uno abierto).
// El préstamo apunta al libro con `bookID`; el libro no conoce sus préstamos.

/// Préstamo de un libro a otra persona.
struct BookLoan: Identifiable, Codable {
    let id: UUID

    /// Libro prestado (`Book.id`).
    let bookID: UUID

    /// Persona que tiene el libro. Obligatorio y no vacío.
    var borrowerName: String

    var loanDate: Date

    /// Fecha prevista de devolución, si se ha acordado.
    var dueDate: Date?

    /// Fecha real de devolución; `nil` mientras el préstamo siga abierto.
    var returnedDate: Date?

    init(
        id: UUID = UUID(),
        bookID: UUID,
        borrowerName: String,
        loanDate: Date = Date(),
        dueDate: Date? = nil,
        returnedDate: Date? = nil
    ) {
        self.id = id
        self.bookID = bookID
        self.borrowerName = borrowerName
        self.loanDate = loanDate
        self.dueDate = dueDate
        self.returnedDate = returnedDate
    }

    /// El préstamo sigue abierto mientras no se haya devuelto.
    var isOpen: Bool { returnedDate == nil }

    /// Vencido: sigue abierto y ya ha pasado el día previsto de devolución.
    /// El mismo día de la devolución todavía no cuenta como vencido.
    func isOverdue(at date: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard isOpen, let dueDate else { return false }
        return calendar.startOfDay(for: date) > calendar.startOfDay(for: dueDate)
    }

    /// El nombre es válido si no está vacío ni son solo espacios.
    static func isValidBorrower(_ name: String) -> Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension BookLoan {
    /// Préstamos de ejemplo de los libros de ejemplo del Core.
    static let samples: [BookLoan] = [
        BookLoan(bookID: Book.SampleID.lazarillo, borrowerName: "Ana",
                 loanDate: Date().addingTimeInterval(-5 * 86_400),
                 dueDate: Date().addingTimeInterval(9 * 86_400)),
        BookLoan(bookID: Book.SampleID.cienAnos, borrowerName: "Luis",
                 loanDate: Date().addingTimeInterval(-60 * 86_400),
                 dueDate: Date().addingTimeInterval(-30 * 86_400),
                 returnedDate: Date().addingTimeInterval(-35 * 86_400)),
    ]
}
#endif
