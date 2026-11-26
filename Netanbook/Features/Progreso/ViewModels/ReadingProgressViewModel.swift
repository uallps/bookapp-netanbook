#if Progreso
import Foundation
import Observation

/// ViewModel de F1 · Progreso.
///
/// Guarda el progreso de cada libro, indexado por `Book.id`. Es independiente
/// del ViewModel del listado: el Core no sabe que existe. Cada cambio se guarda
/// en el almacenamiento propio de F1 (`ReadingProgressStorage`).
@Observable
final class ReadingProgressViewModel {
    /// Progreso de cada libro. Solo este ViewModel puede modificarlo.
    private(set) var progressByBook: [UUID: ReadingProgress] = [:]

    @ObservationIgnored private let storage: ReadingProgressStorage

    /// Carga el progreso guardado. Si aún no hay nada guardado, empieza con el
    /// progreso de ejemplo de los libros de ejemplo.
    init(storage: ReadingProgressStorage = JSONReadingProgressStorage()) {
        self.storage = storage
        let progress = (try? storage.loadProgress()) ?? ReadingProgress.samples
        for item in progress {
            progressByBook[item.bookID] = item
        }
    }

    private func save() {
        do {
            try storage.saveProgress(Array(progressByBook.values))
        } catch {
            print("No se ha guardado el progreso: \(error)")
        }
    }

    /// Progreso de un libro, o `nil` si todavía no tiene.
    func progress(for bookID: UUID) -> ReadingProgress? {
        progressByBook[bookID]
    }

    /// Registra o actualiza el progreso de un libro: la página actual y el
    /// total de páginas (opcional). Devuelve `false` y no cambia nada si los
    /// datos no son válidos (página negativa, total 0 o menor, o página que
    /// pasa del total). Si no cambia nada, no toca el fichero.
    @discardableResult
    func setProgress(bookID: UUID, currentPage: Int, totalPages: Int?) -> Bool {
        guard ReadingProgress.isValid(currentPage: currentPage, totalPages: totalPages) else { return false }
        let item = ReadingProgress(bookID: bookID, totalPages: totalPages, currentPage: currentPage)
        guard progressByBook[bookID] != item else { return true }
        progressByBook[bookID] = item
        save()
        return true
    }

    /// Cambia solo la página actual y conserva el total. Lo usa O1 al terminar
    /// una sesión de lectura. Devuelve `false` si la página no es válida.
    @discardableResult
    func setCurrentPage(bookID: UUID, page: Int) -> Bool {
        setProgress(bookID: bookID, currentPage: page, totalPages: progressByBook[bookID]?.totalPages)
    }

    /// Avanza la página actual de un libro sin pasar del total.
    /// Si el libro aún no tenía progreso, lo empieza.
    func advance(bookID: UUID, by pages: Int = 10) {
        var item = progressByBook[bookID]
            ?? ReadingProgress(bookID: bookID, totalPages: nil, currentPage: 0)
        let next = item.currentPage + pages
        if let total = item.totalPages {
            item.currentPage = min(next, total)
        } else {
            item.currentPage = next
        }
        progressByBook[bookID] = item
        save()
    }

    /// Borra el progreso de un libro (cuando el libro se elimina del listado).
    /// Si el libro no tenía progreso, no toca el fichero.
    func removeProgress(bookID: UUID) {
        guard progressByBook[bookID] != nil else { return }
        progressByBook[bookID] = nil
        save()
    }
}
#endif
