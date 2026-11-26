#if Valoraciones
import Foundation

// F4 · Valoraciones y reseñas (opcional). Solo se compila con `--traits Valoraciones`.
// Relación con el libro: 1 libro → 0..1 valoración global.

/// Valoración y reseña global de un libro.
struct BookReview: Identifiable, Codable, Sendable {
    /// Una valoración por libro: su identidad es la del libro.
    var id: UUID { bookID }

    /// Libro valorado (`Book.id`).
    let bookID: UUID

    /// Puntuación de 1 a 5 (ver `ratingRange`).
    var rating: Int

    /// Reseña breve. Opcional: se puede puntuar sin escribir reseña.
    var text: String?

    /// Rango válido de la puntuación.
    static let ratingRange = 1...5

    init(bookID: UUID, rating: Int, text: String? = nil) {
        self.bookID = bookID
        self.rating = Self.clampedRating(rating)
        let clean = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.text = (clean?.isEmpty ?? true) ? nil : clean
    }

    static func isValidRating(_ rating: Int) -> Bool {
        ratingRange.contains(rating)
    }

    static func clampedRating(_ rating: Int) -> Int {
        min(max(rating, ratingRange.lowerBound), ratingRange.upperBound)
    }
}

extension BookReview {
    /// Valoraciones de ejemplo para los libros de ejemplo del Core.
    static let samples: [BookReview] = [
        BookReview(
            bookID: Book.SampleID.cienAnos,
            rating: 5,
            text: "Una obra maestra imprescindible del realismo mágico."
        )
    ]
}
#endif