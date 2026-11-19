#if Progreso
import Foundation
import Observation

/// ViewModel de F1. Componente independiente: guarda el progreso de cada libro
/// en su propia colección (clave = id del libro). Ni `Book` ni
/// `BookListViewModel` saben que existe.
@Observable
final class ReadingProgressViewModel {
    private(set) var entries: [UUID: ReadingProgress] = [:]

    init(entries: [ReadingProgress] = SampleLibrary.progress) {
        for entry in entries {
            self.entries[entry.bookID] = entry
        }
    }

    func progress(for bookID: UUID) -> ReadingProgress? {
        entries[bookID]
    }

    /// Registra (o corrige) el total de páginas de un libro.
    func setTotalPages(_ total: Int, for bookID: UUID) {
        guard total > 0 else { return }
        var entry = entries[bookID] ?? ReadingProgress(bookID: bookID, totalPages: total)
        entry.totalPages = total
        entry.currentPage = min(entry.currentPage, total)
        entries[bookID] = entry
    }

    /// Actualiza la página actual sumando `delta` (puede ser negativo),
    /// sin bajar de 0 ni pasar del total.
    func changePage(by delta: Int, for bookID: UUID) {
        guard var entry = entries[bookID] else { return }
        entry.currentPage = min(max(entry.currentPage + delta, 0), entry.totalPages)
        entries[bookID] = entry
    }

    /// Se llama cuando el Core elimina un libro, para no dejar datos huérfanos.
    func removeProgress(for bookID: UUID) {
        entries[bookID] = nil
    }
}
#endif
