#if ObjetivoAnual
import Foundation

/// Almacenamiento de O4 · Objetivo anual.
protocol AnnualGoalStorage {
    func loadGoalData() throws -> AnnualGoalData
    func saveGoalData(_ data: AnnualGoalData) throws
}

/// Guarda la meta anual y las fechas de finalización en `netanbook-objetivo-anual.json`.
final class JSONAnnualGoalStorage: AnnualGoalStorage {
    private let fileURL: URL

    init(filename: String = "netanbook-objetivo-anual.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent(filename)
    }

    func loadGoalData() throws -> AnnualGoalData {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(AnnualGoalData.self, from: data)
    }

    func saveGoalData(_ goalData: AnnualGoalData) throws {
        let data = try JSONEncoder().encode(goalData)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }
}

/// Almacenamiento en memoria para pruebas y vistas previas.
final class MockAnnualGoalStorage: AnnualGoalStorage {
    var data: AnnualGoalData
    private(set) var saveCount = 0

    init(data: AnnualGoalData = AnnualGoalData()) {
        self.data = data
    }

    func loadGoalData() throws -> AnnualGoalData { data }

    func saveGoalData(_ data: AnnualGoalData) throws {
        self.data = data
        saveCount += 1
    }
}
#endif