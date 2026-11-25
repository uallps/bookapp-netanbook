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
    /// Una página que no sea mayor que 0 se guarda como «sin página».
    @discardableResult
    func addNote(bookID: UUID, kind: NoteKind, text: String, page: Int? = nil) -> Bool {
        guard BookNote.isValidText(text) else { return false }
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        notes.append(BookNote(bookID: bookID, kind: kind, text: clean, page: BookNote.validPage(page)))
        save()
        return true
    }

    /// Edita el tipo, el texto y la página de una anotación. Devuelve `false`
    /// si no existe o si el texto queda vacío; en ese caso no cambia nada.
    @discardableResult
    func updateNote(id: UUID, kind: NoteKind, text: String, page: Int?) -> Bool {
        guard BookNote.isValidText(text),
              let index = notes.firstIndex(where: { $0.id == id }) else { return false }
        notes[index].kind = kind
        notes[index].text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        notes[index].page = BookNote.validPage(page)
        save()
        return true
    }

    /// Borra una anotación.
    func removeNote(id: UUID) {
        notes.removeAll { $0.id == id }
        save()
    }

    /// Borra todas las anotaciones de un libro (cuando el libro se elimina del
    /// listado). Si el libro no tenía notas, no toca el fichero.
    func removeNotes(bookID: UUID) {
        let before = notes.count
        notes.removeAll { $0.bookID == bookID }
        if notes.count != before { save() }
    }
}
#endif
