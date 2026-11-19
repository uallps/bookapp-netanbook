#if Progreso
import SwiftUI

/// F1 · Progreso: página actual, total y porcentaje, con botones para avanzar
/// o retroceder. No conoce el ViewModel: recibe los datos y la acción.
struct BookProgressView: View {
    let progress: ReadingProgress
    let changePage: (Int) -> Void

    var body: some View {
        HStack {
            Text("Pág. \(progress.currentPage) de \(progress.totalPages) · \(progress.percentage ?? 0) %")
                .font(.caption)
                .foregroundColor(.green)
            Button("−10") { changePage(-10) }
            Button("+10") { changePage(10) }
        }
    }
}
#endif
