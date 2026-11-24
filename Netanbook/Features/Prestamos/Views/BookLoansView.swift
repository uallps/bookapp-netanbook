#if Prestamos
import Foundation
import SwiftUI

/// Lo que el detalle de un libro necesita de O2, sin conocer su ViewModel: cómo
/// leer el préstamo abierto y el historial, y las acciones, como closures. Lo
/// crea el listado, igual que el enlace `book` del detalle.
struct LoansForBook {
    let openLoan: () -> BookLoan?
    let history: () -> [BookLoan]
    let lend: (String, Int?) -> Bool
    let markReturned: (UUID) -> Void
}

/// Vista de O2 · Préstamos para un libro: a quién está prestado y hasta cuándo
/// (con un botón para devolverlo) o que está en casa; el formulario para
/// prestarlo, que solo funciona si está en casa; y el historial. No conoce
/// ningún ViewModel: lee los préstamos con closures en su `body`, así que se
/// vuelve a dibujar sola cuando cambian.
///
/// Como en F2, la sección tiene siempre el mismo alto (ver BookNotesView).
struct BookLoansView: View {
    let data: LoansForBook

    @State private var borrower = ""
    @State private var daysText = ""
    /// Aviso si no se ha podido prestar (sin nombre o días no válidos).
    @State private var warning: String?

    var body: some View {
        let openLoan = data.openLoan()
        let history = data.history()
        Section(header: Text("Préstamo")) {
            HStack {
                if let openLoan {
                    Text(summary(of: openLoan))
                    Button("Marcar como devuelto") { data.markReturned(openLoan.id) }
                } else {
                    Text("Este libro está en casa")
                }
            }
            .frame(height: 36)
            TextField("¿A quién se lo prestas?", text: $borrower)
            HStack {
                TextField("Días de préstamo (opcional)", text: $daysText)
                Button("Prestar", action: lend)
                    .disabled(openLoan != nil)
            }
            Text(warning ?? " ")
                .bookCaption()
            ScrollView {
                VStack(alignment: .leading) {
                    if history.isEmpty {
                        Text("Sin préstamos anteriores")
                            .bookCaption()
                    }
                    ForEach(history) { loan in
                        Text(historyLine(of: loan))
                            .bookCaption()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 60)
        }
    }

    /// Presta el libro. Si algo no es válido, avisa y no borra lo escrito.
    private func lend() {
        let daysInput = daysText.trimmingCharacters(in: .whitespaces)
        let days = Int(daysInput)
        if !daysInput.isEmpty && (days ?? 0) <= 0 {
            warning = "Los días tienen que ser un número mayor que 0"
            return
        }
        if data.lend(borrower, days) {
            borrower = ""
            daysText = ""
            warning = nil
        } else {
            warning = "Escribe a quién se lo prestas"
        }
    }

    /// Línea del préstamo abierto: persona, fecha de salida y vencimiento.
    private func summary(of loan: BookLoan) -> String {
        var text = "Prestado a \(loan.borrowerName) el \(format(loan.loanDate))"
        if let due = loan.dueDate {
            text += " · devolver el \(format(due))"
            if loan.isOverdue() { text += " (¡vencido!)" }
        }
        return text
    }

    /// Línea de un préstamo devuelto.
    private func historyLine(of loan: BookLoan) -> String {
        let returned = loan.returnedDate.map { format($0) } ?? "—"
        return "Devuelto · \(loan.borrowerName): \(format(loan.loanDate)) → \(returned)"
    }

    /// Un solo formateador para todas las fechas (crear uno es costoso).
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    private func format(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }
}
#endif
