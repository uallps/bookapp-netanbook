#if Categorias
import Foundation
import XCTest
@testable import Netanbook

/// Pruebas de F3 · Categorías con `MockBookCategoriesStorage`: no se toca ningún fichero.
/// Los métodos son `async` porque XCTest en Windows no ejecuta los métodos
/// síncronos de una clase `@MainActor` (falla al convertir el método).
@MainActor
final class BookCategoriesViewModelTests: XCTestCase {
    private let bookID = UUID()

    func testSinNadaGuardadoEmpiezaConLasDeEjemplo() async {
        // Un almacenamiento que falla al leer equivale a «nunca se ha guardado».
        let viewModel = BookCategoriesViewModel(storage: FailingCategoriesStorage())

        XCTAssertEqual(viewModel.categories.count, BookCategoriesData.samples.categories.count)
        XCTAssertEqual(viewModel.categories(for: Book.SampleID.cienAnos).map(\.name),
                       ["Clásicos", "Novela"])
    }

    func testCrearCategoriaLaGuardaSinEspacios() async {
        let storage = MockBookCategoriesStorage()
        let viewModel = BookCategoriesViewModel(storage: storage)

        let category = viewModel.addCategory(name: "  Ensayo  ")

        XCTAssertEqual(category?.name, "Ensayo")
        XCTAssertEqual(viewModel.sortedCategories().map(\.name), ["Ensayo"])
        XCTAssertEqual(storage.data.categories.map(\.name), ["Ensayo"])
    }

    func testNombreVacioORepetidoNoSeCrea() async {
        let storage = MockBookCategoriesStorage()
        let viewModel = BookCategoriesViewModel(storage: storage)
        viewModel.addCategory(name: "Fantasía")
        let saves = storage.saveCount

        XCTAssertNil(viewModel.addCategory(name: "   "))
        XCTAssertNil(viewModel.addCategory(name: " fantasia "))
        XCTAssertNil(viewModel.addCategory(name: "FANTASÍA"))

        XCTAssertEqual(viewModel.categories.count, 1)
        XCTAssertEqual(storage.saveCount, saves)
    }

    func testCategoriasOrdenadasAlfabeticamente() async {
        let viewModel = BookCategoriesViewModel(storage: MockBookCategoriesStorage())
        viewModel.addCategory(name: "Poesía")
        viewModel.addCategory(name: "ensayo")
        viewModel.addCategory(name: "Ciencia")

        XCTAssertEqual(viewModel.sortedCategories().map(\.name), ["Ciencia", "ensayo", "Poesía"])
    }

    func testAsignarYQuitarCategoria() async {
        let storage = MockBookCategoriesStorage()
        let viewModel = BookCategoriesViewModel(storage: storage)
        let category = viewModel.addCategory(name: "Novela")!

        viewModel.setAssigned(true, bookID: bookID, categoryID: category.id)
        XCTAssertTrue(viewModel.isAssigned(bookID: bookID, categoryID: category.id))
        XCTAssertEqual(viewModel.categories(for: bookID).map(\.name), ["Novela"])
        XCTAssertEqual(storage.data.assignments.count, 1)

        viewModel.setAssigned(false, bookID: bookID, categoryID: category.id)
        XCTAssertFalse(viewModel.isAssigned(bookID: bookID, categoryID: category.id))
        XCTAssertTrue(storage.data.assignments.isEmpty)
    }

    func testAsignarDosVecesOCategoriaInexistenteNoCambiaNada() async {
        let storage = MockBookCategoriesStorage()
        let viewModel = BookCategoriesViewModel(storage: storage)
        let category = viewModel.addCategory(name: "Novela")!
        viewModel.setAssigned(true, bookID: bookID, categoryID: category.id)
        let saves = storage.saveCount

        viewModel.setAssigned(true, bookID: bookID, categoryID: category.id)
        viewModel.setAssigned(false, bookID: UUID(), categoryID: category.id)
        viewModel.setAssigned(true, bookID: bookID, categoryID: UUID())

        XCTAssertEqual(viewModel.assignments.count, 1)
        XCTAssertEqual(storage.saveCount, saves)
    }

    func testRenombrarCategoria() async {
        let storage = MockBookCategoriesStorage()
        let viewModel = BookCategoriesViewModel(storage: storage)
        let novela = viewModel.addCategory(name: "Novela")!
        viewModel.addCategory(name: "Poesía")

        XCTAssertTrue(viewModel.renameCategory(id: novela.id, to: " Novela negra "))
        XCTAssertEqual(viewModel.category(id: novela.id)?.name, "Novela negra")
        // Cambiar solo mayúsculas del propio nombre sí se permite.
        XCTAssertTrue(viewModel.renameCategory(id: novela.id, to: "NOVELA NEGRA"))
        XCTAssertEqual(storage.data.categories.first { $0.id == novela.id }?.name, "NOVELA NEGRA")
    }

    func testRenombrarConNombreVacioRepetidoOInexistenteNoCambiaNada() async {
        let storage = MockBookCategoriesStorage()
        let viewModel = BookCategoriesViewModel(storage: storage)
        let novela = viewModel.addCategory(name: "Novela")!
        viewModel.addCategory(name: "Poesía")
        let saves = storage.saveCount

        XCTAssertFalse(viewModel.renameCategory(id: novela.id, to: "  "))
        XCTAssertFalse(viewModel.renameCategory(id: novela.id, to: "poesia"))
        XCTAssertFalse(viewModel.renameCategory(id: UUID(), to: "Otra"))

        XCTAssertEqual(viewModel.category(id: novela.id)?.name, "Novela")
        XCTAssertEqual(storage.saveCount, saves)
    }

    func testBorrarCategoriaLaQuitaDeTodosLosLibros() async {
        let other = UUID()
        let viewModel = BookCategoriesViewModel(storage: MockBookCategoriesStorage())
        let novela = viewModel.addCategory(name: "Novela")!
        let poesia = viewModel.addCategory(name: "Poesía")!
        viewModel.setAssigned(true, bookID: bookID, categoryID: novela.id)
        viewModel.setAssigned(true, bookID: other, categoryID: novela.id)
        viewModel.setAssigned(true, bookID: other, categoryID: poesia.id)

        viewModel.removeCategory(id: novela.id)

        XCTAssertNil(viewModel.category(id: novela.id))
        XCTAssertTrue(viewModel.categories(for: bookID).isEmpty)
        XCTAssertEqual(viewModel.categories(for: other).map(\.name), ["Poesía"])
    }

    func testFiltrarLibrosPorCategoria() async {
        let other = UUID()
        let viewModel = BookCategoriesViewModel(storage: MockBookCategoriesStorage())
        let novela = viewModel.addCategory(name: "Novela")!
        let poesia = viewModel.addCategory(name: "Poesía")!
        viewModel.setAssigned(true, bookID: bookID, categoryID: novela.id)
        viewModel.setAssigned(true, bookID: other, categoryID: novela.id)
        viewModel.setAssigned(true, bookID: other, categoryID: poesia.id)

        XCTAssertEqual(viewModel.bookIDs(in: novela.id), [bookID, other])
        XCTAssertEqual(viewModel.bookIDs(in: poesia.id), [other])
        XCTAssertTrue(viewModel.bookIDs(in: UUID()).isEmpty)
    }

    func testBorrarLibroQuitaSusAsignacionesPeroNoLasCategorias() async {
        let other = UUID()
        let storage = MockBookCategoriesStorage()
        let viewModel = BookCategoriesViewModel(storage: storage)
        let novela = viewModel.addCategory(name: "Novela")!
        viewModel.setAssigned(true, bookID: bookID, categoryID: novela.id)
        viewModel.setAssigned(true, bookID: other, categoryID: novela.id)

        viewModel.removeAssignments(bookID: bookID)

        XCTAssertTrue(viewModel.categories(for: bookID).isEmpty)
        XCTAssertEqual(viewModel.bookIDs(in: novela.id), [other])
        XCTAssertNotNil(viewModel.category(id: novela.id))
        XCTAssertEqual(storage.data.assignments.count, 1)
    }

    func testBorrarLibroSinCategoriasNoGuarda() async {
        let storage = MockBookCategoriesStorage()
        let viewModel = BookCategoriesViewModel(storage: storage)

        viewModel.removeAssignments(bookID: bookID)

        XCTAssertEqual(storage.saveCount, 0)
    }
}

/// Almacenamiento que no tiene nada guardado: leer siempre falla.
@MainActor
private final class FailingCategoriesStorage: BookCategoriesStorage {
    struct NothingSaved: Error {}

    func loadCategories() throws -> BookCategoriesData { throw NothingSaved() }
    func saveCategories(_ data: BookCategoriesData) throws {}
}
#endif
