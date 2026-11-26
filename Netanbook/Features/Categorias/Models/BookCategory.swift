#if Categorias
import Foundation

// F3 · Categorías (opcional). Solo se compila con la variable `Categorias`:
// `--traits Categorias` en SwiftPM.
//
// Relación con el libro: N libros ↔ M categorías.
// La asociación se guarda aparte (`BookCategoryAssignment`), así ni `Book`
// ni `BookCategory` dependen el uno del otro.

/// Categoría creada por el usuario (género, curso, tema...).
struct BookCategory: Identifiable, Hashable, Codable {
    let id: UUID

    /// Nombre de la categoría. Obligatorio, no vacío y sin repetir
    /// (sin distinguir mayúsculas, minúsculas ni tildes).
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = BookCategory.cleanName(name)
    }

    /// Nombre sin espacios al principio ni al final.
    static func cleanName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// El nombre es válido si no está vacío ni son solo espacios.
    static func isValidName(_ name: String) -> Bool {
        !cleanName(name).isEmpty
    }

    /// Forma del nombre para comparar: «Fantasía», «fantasia» y « FANTASÍA »
    /// son la misma categoría.
    static func comparableName(_ name: String) -> String {
        cleanName(name).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}

/// Asignación de un libro a una categoría.
struct BookCategoryAssignment: Hashable, Codable {
    /// Libro asignado (`Book.id`).
    let bookID: UUID

    /// Categoría asignada (`BookCategory.id`).
    let categoryID: UUID
}

/// Todo lo que guarda F3: las categorías y sus asignaciones, en un solo fichero.
struct BookCategoriesData: Codable {
    var categories: [BookCategory]
    var assignments: [BookCategoryAssignment]
}

extension BookCategoriesData {
    /// Identificadores fijos de las categorías de ejemplo.
    enum SampleID {
        static let novela = UUID(uuidString: "0C1A7E60-0001-4000-8000-000000000001")!
        static let fantasia = UUID(uuidString: "0C1A7E60-0002-4000-8000-000000000002")!
        static let clasicos = UUID(uuidString: "0C1A7E60-0003-4000-8000-000000000003")!
    }

    /// Categorías de ejemplo asignadas a los libros de ejemplo del Core.
    static let samples = BookCategoriesData(
        categories: [
            BookCategory(id: SampleID.novela, name: "Novela"),
            BookCategory(id: SampleID.fantasia, name: "Fantasía"),
            BookCategory(id: SampleID.clasicos, name: "Clásicos"),
        ],
        assignments: [
            BookCategoryAssignment(bookID: Book.SampleID.cienAnos, categoryID: SampleID.novela),
            BookCategoryAssignment(bookID: Book.SampleID.cienAnos, categoryID: SampleID.clasicos),
            BookCategoryAssignment(bookID: Book.SampleID.nombreDelViento, categoryID: SampleID.novela),
            BookCategoryAssignment(bookID: Book.SampleID.nombreDelViento, categoryID: SampleID.fantasia),
            BookCategoryAssignment(bookID: Book.SampleID.lazarillo, categoryID: SampleID.clasicos),
        ]
    )
}
#endif
