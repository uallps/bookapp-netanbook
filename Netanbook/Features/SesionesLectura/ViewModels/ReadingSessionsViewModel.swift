#if SesionesLectura
import Foundation
import Observation

/// ViewModel de O1 · Sesiones de lectura.
///
/// Guarda las sesiones de todos los libros. Es independiente del ViewModel del
/// listado y del de F1: no actualiza la página actual él mismo. Al terminar una
/// sesión, quien lo usa (el listado) pasa la página final a F1. Así cada
/// característica solo modifica sus propios datos.
@Observable
final class ReadingSessionsViewModel {
    /// Todas las sesiones. Solo este ViewModel puede modificarlas.
    private(set) var sessions: [ReadingSession] = []

    @ObservationIgnored private let storage: ReadingSessionsStorage
    /// Reloj: en la app es la hora actual; en las pruebas, una hora fija.
    @ObservationIgnored private let now: () -> Date

    /// Carga las sesiones guardadas. Si aún no hay nada guardado, empieza sin sesiones.
    init(storage: ReadingSessionsStorage = JSONReadingSessionsStorage(), now: @escaping () -> Date = { Date() }) {
        self.storage = storage
        self.now = now
        sessions = (try? storage.loadSessions()) ?? []
    }

    private func save() {
        do {
            try storage.saveSessions(sessions)
        } catch {
            print("No se han guardado las sesiones de lectura: \(error)")
        }
    }

    // MARK: - Consultas

    /// La sesión en curso de un libro, si hay una.
    func activeSession(for bookID: UUID) -> ReadingSession? {
        sessions.first { $0.bookID == bookID && $0.isActive }
    }

    /// Sesiones terminadas de un libro, de la más reciente a la más antigua.
    func history(for bookID: UUID) -> [ReadingSession] {
        sessions
            .filter { $0.bookID == bookID && !$0.isActive }
            .sorted { $0.startDate > $1.startDate }
    }

    /// Tiempo total de lectura de un libro (solo sesiones terminadas), en segundos.
    func totalDuration(for bookID: UUID) -> TimeInterval {
        history(for: bookID).compactMap(\.duration).reduce(0, +)
    }

    /// Páginas leídas en total en las sesiones terminadas de un libro.
    func totalPagesRead(for bookID: UUID) -> Int {
        history(for: bookID).compactMap(\.pagesRead).reduce(0, +)
    }

    // MARK: - Acciones

    /// Inicia una sesión desde una página. Devuelve `false` si el libro ya
    /// tiene una sesión en curso o si la página es negativa.
    @discardableResult
    func start(bookID: UUID, fromPage page: Int) -> Bool {
        guard page >= 0, activeSession(for: bookID) == nil else { return false }
        sessions.append(ReadingSession(bookID: bookID, startDate: now(), startPage: page))
        save()
        return true
    }

    /// Termina la sesión en curso de un libro en una página. Devuelve la sesión
    /// terminada, o `nil` si no había ninguna en curso o si la página final es
    /// menor que la inicial (en ese caso no cambia nada).
    @discardableResult
    func stop(bookID: UUID, atPage page: Int) -> ReadingSession? {
        guard let index = sessions.firstIndex(where: { $0.bookID == bookID && $0.isActive }),
              page >= sessions[index].startPage else { return nil }
        sessions[index].endDate = now()
        sessions[index].endPage = page
        save()
        return sessions[index]
    }

    /// Descarta la sesión en curso de un libro sin guardarla en el historial.
    func cancel(bookID: UUID) {
        let before = sessions.count
        sessions.removeAll { $0.bookID == bookID && $0.isActive }
        if sessions.count != before { save() }
    }

    /// Borra una sesión del historial.
    func removeSession(id: UUID) {
        let before = sessions.count
        sessions.removeAll { $0.id == id }
        if sessions.count != before { save() }
    }

    /// Borra todas las sesiones de un libro (cuando el libro se elimina del
    /// listado). Si el libro no tenía ninguna, no toca el fichero.
    func removeSessions(bookID: UUID) {
        let before = sessions.count
        sessions.removeAll { $0.bookID == bookID }
        if sessions.count != before { save() }
    }
}
#endif
