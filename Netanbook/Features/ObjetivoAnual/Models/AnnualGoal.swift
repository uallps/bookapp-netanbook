#if ObjetivoAnual
import Foundation

// O4 · Objetivo anual (característica original). Solo se compila con `--traits ObjetivoAnual`.
// Relación con el libro: guarda la meta anual y registra la fecha de finalización
// de cada libro (`bookID` → `completedAt`), sin modificar la entidad `Book` del Core.

/// Registro de finalización de un libro asociado a O4.
struct CompletedBookRecord: Identifiable, Codable, Sendable {
    var id: UUID { bookID }
    let bookID: UUID
    var completedAt: Date
}

/// Estado persistido de O4: meta anual y libros registrados como terminados con su fecha.
struct AnnualGoalData: Codable, Sendable {
    var targetBooks: Int
    var records: [CompletedBookRecord]

    static let defaultTarget = 12
    static let validTargetRange = 1...500

    init(targetBooks: Int = defaultTarget, records: [CompletedBookRecord] = []) {
        self.targetBooks = Self.clampedTarget(targetBooks)
        self.records = records
    }

    static func clampedTarget(_ value: Int) -> Int {
        min(max(value, validTargetRange.lowerBound), validTargetRange.upperBound)
    }
}

extension AnnualGoalData {
    /// Datos de ejemplo: Cien años de soledad ya viene como `.finished` en SampleBooks.
    static let sample = AnnualGoalData(
        targetBooks: 12,
        records: [
            CompletedBookRecord(bookID: Book.SampleID.cienAnos, completedAt: Date())
        ]
    )
}
#endif