#if Valoraciones
import Foundation
import Observation

/// ViewModel de F4 · Valoraciones y reseñas.
@Observable
final class BookReviewsViewModel {
    private(set) var reviews: [BookReview] = []

    @ObservationIgnored private let storage: BookReviewsStorage

    init(storage: BookReviewsStorage = JSONBookReviewsStorage()) {
        self.storage = storage
        reviews = (try? storage.loadReviews()) ?? BookReview.samples
    }

    private func save() {
        do {
            try storage.saveReviews(reviews)
        } catch {
            print("No se han guardado las valoraciones: \(error)")
        }
    }

    /// Valoración actual de un libro (0 o 1).
    func review(for bookID: UUID) -> BookReview? {
        reviews.first { $0.bookID == bookID }
    }

    /// Crea o actualiza la valoración de un libro (1..5 estrellas y reseña opcional).
    @discardableResult
    func saveReview(bookID: UUID, rating: Int, text: String?) -> Bool {
        guard BookReview.isValidRating(rating) else { return false }
        let updated = BookReview(bookID: bookID, rating: rating, text: text)
        if let index = reviews.firstIndex(where: { $0.bookID == bookID }) {
            reviews[index] = updated
        } else {
            reviews.append(updated)
        }
        save()
        return true
    }

    /// Elimina la valoración de un libro.
    func removeReview(bookID: UUID) {
        let before = reviews.count
        reviews.removeAll { $0.bookID == bookID }
        if reviews.count != before { save() }
    }
}
#endif