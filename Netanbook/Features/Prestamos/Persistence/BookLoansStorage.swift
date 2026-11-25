#if Prestamos
import Foundation

/// Almacenamiento de los préstamos (O2).
///
/// Es de la característica, no del Core: `BookStorageProvider` no sabe que los
/// préstamos existen. Si O2 no se compila, este fichero queda vacío.
protocol BookLoansStorage {
    func loadLoans() throws -> [BookLoan]
    func saveLoans(_ loans: [BookLoan]) throws
}

/// Guarda los préstamos en su propio fichero JSON, junto al de los libros.
final class JSONBookLoansStorage: BookLoansStorage {
    private let fileURL: URL

    init(filename: String = "netanbook-prestamos.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent(filename)
    }

    func loadLoans() throws -> [BookLoan] {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([BookLoan].self, from: data)
    }

    /// Escritura atómica: si la app se cierra a mitad, el fichero anterior sigue entero.
    func saveLoans(_ loans: [BookLoan]) throws {
        let data = try JSONEncoder().encode(loans)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }
}

/// Almacenamiento en memoria para pruebas y vistas previas: no toca el disco.
final class MockBookLoansStorage: BookLoansStorage {
    var loans: [BookLoan]
    /// Veces que se ha guardado: las pruebas comprueban que no se guarda sin cambios.
    private(set) var saveCount = 0

    init(loans: [BookLoan] = []) {
        self.loans = loans
    }

    func loadLoans() throws -> [BookLoan] { loans }

    func saveLoans(_ loans: [BookLoan]) throws {
        self.loans = loans
        saveCount += 1
    }
}
#endif
