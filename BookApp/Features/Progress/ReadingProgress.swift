#if Progreso
import Foundation

/// F1 · Progreso. Datos propios de la feature, enlazados al libro por `bookID`.
/// No forman parte de `Book`: sin F1 el libro es exactamente el mismo.
/// Todo el código de F1 está dentro de `#if Progreso`: sin esa variable de
/// compilación (trait en SwiftPM, target «BookApp Progreso» en Xcode) no existe.
struct ReadingProgress {
    let bookID: UUID
    var totalPages: Int
    var currentPage: Int = 0

    /// Porcentaje leído (0...100). Solo existe cuando hay un total válido.
    var percentage: Int? {
        guard totalPages > 0 else { return nil }
        return min(max(currentPage, 0), totalPages) * 100 / totalPages
    }
}

extension SampleLibrary {
    static let progress: [ReadingProgress] = [
        ReadingProgress(bookID: nombreDelViento, totalPages: 662, currentPage: 265),
        ReadingProgress(bookID: cleanCode, totalPages: 464, currentPage: 300),
        ReadingProgress(bookID: cienAnios, totalPages: 471, currentPage: 471),
    ]
}
#endif
