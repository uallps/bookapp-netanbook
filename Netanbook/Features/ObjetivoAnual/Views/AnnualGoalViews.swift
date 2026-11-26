#if ObjetivoAnual
import Foundation
import SwiftUI

/// Tarjeta superior en la biblioteca para fijar el objetivo anual y ver el progreso.
struct AnnualGoalSummaryView: View {
    let targetBooks: Int
    let completedBooks: Int
    let onChangeTarget: (Int) -> Void

    private var currentYear: String {
        String(Calendar.current.component(.year, from: Date()))
    }

    private var progressFraction: Double {
        guard targetBooks > 0 else { return 0 }
        return min(Double(completedBooks) / Double(targetBooks), 1.0)
    }

    var body: some View {
        Section(header: Text("Objetivo anual \(currentYear)")) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(completedBooks) de \(targetBooks) libros terminados")
                    Spacer()
                    Text("\(Int(progressFraction * 100))%")
                        .bookCaption(color: .bookAccent)
                }

                ProgressView(value: progressFraction)

                HStack {
                    Text("Meta anual: \(targetBooks)")
                        .bookCaption()
                    Spacer()
                    Button("-1") {
                        if targetBooks > 1 { onChangeTarget(targetBooks - 1) }
                    }
                    Button("+1") {
                        onChangeTarget(targetBooks + 1)
                    }
                }
            }
        }
    }
}

/// Closures que el detalle de un libro recibe para mostrar/registrar su fecha de fin.
struct AnnualGoalForBook {
    let completionDate: () -> Date?
    let markCompletedToday: () -> Void
    let clearCompletion: () -> Void
}

/// Sección en el detalle del libro para ver o registrar cuándo se terminó.
struct BookCompletionGoalView: View {
    let data: AnnualGoalForBook

    var body: some View {
        let completedDate = data.completionDate()
        Section(header: Text("Objetivo anual · Fecha de finalización")) {
            if let completedDate {
                Text("Terminado el \(formatted(date: completedDate))")
                HStack {
                    Button("Actualizar a hoy") {
                        data.markCompletedToday()
                    }
                    Button("Quitar fecha") {
                        data.clearCompletion()
                    }
                }
            } else {
                Text("Aún sin fecha de finalización registrada")
                    .bookCaption()
                Button("Marcar como terminado hoy") {
                    data.markCompletedToday()
                }
            }
        }
    }

    private func formatted(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
#endif