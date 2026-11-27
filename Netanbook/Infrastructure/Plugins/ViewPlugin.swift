import SwiftUI

/// Plugin que aporta vistas en puntos fijos de la app. El núcleo las muestra sin
/// saber de quién son. Hay cuatro huecos:
///
/// - la **cabecera del listado**, encima de los libros (estadísticas, objetivo
///   anual, filtro por categoría, alta por ISBN…);
/// - la **fila** de un libro;
/// - el **detalle** de un libro;
/// - la pantalla de **Ajustes**.
///
/// Un plugin solo implementa los huecos que usa: los demás quedan vacíos
/// (`EmptyView`) gracias a las implementaciones por defecto de más abajo.
/// Los Ajustes son obligatorios, porque ahí está el interruptor del plugin.
protocol ViewPlugin: FeaturePlugin {
    /// Cada plugin elige el tipo de sus vistas (en un protocolo no vale `some View`).
    associatedtype LibraryContent: View = EmptyView
    associatedtype RowContent: View = EmptyView
    associatedtype DetailContent: View = EmptyView
    associatedtype SettingsContent: View

    /// Si sus vistas de cabecera, fila y detalle se muestran ahora (su ajuste).
    var isEnabled: Bool { get }

    /// Lo que el plugin añade encima de los libros del listado.
    @ViewBuilder func libraryHeaderView(library: LibraryContext) -> LibraryContent
    /// Lo que el plugin añade a la fila de un libro.
    @ViewBuilder func bookRowView(for book: Book) -> RowContent
    /// Lo que el plugin añade al detalle de un libro.
    @ViewBuilder func bookDetailView(for book: Book) -> DetailContent
    /// Sus ajustes, en la pantalla de Ajustes.
    @ViewBuilder func settingsView() -> SettingsContent
}

// MARK: - Huecos vacíos por defecto

extension ViewPlugin where LibraryContent == EmptyView {
    func libraryHeaderView(library: LibraryContext) -> EmptyView { EmptyView() }
}

extension ViewPlugin where RowContent == EmptyView {
    func bookRowView(for book: Book) -> EmptyView { EmptyView() }
}

extension ViewPlugin where DetailContent == EmptyView {
    func bookDetailView(for book: Book) -> EmptyView { EmptyView() }
}

// MARK: - Lo que el núcleo ofrece a la cabecera

/// Lo que el listado pasa a la cabecera de los plugins: los libros y las
/// acciones del Core que un plugin puede necesitar. Son datos y closures, no el
/// ViewModel: el plugin no puede tocar la colección por su cuenta.
struct LibraryContext {
    /// Todos los libros de la biblioteca, sin filtrar.
    let books: [Book]
    /// Da de alta un libro con título y autor. Devuelve su id, o `nil` si el
    /// título no es válido. Lo usan los plugins que añaden libros (O3).
    let addBook: (_ title: String, _ author: String?) -> UUID?
}

/// Una vista aportada por un plugin, lista para un `ForEach`.
struct PluginView: Identifiable {
    /// El nombre del plugin: no hay dos iguales.
    let id: String
    /// Vistas de tipos distintos guardadas con un tipo común (borrado de tipo).
    let view: AnyView
}
