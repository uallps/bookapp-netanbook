import Foundation
import SwiftUI
import XCTest
@testable import Netanbook

/// Pruebas del sistema de plugins: registro, avisos al borrar y cambiar un libro
/// (observador), filtros del listado y vistas de cada hueco.
/// Cada prueba usa su propio `PluginRegistry`, no el de la app.
/// Los métodos son `async` porque XCTest en Windows no ejecuta los métodos
/// síncronos de una clase `@MainActor`.
@MainActor
final class PluginRegistryTests: XCTestCase {
    func testRegistrarDosVecesElMismoPluginNoLoDuplica() async {
        let registry = PluginRegistry()
        let plugin = SpyDataPlugin()

        registry.register(plugin)
        registry.register(plugin)

        XCTAssertEqual(registry.plugins.count, 1)
        XCTAssertTrue(registry.plugin(ofType: SpyDataPlugin.self) === plugin)
        XCTAssertNil(registry.plugin(ofType: SpyViewPlugin.self))
    }

    func testAlBorrarUnLibroSeAvisaAntesYDespues() async {
        let registry = PluginRegistry()
        let plugin = SpyDataPlugin()
        registry.register(plugin)
        let viewModel = BookListViewModel(storageProvider: MockBookStorageProvider(), registry: registry)
        await viewModel.loadBooks()
        let book = viewModel.addBook(title: "Dune")!

        viewModel.removeBook(id: book.id)

        XCTAssertEqual(plugin.willDelete.map(\.id), [book.id])
        XCTAssertEqual(plugin.didDelete, [book.id])
        XCTAssertNil(viewModel.book(id: book.id))
    }

    func testBorrarUnLibroQueNoExisteNoAvisa() async {
        let registry = PluginRegistry()
        let plugin = SpyDataPlugin()
        registry.register(plugin)
        let viewModel = BookListViewModel(storageProvider: MockBookStorageProvider(), registry: registry)
        await viewModel.loadBooks()

        viewModel.removeBook(id: UUID())

        XCTAssertTrue(plugin.willDelete.isEmpty)
        XCTAssertTrue(plugin.didDelete.isEmpty)
    }

    func testAlCambiarElEstadoOEditarSeAvisaConElLibroNuevo() async {
        let registry = PluginRegistry()
        let plugin = SpyDataPlugin()
        registry.register(plugin)
        let viewModel = BookListViewModel(storageProvider: MockBookStorageProvider(), registry: registry)
        await viewModel.loadBooks()
        var book = viewModel.addBook(title: "Dune")!

        viewModel.changeStatus(id: book.id, to: .reading)
        book.title = "Dune (edición de bolsillo)"
        viewModel.updateBook(book)

        XCTAssertEqual(plugin.didUpdate.map(\.status), [.reading, .pending])
        XCTAssertEqual(plugin.didUpdate.last?.title, "Dune (edición de bolsillo)")
    }

    func testUnLibroSeVeSoloSiTodosLosFiltrosLoIncluyen() async {
        let registry = PluginRegistry()
        let dune = Book(title: "Dune")
        let emma = Book(title: "Emma")
        XCTAssertTrue(registry.includes(dune), "Sin filtros se ven todos los libros")

        registry.register(TitleFilterPlugin(name: "Empieza por D o E", allowed: ["D", "E"]))
        registry.register(TitleFilterPlugin(name: "Empieza por D", allowed: ["D"]))

        XCTAssertTrue(registry.includes(dune))
        XCTAssertFalse(registry.includes(emma))
    }

    func testUnPluginApagadoSoloAportaSusAjustes() async {
        let registry = PluginRegistry()
        let on = SpyViewPlugin(name: "Encendido", isEnabled: true)
        let off = SpyViewPlugin(name: "Apagado", isEnabled: false)
        registry.register(on)
        registry.register(off)
        let book = Book(title: "Dune")

        XCTAssertEqual(registry.bookRowViews(for: book).map(\.id), ["Encendido"])
        XCTAssertEqual(registry.settingsViews().map(\.id), ["Encendido", "Apagado"])
    }

    func testLosHuecosQueElPluginNoImplementaNoAparecen() async {
        let registry = PluginRegistry()
        registry.register(SpyViewPlugin(name: "Solo fila", isEnabled: true))
        let book = Book(title: "Dune")
        let library = LibraryContext(books: [book], addBook: { _, _ in nil })

        XCTAssertTrue(registry.libraryHeaderViews(library: library).isEmpty)
        XCTAssertTrue(registry.bookDetailViews(for: book).isEmpty)
        XCTAssertEqual(registry.bookRowViews(for: book).map(\.id), ["Solo fila"])
    }

    func testUnPluginDeDatosSinVistasNoApareceEnLosHuecos() async {
        let registry = PluginRegistry()
        registry.register(SpyDataPlugin())

        XCTAssertTrue(registry.settingsViews().isEmpty)
        XCTAssertTrue(registry.bookRowViews(for: Book(title: "Dune")).isEmpty)
    }

#if Estadisticas
    /// F5 como plugin: solo la cabecera y su ajuste, y la cabecera solo con el
    /// ajuste encendido.
    func testF5AportaLaCabeceraSoloConSuAjusteEncendido() async {
        let defaults = UserDefaults(suiteName: "PluginRegistryTests-\(UUID().uuidString)")!
        let config = AppConfig(defaults: defaults)
        let registry = PluginRegistry()
        registry.register(StatisticsPlugin(config: config))
        let book = Book(title: "Dune")
        let library = LibraryContext(books: [book], addBook: { _, _ in nil })

        XCTAssertTrue(registry.libraryHeaderViews(library: library).isEmpty)
        config.showStatistics = true

        XCTAssertEqual(registry.libraryHeaderViews(library: library).map(\.id), ["F5 · Estadísticas"])
        XCTAssertTrue(registry.bookRowViews(for: book).isEmpty)
        XCTAssertTrue(registry.bookDetailViews(for: book).isEmpty)
        XCTAssertEqual(registry.settingsViews().map(\.id), ["F5 · Estadísticas"])
    }
#endif
}

// MARK: - Plugins de prueba

/// Apunta los avisos que recibe.
private final class SpyDataPlugin: DataPlugin {
    let name = "Espía de datos"
    private(set) var willDelete: [Book] = []
    private(set) var didDelete: [UUID] = []
    private(set) var didUpdate: [Book] = []

    func willDeleteBook(_ book: Book) { willDelete.append(book) }
    func didDeleteBook(id: UUID) { didDelete.append(id) }
    func didUpdateBook(_ book: Book) { didUpdate.append(book) }
}

/// Deja pasar los libros cuyo título empieza por una de las letras.
private final class TitleFilterPlugin: BookFilterPlugin {
    let name: String
    let allowed: [Character]

    init(name: String, allowed: [Character]) {
        self.name = name
        self.allowed = allowed
    }

    func includes(_ book: Book) -> Bool {
        guard let first = book.title.first else { return false }
        return allowed.contains(first)
    }
}

/// Aporta una vista en cada hueco; solo implementa la fila y los ajustes, así
/// que la cabecera y el detalle salen de las implementaciones por defecto.
private final class SpyViewPlugin: ViewPlugin {
    let name: String
    let isEnabled: Bool

    init(name: String, isEnabled: Bool) {
        self.name = name
        self.isEnabled = isEnabled
    }

    func bookRowView(for book: Book) -> some View {
        Text("\(name): \(book.title)")
    }

    func settingsView() -> some View {
        Text("Ajuste de \(name)")
    }
}
