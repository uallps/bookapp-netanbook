#if Categorias
import Foundation

/// Almacenamiento de las categorías y sus asignaciones (F3).
///
/// Es de la característica, no del Core: `BookStorageProvider` no sabe que las
/// categorías existen. Si F3 no se compila, este fichero queda vacío.
protocol BookCategoriesStorage {
    func loadCategories() throws -> BookCategoriesData
    func saveCategories(_ data: BookCategoriesData) throws
}

/// Guarda las categorías en su propio fichero JSON, junto al de los libros.
final class JSONBookCategoriesStorage: BookCategoriesStorage {
    private let fileURL: URL

    init(filename: String = "netanbook-categorias.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent(filename)
    }

    func loadCategories() throws -> BookCategoriesData {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(BookCategoriesData.self, from: data)
    }

    /// Escritura atómica: si la app se cierra a mitad, el fichero anterior sigue entero.
    func saveCategories(_ data: BookCategoriesData) throws {
        let encoded = try JSONEncoder().encode(data)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoded.write(to: fileURL, options: .atomic)
    }
}

/// Almacenamiento en memoria para pruebas y vistas previas: no toca el disco.
final class MockBookCategoriesStorage: BookCategoriesStorage {
    var data: BookCategoriesData
    /// Veces que se ha guardado: las pruebas comprueban que no se guarda sin cambios.
    private(set) var saveCount = 0

    init(data: BookCategoriesData = BookCategoriesData(categories: [], assignments: [])) {
        self.data = data
    }

    func loadCategories() throws -> BookCategoriesData { data }

    func saveCategories(_ data: BookCategoriesData) throws {
        self.data = data
        saveCount += 1
    }
}
#endif
