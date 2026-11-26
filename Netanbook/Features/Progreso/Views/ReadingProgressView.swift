#if Progreso
import SwiftUI

/// Vista de F1 · Progreso para un libro en la fila del listado: barra, páginas,
/// porcentaje y un botón para avanzar. Como la fila, no conoce ningún ViewModel.
struct ReadingProgressView: View {
    let progress: ReadingProgress?
    let advance: () -> Void

    var body: some View {
        HStack {
            if let fraction = progress?.fractionRead {
                ProgressView(value: fraction)
                    .frame(width: 120)
            }
            Text(Self.summary(for: progress))
                .bookCaption()
            Button("+10 páginas", action: advance)
        }
    }

    /// Texto del progreso: el porcentaje solo aparece si hay un total válido.
    /// Lo comparten la fila y la sección del detalle.
    static func summary(for progress: ReadingProgress?) -> String {
        guard let progress else { return "Sin progreso registrado" }
        guard let total = progress.totalPages, let percent = progress.percentRead else {
            return "Página \(progress.currentPage)"
        }
        return "Página \(progress.currentPage) de \(total) · \(percent) %"
    }
}
#endif
