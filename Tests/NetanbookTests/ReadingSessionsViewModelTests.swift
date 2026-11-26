#if SesionesLectura
import Foundation
import XCTest
@testable import Netanbook

/// Pruebas de O1 · Sesiones de lectura con `MockReadingSessionsStorage` y un
/// reloj falso: no se toca ningún fichero ni se espera tiempo real.
/// Los métodos son `async` porque XCTest en Windows no ejecuta los métodos
/// síncronos de una clase `@MainActor` (falla al convertir el método).
@MainActor
final class ReadingSessionsViewModelTests: XCTestCase {
    private let bookID = UUID()
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    /// ViewModel con un reloj que se puede adelantar a mano.
    private func makeViewModel(
        storage: MockReadingSessionsStorage = MockReadingSessionsStorage()
    ) -> (ReadingSessionsViewModel, Clock) {
        let clock = Clock(now: start)
        let viewModel = ReadingSessionsViewModel(storage: storage, now: { clock.now })
        return (viewModel, clock)
    }

    final class Clock {
        var now: Date
        init(now: Date) { self.now = now }
    }

    func testIniciarYTerminarGuardaDuracionYPaginas() async {
        let storage = MockReadingSessionsStorage()
        let (viewModel, clock) = makeViewModel(storage: storage)

        XCTAssertTrue(viewModel.start(bookID: bookID, fromPage: 10))
        XCTAssertEqual(viewModel.activeSession(for: bookID)?.startPage, 10)

        clock.now = start.addingTimeInterval(25 * 60)
        let finished = viewModel.stop(bookID: bookID, atPage: 40)

        XCTAssertEqual(finished?.duration, 25 * 60)
        XCTAssertEqual(finished?.pagesRead, 30)
        XCTAssertNil(viewModel.activeSession(for: bookID))
        XCTAssertEqual(viewModel.history(for: bookID).count, 1)
        XCTAssertEqual(storage.sessions.first?.endPage, 40)
    }

    func testSoloUnaSesionEnCursoPorLibro() async {
        let (viewModel, _) = makeViewModel()

        XCTAssertTrue(viewModel.start(bookID: bookID, fromPage: 0))
        XCTAssertFalse(viewModel.start(bookID: bookID, fromPage: 5))
        // Otro libro sí puede tener su propia sesión.
        XCTAssertTrue(viewModel.start(bookID: UUID(), fromPage: 0))

        XCTAssertEqual(viewModel.sessions.filter { $0.bookID == bookID }.count, 1)
    }

    func testNoSeIniciaDesdeUnaPaginaNegativa() async {
        let storage = MockReadingSessionsStorage()
        let (viewModel, _) = makeViewModel(storage: storage)

        XCTAssertFalse(viewModel.start(bookID: bookID, fromPage: -1))

        XCTAssertNil(viewModel.activeSession(for: bookID))
        XCTAssertEqual(storage.saveCount, 0)
    }

    func testLaPaginaFinalNoPuedeSerMenorQueLaInicial() async {
        let (viewModel, _) = makeViewModel()
        viewModel.start(bookID: bookID, fromPage: 50)

        XCTAssertNil(viewModel.stop(bookID: bookID, atPage: 49))

        XCTAssertNotNil(viewModel.activeSession(for: bookID))
        XCTAssertTrue(viewModel.history(for: bookID).isEmpty)
    }

    func testTerminarSinSesionEnCursoNoHaceNada() async {
        let storage = MockReadingSessionsStorage()
        let (viewModel, _) = makeViewModel(storage: storage)

        XCTAssertNil(viewModel.stop(bookID: bookID, atPage: 10))

        XCTAssertEqual(storage.saveCount, 0)
    }

    func testDescartarQuitaLaSesionEnCursoSinHistorial() async {
        let (viewModel, _) = makeViewModel()
        viewModel.start(bookID: bookID, fromPage: 0)

        viewModel.cancel(bookID: bookID)

        XCTAssertNil(viewModel.activeSession(for: bookID))
        XCTAssertTrue(viewModel.history(for: bookID).isEmpty)
    }

    func testHistorialDeMasRecienteAMasAntiguaYTotales() async {
        let (viewModel, clock) = makeViewModel()
        viewModel.start(bookID: bookID, fromPage: 0)
        clock.now = start.addingTimeInterval(10 * 60)
        viewModel.stop(bookID: bookID, atPage: 20)
        clock.now = start.addingTimeInterval(60 * 60)
        viewModel.start(bookID: bookID, fromPage: 20)
        clock.now = start.addingTimeInterval(90 * 60)
        viewModel.stop(bookID: bookID, atPage: 35)

        let history = viewModel.history(for: bookID)
        XCTAssertEqual(history.map(\.startPage), [20, 0])
        XCTAssertEqual(viewModel.totalDuration(for: bookID), 40 * 60)
        XCTAssertEqual(viewModel.totalPagesRead(for: bookID), 35)
    }

    func testBorrarUnaSesionYLasDeUnLibro() async {
        let storage = MockReadingSessionsStorage()
        let (viewModel, _) = makeViewModel(storage: storage)
        let otherBook = UUID()
        viewModel.start(bookID: bookID, fromPage: 0)
        viewModel.stop(bookID: bookID, atPage: 5)
        viewModel.start(bookID: otherBook, fromPage: 0)

        viewModel.removeSession(id: viewModel.history(for: bookID)[0].id)
        XCTAssertTrue(viewModel.history(for: bookID).isEmpty)

        let saves = storage.saveCount
        viewModel.removeSessions(bookID: bookID)  // ya no tenía ninguna
        XCTAssertEqual(storage.saveCount, saves)

        viewModel.removeSessions(bookID: otherBook)
        XCTAssertTrue(viewModel.sessions.isEmpty)
        XCTAssertEqual(storage.saveCount, saves + 1)
    }

    func testSeCargaLoGuardado() async {
        let saved = ReadingSession(bookID: bookID, startDate: start, startPage: 3)
        let (viewModel, _) = makeViewModel(storage: MockReadingSessionsStorage(sessions: [saved]))

        XCTAssertEqual(viewModel.activeSession(for: bookID), saved)
    }

    func testTextoDeLaDuracion() async {
        XCTAssertEqual(ReadingSession.durationText(30), "menos de 1 min")
        XCTAssertEqual(ReadingSession.durationText(25 * 60), "25 min")
        XCTAssertEqual(ReadingSession.durationText(60 * 60), "1 h")
        XCTAssertEqual(ReadingSession.durationText(65 * 60), "1 h 5 min")
    }

    /// O1 y F1 juntos, como los une el listado: al terminar la sesión, la
    /// página final pasa a ser la página actual de F1.
    func testTerminarLaSesionActualizaLaPaginaDeF1() async {
        let progress = ReadingProgressViewModel(storage: MockReadingProgressStorage())
        progress.setProgress(bookID: bookID, currentPage: 100, totalPages: 300)
        let (sessions, _) = makeViewModel()

        sessions.start(bookID: bookID, fromPage: progress.progress(for: bookID)!.currentPage)
        if sessions.stop(bookID: bookID, atPage: 130) != nil {
            progress.setCurrentPage(bookID: bookID, page: 130)
        }

        XCTAssertEqual(progress.progress(for: bookID)?.currentPage, 130)
        XCTAssertEqual(progress.progress(for: bookID)?.totalPages, 300)
        XCTAssertEqual(sessions.history(for: bookID).first?.pagesRead, 30)
    }
}
#endif
