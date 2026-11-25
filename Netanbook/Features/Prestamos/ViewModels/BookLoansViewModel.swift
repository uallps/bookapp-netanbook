#if Prestamos
import Foundation
import Observation

/// ViewModel de O2 · Préstamos.
///
/// Guarda los préstamos de todos los libros. Es independiente del ViewModel del
/// listado: el Core no sabe que existe. Regla principal: un libro solo puede
/// tener un préstamo abierto a la vez. Cada cambio se guarda en el
/// almacenamiento propio de O2 (`BookLoansStorage`).
@Observable
final class BookLoansViewModel {
    /// Todos los préstamos. Solo este ViewModel puede modificarlos.
    private(set) var loans: [BookLoan] = []

    @ObservationIgnored private let storage: BookLoansStorage

    /// Carga los préstamos guardados. Si aún no hay nada guardado, empieza con
    /// los préstamos de ejemplo de los libros de ejemplo.
    init(storage: BookLoansStorage = JSONBookLoansStorage()) {
        self.storage = storage
        loans = (try? storage.loadLoans()) ?? BookLoan.samples
    }

    private func save() {
        do {
            try storage.saveLoans(loans)
        } catch {
            print("No se han guardado los préstamos: \(error)")
        }
    }

    /// Préstamo abierto de un libro, o `nil` si está en casa.
    func openLoan(for bookID: UUID) -> BookLoan? {
        loans.first { $0.bookID == bookID && $0.isOpen }
    }

    /// Préstamos ya devueltos de un libro, del más reciente al más antiguo.
    func history(for bookID: UUID) -> [BookLoan] {
        loans.filter { $0.bookID == bookID && !$0.isOpen }
            .sorted { $0.loanDate > $1.loanDate }
    }

    /// Presta un libro. Devuelve `false` si el nombre está vacío o si el libro
    /// ya está prestado. Con `days` mayor que 0 se fija la fecha prevista de
    /// devolución: esos días de calendario después del préstamo.
    @discardableResult
    func lend(bookID: UUID, to borrower: String, days: Int? = nil, now: Date = Date()) -> Bool {
        guard BookLoan.isValidBorrower(borrower), openLoan(for: bookID) == nil else { return false }
        let clean = borrower.trimmingCharacters(in: .whitespacesAndNewlines)
        var due: Date?
        if let days, days > 0 {
            due = Calendar.current.date(byAdding: .day, value: days, to: now)
        }
        loans.append(BookLoan(bookID: bookID, borrowerName: clean, loanDate: now, dueDate: due))
        save()
        return true
    }

    /// Marca un préstamo como devuelto. Devuelve `false` si no existe o ya
    /// estaba devuelto.
    @discardableResult
    func markReturned(id: UUID, now: Date = Date()) -> Bool {
        guard let index = loans.firstIndex(where: { $0.id == id && $0.isOpen }) else { return false }
        loans[index].returnedDate = now
        save()
        return true
    }

    /// Borra todos los préstamos de un libro (cuando el libro se elimina del
    /// listado). Si el libro no tenía préstamos, no toca el fichero.
    func removeLoans(bookID: UUID) {
        let before = loans.count
        loans.removeAll { $0.bookID == bookID }
        if loans.count != before { save() }
    }
}
#endif
