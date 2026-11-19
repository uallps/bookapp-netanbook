import SwiftUI

/// Fila de un libro. No conoce el ViewModel: recibe el libro y las acciones.
struct BookRowView: View {
    let book: Book
    let advanceStatus: () -> Void
    let delete: () -> Void

    var body: some View {
        HStack {
            Button(action: advanceStatus) {
                Image(systemName: icon(for: book.status))
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading) {
                Text(book.title)
                Text("\(book.author ?? "Autor desconocido") · \(book.status.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Button("Eliminar", action: delete)
        }
    }

    private func icon(for status: ReadingStatus) -> String {
        switch status {
        case .pendiente: return "book.closed"
        case .leyendo: return "book"
        case .terminado: return "checkmark.circle.fill"
        }
    }
}
