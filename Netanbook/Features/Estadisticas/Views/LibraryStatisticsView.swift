#if Estadisticas
import SwiftUI

/// Vista de F5 · Estadísticas: una sección al principio del listado con el
/// total de libros y el número de libros en cada estado.
///
/// Recibe las estadísticas ya calculadas: no conoce ningún ViewModel. Tiene
/// siempre el mismo número de líneas, cambie lo que cambie la biblioteca.
struct LibraryStatisticsView: View {
    let statistics: LibraryStatistics

    var body: some View {
        Section(header: Text("Estadísticas")) {
            Text(totalText)
            HStack {
                ForEach(ReadingStatus.allCases, id: \.self) { status in
                    Image(systemName: status.symbolName)
                        .foregroundColor(status.color)
                    Text("\(status.displayName): \(statistics.count(for: status))")
                        .bookCaption()
                }
            }
            Text(finishedText)
                .bookCaption(color: .bookAccent)
        }
    }

    private var totalText: String {
        statistics.totalBooks == 1 ? "1 libro en la biblioteca" : "\(statistics.totalBooks) libros en la biblioteca"
    }

    private var finishedText: String {
        guard let percent = statistics.finishedPercentage else { return "Aún no hay libros" }
        return "Terminados: \(percent) %"
    }
}
#endif
