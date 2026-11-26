#if Progreso
import Foundation
import XCTest
@testable import Netanbook

/// Pruebas de F1 · Progreso con `MockReadingProgressStorage`: no se toca ningún fichero.
/// Los métodos son `async` porque XCTest en Windows no ejecuta los métodos
/// síncronos de una clase `@MainActor` (falla al convertir el método).
@MainActor
final class ReadingProgressViewModelTests: XCTestCase {
    private let bookID = UUID()

    func testAlmacenamientoVacioNoTieneProgreso() async {
        // El mock devuelve una lista vacía (no un error): no se usan los ejemplos.
        let viewModel = ReadingProgressViewModel(storage: MockReadingProgressStorage(progress: []))
        XCTAssertNil(viewModel.progress(for: Book.SampleID.lazarillo))
    }

    func testRegistrarPaginaYTotalCalculaElPorcentaje() async {
        let storage = MockReadingProgressStorage()
        let viewModel = ReadingProgressViewModel(storage: storage)

        XCTAssertTrue(viewModel.setProgress(bookID: bookID, currentPage: 50, totalPages: 200))

        let progress = viewModel.progress(for: bookID)
        XCTAssertEqual(progress?.currentPage, 50)
        XCTAssertEqual(progress?.totalPages, 200)
        XCTAssertEqual(progress?.percentRead, 25)
        XCTAssertEqual(storage.progress.count, 1)
    }

    func testSinTotalNoHayPorcentaje() async {
        let viewModel = ReadingProgressViewModel(storage: MockReadingProgressStorage())

        XCTAssertTrue(viewModel.setProgress(bookID: bookID, currentPage: 30, totalPages: nil))

        XCTAssertEqual(viewModel.progress(for: bookID)?.currentPage, 30)
        XCTAssertNil(viewModel.progress(for: bookID)?.fractionRead)
        XCTAssertNil(viewModel.progress(for: bookID)?.percentRead)
    }

    func testDatosNoValidosNoCambianNada() async {
        let storage = MockReadingProgressStorage()
        let viewModel = ReadingProgressViewModel(storage: storage)
        viewModel.setProgress(bookID: bookID, currentPage: 10, totalPages: 100)

        XCTAssertFalse(viewModel.setProgress(bookID: bookID, currentPage: -1, totalPages: 100))
        XCTAssertFalse(viewModel.setProgress(bookID: bookID, currentPage: 10, totalPages: 0))
        XCTAssertFalse(viewModel.setProgress(bookID: bookID, currentPage: 150, totalPages: 100))

        XCTAssertEqual(viewModel.progress(for: bookID)?.currentPage, 10)
        XCTAssertEqual(viewModel.progress(for: bookID)?.totalPages, 100)
        XCTAssertEqual(storage.saveCount, 1)
    }

    func testActualizarConLosMismosDatosNoGuarda() async {
        let storage = MockReadingProgressStorage()
        let viewModel = ReadingProgressViewModel(storage: storage)
        viewModel.setProgress(bookID: bookID, currentPage: 10, totalPages: 100)

        XCTAssertTrue(viewModel.setProgress(bookID: bookID, currentPage: 10, totalPages: 100))

        XCTAssertEqual(storage.saveCount, 1)
    }

    func testCambiarSoloLaPaginaConservaElTotal() async {
        let viewModel = ReadingProgressViewModel(storage: MockReadingProgressStorage())
        viewModel.setProgress(bookID: bookID, currentPage: 10, totalPages: 100)

        XCTAssertTrue(viewModel.setCurrentPage(bookID: bookID, page: 60))
        XCTAssertFalse(viewModel.setCurrentPage(bookID: bookID, page: 101))

        XCTAssertEqual(viewModel.progress(for: bookID)?.currentPage, 60)
        XCTAssertEqual(viewModel.progress(for: bookID)?.totalPages, 100)
    }

    func testAvanzarNoPasaDelTotal() async {
        let viewModel = ReadingProgressViewModel(storage: MockReadingProgressStorage())
        viewModel.setProgress(bookID: bookID, currentPage: 95, totalPages: 100)

        viewModel.advance(bookID: bookID)

        XCTAssertEqual(viewModel.progress(for: bookID)?.currentPage, 100)
        XCTAssertEqual(viewModel.progress(for: bookID)?.percentRead, 100)
    }

    func testAvanzarUnLibroSinProgresoLoEmpieza() async {
        let viewModel = ReadingProgressViewModel(storage: MockReadingProgressStorage())

        viewModel.advance(bookID: bookID)

        XCTAssertEqual(viewModel.progress(for: bookID)?.currentPage, 10)
        XCTAssertNil(viewModel.progress(for: bookID)?.totalPages)
    }

    func testBorrarElProgresoDeUnLibroSinProgresoNoGuarda() async {
        let storage = MockReadingProgressStorage()
        let viewModel = ReadingProgressViewModel(storage: storage)
        viewModel.setProgress(bookID: bookID, currentPage: 5, totalPages: nil)

        viewModel.removeProgress(bookID: UUID())
        XCTAssertEqual(storage.saveCount, 1)

        viewModel.removeProgress(bookID: bookID)
        XCTAssertNil(viewModel.progress(for: bookID))
        XCTAssertEqual(storage.saveCount, 2)
    }

    func testSeCargaLoGuardado() async {
        let saved = ReadingProgress(bookID: bookID, totalPages: 300, currentPage: 120)
        let viewModel = ReadingProgressViewModel(storage: MockReadingProgressStorage(progress: [saved]))

        XCTAssertEqual(viewModel.progress(for: bookID), saved)
        XCTAssertEqual(viewModel.progress(for: bookID)?.percentRead, 40)
    }
}
#endif
