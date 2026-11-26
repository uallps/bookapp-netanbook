#if Progreso
import Foundation
import SwiftUI

/// Lo que el detalle de un libro necesita de F1, sin conocer su ViewModel: cómo
/// leer el progreso del libro y cómo guardarlo, como closures. Lo crea el
/// listado, igual que el enlace `book` del detalle.
struct ProgressForBook {
    let progress: () -> ReadingProgress?
    /// Guarda la página actual y el total (opcional). Devuelve `false` si no es válido.
    let save: (Int, Int?) -> Bool
}

/// Sección de F1 · Progreso en el detalle de un libro: muestra el progreso y
/// permite escribir la página exacta por la que se va y el total de páginas.
///
/// Un campo vacío conserva el valor guardado; así se puede cambiar solo la
/// página o solo el total. La sección tiene siempre el mismo alto (la línea del
/// aviso está siempre, vacía si no hay aviso): en Windows, SwiftOpenUI no
/// recoloca las secciones de debajo cuando una crece.
struct ReadingProgressEditView: View {
    let data: ProgressForBook

    @State private var currentText = ""
    @State private var totalText = ""
    /// Aviso si no se ha podido guardar, o confirmación si se ha guardado.
    @State private var message: String?

    var body: some View {
        let progress = data.progress()
        Section(header: Text("Progreso de lectura")) {
            HStack {
                if let fraction = progress?.fractionRead {
                    ProgressView(value: fraction)
                        .frame(width: 120)
                }
                Text(ReadingProgressView.summary(for: progress))
                    .bookCaption()
            }
            HStack {
                TextField(currentPlaceholder(progress), text: $currentText)
                TextField(totalPlaceholder(progress), text: $totalText)
                Button("Guardar progreso", action: save)
            }
            Text(message ?? " ")
                .bookCaption()
        }
    }

    /// Valida lo escrito y guarda. Si algo no es válido, avisa y no borra lo escrito.
    private func save() {
        let progress = data.progress()
        let currentInput = currentText.trimmingCharacters(in: .whitespaces)
        let totalInput = totalText.trimmingCharacters(in: .whitespaces)

        let current: Int
        if currentInput.isEmpty {
            current = progress?.currentPage ?? 0
        } else if let value = Int(currentInput), value >= 0 {
            current = value
        } else {
            message = "La página actual tiene que ser un número (0 o más)"
            return
        }

        let total: Int?
        if totalInput.isEmpty {
            total = progress?.totalPages
        } else if let value = Int(totalInput), value > 0 {
            total = value
        } else {
            message = "El total de páginas tiene que ser un número mayor que 0"
            return
        }

        if let total, current > total {
            message = "La página actual no puede pasar del total (\(total))"
            return
        }

        if data.save(current, total) {
            currentText = ""
            totalText = ""
            message = "Progreso guardado"
        } else {
            message = "No se ha podido guardar el progreso"
        }
    }

    private func currentPlaceholder(_ progress: ReadingProgress?) -> String {
        "Página actual (ahora \(progress?.currentPage ?? 0))"
    }

    private func totalPlaceholder(_ progress: ReadingProgress?) -> String {
        if let total = progress?.totalPages {
            return "Total de páginas (ahora \(total))"
        }
        return "Total de páginas"
    }
}
#endif
