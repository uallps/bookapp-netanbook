#if Estadisticas
import SwiftUI

/// Plugin de F5 · Estadísticas.
///
/// Es solo un plugin de vista: no guarda datos (las estadísticas se calculan con
/// los libros del Core), así que no es un `DataPlugin` ni tiene nada que borrar
/// al eliminar un libro. Aporta la sección de la cabecera del listado y su
/// interruptor de Ajustes; la fila y el detalle se quedan vacíos.
final class StatisticsPlugin: ViewPlugin {
    let name = "F5 · Estadísticas"

    private let config: AppConfig

    init(config: AppConfig) {
        self.config = config
    }

    /// El ajuste «Mostrar estadísticas».
    var isEnabled: Bool { config.showStatistics }

    /// Se calcula con todos los libros, sin los filtros de otros plugins.
    func libraryHeaderView(library: LibraryContext) -> some View {
        LibraryStatisticsView(statistics: LibraryStatistics(books: library.books))
    }

    func settingsView() -> some View {
        Toggle("Mostrar estadísticas", isOn: Binding(
            get: { self.config.showStatistics },
            set: { self.config.showStatistics = $0 }
        ))
    }
}
#endif
