import Foundation

/// F3 · Categorías (boceto). Se llama `BookCategory` para no chocar con el tipo
/// `Category` del runtime de Objective-C en las plataformas de Apple.
struct BookCategory: Identifiable {
    let id = UUID()
    var name: String
}

/// Relación n:m entre libros y categorías: la asignación es un tipo aparte,
/// así `Book` no necesita saber nada de F3.
struct BookCategoryAssignment {
    var bookID: UUID
    var categoryID: UUID
}
