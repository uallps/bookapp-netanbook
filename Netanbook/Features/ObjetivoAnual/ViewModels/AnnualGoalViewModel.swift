#if ObjetivoAnual
import Foundation
import Observation

/// ViewModel de O4 · Objetivo anual.
/// Gestiona la meta anual de lectura y las fechas en que se termina cada libro.
@Observable
final class AnnualGoalViewModel {
    private(set) var data: AnnualGoalData

    @ObservationIgnored private let storage: AnnualGoalStorage

    init(storage: AnnualGoalStorage = JSONAnnualGoalStorage()) {
        self.storage = storage
        data = (try? storage.loadGoalData()) ?? AnnualGoalData.sample
    }

    private func save() {
        do {
            try storage.saveGoalData(data)
        } catch {
            print("No se ha guardado el objetivo anual: \(error)")
        }
    }

    /// Meta de libros fijada por el usuario para el año.
    var targetBooks: Int {
        data.targetBooks
    }

    /// Actualiza el número de libros objetivo para el año.
    func setTargetBooks(_ target: Int) {
        data.targetBooks = AnnualGoalData.clampedTarget(target)
        save()
    }

    /// Fecha en la que se terminó un libro concreto, si consta en O4.
    func completionDate(for bookID: UUID) -> Date? {
        data.records.first { $0.bookID == bookID }?.completedAt
    }

    /// Marca o actualiza la fecha de finalización de un libro.
    func markCompleted(bookID: UUID, on date: Date = Date()) {
        if let index = data.records.firstIndex(where: { $0.bookID == bookID }) {
            data.records[index].completedAt = date
        } else {
            data.records.append(CompletedBookRecord(bookID: bookID, completedAt: date))
        }
        save()
    }

    /// Quita la fecha de finalización de un libro (por ejemplo si pasa de Terminado a Pendiente).
    func clearCompletion(bookID: UUID) {
        let before = data.records.count
        data.records.removeAll { $0.bookID == bookID }
        if data.records.count != before { save() }
    }

    /// Sincroniza automáticamente cuando el estado del libro cambia en el Core.
    func syncBookStatus(bookID: UUID, status: ReadingStatus) {
        if status == .finished {
            if completionDate(for: bookID) == nil {
                markCompleted(bookID: bookID, on: Date())
            }
        } else {
            clearCompletion(bookID: bookID)
        }
    }

    /// Número de libros terminados en un año concreto (por defecto, el año actual).
    func completedCount(inYear year: Int = Calendar.current.component(.year, from: Date()), validBookIDs: Set<UUID>) -> Int {
        let calendar = Calendar.current
        return data.records.filter { record in
            validBookIDs.contains(record.bookID) &&
            calendar.component(.year, from: record.completedAt) == year
        }.count
    }
}
#endif