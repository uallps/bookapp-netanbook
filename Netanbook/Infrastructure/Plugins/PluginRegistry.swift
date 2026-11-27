import SwiftUI

/// Registro de plugins. El núcleo habla con el registro, nunca con un plugin
/// concreto: así puede mostrar sus vistas y avisarles de los cambios sin
/// nombrarlos.
///
/// Los plugins se crean y se registran al arrancar la app (`NetanbookApp`), cada
/// uno dentro de su `#if <Trait>`: es el único sitio del código que los nombra.
final class PluginRegistry {
    /// Un único registro para toda la app (patrón Singleton).
    static let shared = PluginRegistry()

    /// Los plugins registrados, en el orden en que se registraron. Ese orden es
    /// el de sus vistas en cada hueco.
    private(set) var plugins: [FeaturePlugin] = []

    /// La app usa `shared`. Las pruebas crean un registro propio para no
    /// mezclar sus plugins con los de otras pruebas.
    init() {}

    /// Añade un plugin. Registrar dos veces el mismo no hace nada.
    func register(_ plugin: FeaturePlugin) {
        guard !plugins.contains(where: { $0 === plugin }) else { return }
        plugins.append(plugin)
        print("Plugin registrado: \(plugin.name)")
    }

    /// El plugin registrado de un tipo concreto, si lo hay. Lo usa la app para
    /// pasar a un plugin otro del que depende (por ejemplo, O1 necesita F1).
    func plugin<P: FeaturePlugin>(ofType type: P.Type) -> P? {
        plugins.lazy.compactMap { $0 as? P }.first
    }

    // MARK: - Avisos a los plugins de datos (patrón observador)

    private var dataPlugins: [DataPlugin] {
        plugins.compactMap { $0 as? DataPlugin }
    }

    /// Avisa de que un libro se va a borrar: cada plugin borra sus datos.
    func notifyBookWillBeDeleted(_ book: Book) {
        for plugin in dataPlugins {
            plugin.willDeleteBook(book)
        }
    }

    /// Avisa de que un libro se ha borrado.
    func notifyBookDidDelete(id: UUID) {
        for plugin in dataPlugins {
            plugin.didDeleteBook(id: id)
        }
    }

    /// Avisa de que un libro ha cambiado (estado, título…).
    func notifyBookDidUpdate(_ book: Book) {
        for plugin in dataPlugins {
            plugin.didUpdateBook(book)
        }
    }

    // MARK: - Filtros del listado

    /// Si el libro se muestra: todos los filtros lo incluyen (sin filtros, sí).
    func includes(_ book: Book) -> Bool {
        plugins.compactMap { $0 as? BookFilterPlugin }.allSatisfy { $0.includes(book) }
    }

    // MARK: - Vistas de los plugins

    private var viewPlugins: [any ViewPlugin] {
        plugins.compactMap { $0 as? any ViewPlugin }
    }

    /// Los plugins de vista con su ajuste encendido.
    private var enabledViewPlugins: [any ViewPlugin] {
        viewPlugins.filter(\.isEnabled)
    }

    /// Lo que añaden encima de los libros los plugins activos, en orden de registro.
    /// Los que no aportan nada en ese hueco (`EmptyView`) no aparecen: así no
    /// dejan una fila vacía en la lista.
    func libraryHeaderViews(library: LibraryContext) -> [PluginView] {
        enabledViewPlugins.compactMap { Self.headerView(of: $0, library: library) }
    }

    /// Lo que añaden a la fila de un libro los plugins activos.
    func bookRowViews(for book: Book) -> [PluginView] {
        enabledViewPlugins.compactMap { Self.rowView(of: $0, for: book) }
    }

    /// Lo que añaden al detalle de un libro los plugins activos.
    func bookDetailViews(for book: Book) -> [PluginView] {
        enabledViewPlugins.compactMap { Self.detailView(of: $0, for: book) }
    }

    // Funciones genéricas: con `P` concreto se puede preguntar por el tipo de
    // cada hueco (`P.RowContent`…), cosa que no se puede con `any ViewPlugin`.
    // Swift «abre» el `any ViewPlugin` al llamarlas.

    private static func headerView<P: ViewPlugin>(of plugin: P, library: LibraryContext) -> PluginView? {
        guard P.LibraryContent.self != EmptyView.self else { return nil }
        return PluginView(id: plugin.name, view: AnyView(plugin.libraryHeaderView(library: library)))
    }

    private static func rowView<P: ViewPlugin>(of plugin: P, for book: Book) -> PluginView? {
        guard P.RowContent.self != EmptyView.self else { return nil }
        return PluginView(id: plugin.name, view: AnyView(plugin.bookRowView(for: book)))
    }

    private static func detailView<P: ViewPlugin>(of plugin: P, for book: Book) -> PluginView? {
        guard P.DetailContent.self != EmptyView.self else { return nil }
        return PluginView(id: plugin.name, view: AnyView(plugin.bookDetailView(for: book)))
    }

    /// Los ajustes de todos los plugins, también de los apagados: así se pueden
    /// volver a encender.
    func settingsViews() -> [PluginView] {
        viewPlugins.map { plugin in
            PluginView(id: plugin.name, view: AnyView(plugin.settingsView()))
        }
    }
}
