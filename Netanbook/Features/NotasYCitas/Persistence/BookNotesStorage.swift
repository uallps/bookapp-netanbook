#if Notas
import Foundation

/// Almacenamiento de las notas y citas (F2).
///
/// Es de la característica, no del Core: `BookStorageProvider` no sabe que las
/// notas existen. Si F2 no se compila, este fichero queda vacío.
protocol BookNotesStorage {
    func loadNotes() throws -> [BookNote]
    func saveNotes(_ notes: [BookNote]) throws
}

/// Guarda las notas en su propio fichero JSON, junto al de los libros.
final class JSONBookNotesStorage: BookNotesStorage {
    private let fileURL: URL

    init(filename: String = "netanbook-notas.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent(filename)
    }

    func loadNotes() throws -> [BookNote] {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([BookNote].self, from: data)
    }

    func saveNotes(_ notes: [BookNote]) throws {
        let data = try JSONEncoder().encode(notes)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL)
    }
}

/// Almacenamiento en memoria para pruebas y vistas previas: no toca el disco.
final class MockBookNotesStorage: BookNotesStorage {
    var notes: [BookNote]

    init(notes: [BookNote] = []) {
        self.notes = notes
    }

    func loadNotes() throws -> [BookNote] { notes }
    func saveNotes(_ notes: [BookNote]) throws { self.notes = notes }
}
#endif
