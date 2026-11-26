#if Estadisticas
import Foundation
import XCTest
@testable import Netanbook

/// Pruebas de F5 · Estadísticas: se calculan solo con los libros del Core.
/// Los métodos son `async` porque XCTest en Windows no ejecuta los métodos
/// síncronos de una clase `@MainActor` (falla al convertir el método).
@MainActor
final class LibraryStatisticsTests: XCTestCase {
    func testCuentaLosLibrosDeCadaEstado() async {
        let books = [
            Book(title: "A", status: .pending),
            Book(title: "B", status: .pending),
            Book(title: "C", status: .reading),
            Book(title: "D", status: .finished),
        ]

        let statistics = LibraryStatistics(books: books)

        XCTAssertEqual(statistics.totalBooks, 4)
        XCTAssertEqual(statistics.pendingCount, 2)
        XCTAssertEqual(statistics.readingCount, 1)
        XCTAssertEqual(statistics.finishedCount, 1)
        XCTAssertEqual(statistics.count(for: .pending), 2)
        XCTAssertEqual(statistics.count(for: .reading), 1)
        XCTAssertEqual(statistics.count(for: .finished), 1)
        XCTAssertEqual(statistics.finishedPercentage, 25)
    }

    func testBibliotecaVaciaNoTienePorcentaje() async {
        let statistics = LibraryStatistics(books: [])

        XCTAssertEqual(statistics.totalBooks, 0)
        XCTAssertEqual(statistics.pendingCount, 0)
        XCTAssertNil(statistics.finishedPercentage)
    }

    func testLosLibrosDeEjemplo() async {
        let statistics = LibraryStatistics(books: Book.samples)

        XCTAssertEqual(statistics.totalBooks, 3)
        XCTAssertEqual(statistics.pendingCount, 1)
        XCTAssertEqual(statistics.readingCount, 1)
        XCTAssertEqual(statistics.finishedCount, 1)
        XCTAssertEqual(statistics.finishedPercentage, 33)
    }

    func testCambiaAlCambiarLosLibrosDelListado() async {
        let viewModel = BookListViewModel(storageProvider: MockBookStorageProvider())
        await viewModel.loadBooks()
        let before = LibraryStatistics(books: viewModel.books)

        viewModel.addSampleBook()
        viewModel.changeStatus(id: viewModel.books[0].id, to: .finished)
        let after = LibraryStatistics(books: viewModel.books)

        XCTAssertEqual(after.totalBooks, before.totalBooks + 1)
        XCTAssertEqual(after.pendingCount + after.readingCount + after.finishedCount, after.totalBooks)
        XCTAssertGreaterThanOrEqual(after.finishedCount, 1)
    }
}
#endif
