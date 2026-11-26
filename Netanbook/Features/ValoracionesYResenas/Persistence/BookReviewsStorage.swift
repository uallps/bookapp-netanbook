#if Valoraciones
import Foundation

/// Almacenamiento de las valoraciones y reseñas (F4).
protocol BookReviewsStorage {
    func loadReviews() throws -> [BookReview]
    func saveReviews(_ reviews: [BookReview]) throws
}

/// Guarda las valoraciones en su propio fichero JSON (`netanbook-valoraciones.json`).
final class JSONBookReviewsStorage: BookReviewsStorage {
    private let fileURL: URL

    init(filename: String = "netanbook-valoraciones.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent(filename)
    }

    func loadReviews() throws -> [BookReview] {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([BookReview].self, from: data)
    }

    func saveReviews(_ reviews: [BookReview]) throws {
        let data = try JSONEncoder().encode(reviews)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }
}

/// Almacenamiento en memoria para pruebas y vistas previas.
final class MockBookReviewsStorage: BookReviewsStorage {
    var reviews: [BookReview]
    private(set) var saveCount = 0

    init(reviews: [BookReview] = []) {
        self.reviews = reviews
    }

    func loadReviews() throws -> [BookReview] { reviews }

    func saveReviews(_ reviews: [BookReview]) throws {
        self.reviews = reviews
        saveCount += 1
    }
}
#endif