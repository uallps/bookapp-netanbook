#if AltaISBN
import Foundation

/// Almacenamiento de los ISBN de los libros dados de alta con O3.
///
/// Es de la característica, no del Core: `BookStorageProvider` no sabe que los
/// ISBN existen. Si O3 no se compila, este fichero queda vacío.
protocol BookISBNStorage {
    func loadRecords() throws -> [BookISBN]
    func saveRecords(_ records: [BookISBN]) throws
}

/// Guarda los ISBN en su propio fichero JSON, junto al de los libros.
final class JSONBookISBNStorage: BookISBNStorage {
    private let fileURL: URL

    init(filename: String = "netanbook-isbn.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent(filename)
    }

    func loadRecords() throws -> [BookISBN] {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([BookISBN].self, from: data)
    }

    /// Escritura atómica: si la app se cierra a mitad, el fichero anterior sigue entero.
    func saveRecords(_ records: [BookISBN]) throws {
        let data = try JSONEncoder().encode(records)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }
}

/// Almacenamiento en memoria para pruebas y vistas previas: no toca el disco.
final class MockBookISBNStorage: BookISBNStorage {
    var records: [BookISBN]
    /// Veces que se ha guardado: las pruebas comprueban que no se guarda sin cambios.
    private(set) var saveCount = 0

    init(records: [BookISBN] = []) {
        self.records = records
    }

    func loadRecords() throws -> [BookISBN] { records }

    func saveRecords(_ records: [BookISBN]) throws {
        self.records = records
        saveCount += 1
    }
}
#endif
