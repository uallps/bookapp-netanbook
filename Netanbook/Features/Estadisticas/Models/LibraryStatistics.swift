#if Estadisticas
import Foundation

// F5 · Estadísticas (opcional). Solo se compila con la variable `Estadisticas`:
// `--traits Estadisticas` en SwiftPM.
//
// Relación con el libro: no guarda datos propios. Se calcula a partir de la
// colección de libros del Core (`[Book]`) y de su estado, así que no requiere
// F1 ni ninguna otra característica, y no tiene almacenamiento.

/// Resumen de la biblioteca: total de libros y cuántos hay en cada estado.
struct LibraryStatistics: Equatable, Sendable {
    /// Total de libros.
    let totalBooks: Int

    /// Número de libros en cada estado.
    let pendingCount: Int
    let readingCount: Int
    let finishedCount: Int

    /// Calcula las estadísticas de una colección de libros.
    init(books: [Book]) {
        totalBooks = books.count
        pendingCount = books.filter { $0.status == .pending }.count
        readingCount = books.filter { $0.status == .reading }.count
        finishedCount = books.filter { $0.status == .finished }.count
    }

    /// Número de libros con un estado concreto.
    func count(for status: ReadingStatus) -> Int {
        switch status {
        case .pending: return pendingCount
        case .reading: return readingCount
        case .finished: return finishedCount
        }
    }

    /// Porcentaje de libros terminados (de 0 a 100, redondeado).
    /// `nil` si la biblioteca está vacía: no tiene sentido un porcentaje de nada.
    var finishedPercentage: Int? {
        guard totalBooks > 0 else { return nil }
        return Int((Double(finishedCount) / Double(totalBooks) * 100).rounded())
    }
}
#endif
