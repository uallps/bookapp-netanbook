import Foundation

/// F4 · Valoraciones y reseñas (boceto). Como mucho una valoración por libro.
struct Review {
    var bookID: UUID
    /// Puntuación de 1 a 5 estrellas.
    var rating: Int
    var text: String

    /// Devuelve nil si la puntuación está fuera de 1...5.
    init?(bookID: UUID, rating: Int, text: String = "") {
        guard (1...5).contains(rating) else { return nil }
        self.bookID = bookID
        self.rating = rating
        self.text = text
    }
}
