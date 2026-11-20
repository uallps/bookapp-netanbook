#if Notas
import Foundation
import Observation

/// ViewModel de F2 · Notas y citas.
///
/// Guarda las anotaciones de todos los libros. Es independiente del ViewModel
/// del listado: el Core no sabe que existe. Cada cambio se guarda en el
/// almacenamiento propio de F2 (`BookNotesStorage`).
@Observable
final class BookNotesViewModel {
    /// Todas las anotaciones. Solo este ViewModel puede modificarlas.
    private(set) var notes: [BookNote] = []

    @ObservationIgnored private let storage: BookNotesStorage

    /// Carga las notas guardadas. Si aún no hay nada guardado, empieza con las
    /// notas de ejemplo de los libros de ejemplo.
    init(storage: BookNotesStorage = JSONBookNotesStorage()) {
        self.storage = storage
        notes = (try? storage.loadNotes()) ?? BookNote.samples
    }

    private func save() {
        do {
            try storage.saveNotes(notes)
        } catch {
            print("No se han guardado las notas: \(error)")
        }
    }

    /// Anotaciones de un libro, de la más reciente a la más antigua.
    func notes(for bookID: UUID) -> [BookNote] {
        notes.filter { $0.bookID == bookID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Añade una anotación. Devuelve `false` si el texto está vacío.
    @discardableResult
    func addNote(bookID: UUID, kind: NoteKind, text: String, page: Int? = nil) -> Bool {
        guard BookNote.isValidText(text) else { return false }
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let validPage = page.flatMap { $0 > 0 ? $0 : nil }
        notes.append(BookNote(bookID: bookID, kind: kind, text: clean, page: validPage))
        save()
        return true
    }

    /// Borra una anotación.
    func removeNote(id: UUID) {
        notes.removeAll { $0.id == id }
        save()
    }

    /// Borra todas las anotaciones de un libro (cuando el libro se elimina del listado).
    func removeNotes(bookID: UUID) {
        notes.removeAll { $0.bookID == bookID }
        save()
    }
}
#endif
