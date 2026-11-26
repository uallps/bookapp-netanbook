#if SesionesLectura
import Foundation

/// Almacenamiento de las sesiones de lectura (O1).
///
/// Es de la característica, no del Core: `BookStorageProvider` no sabe que las
/// sesiones existen. Si O1 no se compila, este fichero queda vacío.
protocol ReadingSessionsStorage {
    func loadSessions() throws -> [ReadingSession]
    func saveSessions(_ sessions: [ReadingSession]) throws
}

/// Guarda las sesiones en su propio fichero JSON, junto al de los libros.
final class JSONReadingSessionsStorage: ReadingSessionsStorage {
    private let fileURL: URL

    init(filename: String = "netanbook-sesiones.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent(filename)
    }

    func loadSessions() throws -> [ReadingSession] {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([ReadingSession].self, from: data)
    }

    /// Escritura atómica: si la app se cierra a mitad, el fichero anterior sigue entero.
    func saveSessions(_ sessions: [ReadingSession]) throws {
        let data = try JSONEncoder().encode(sessions)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }
}

/// Almacenamiento en memoria para pruebas y vistas previas: no toca el disco.
final class MockReadingSessionsStorage: ReadingSessionsStorage {
    var sessions: [ReadingSession]
    /// Veces que se ha guardado: las pruebas comprueban que no se guarda sin cambios.
    private(set) var saveCount = 0

    init(sessions: [ReadingSession] = []) {
        self.sessions = sessions
    }

    func loadSessions() throws -> [ReadingSession] { sessions }

    func saveSessions(_ sessions: [ReadingSession]) throws {
        self.sessions = sessions
        saveCount += 1
    }
}
#endif
