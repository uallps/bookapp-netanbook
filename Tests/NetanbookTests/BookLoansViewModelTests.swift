#if Prestamos
import Foundation
import XCTest
@testable import Netanbook

/// Pruebas de O2 · Préstamos con `MockBookLoansStorage`: no se toca ningún fichero.
/// Los métodos son `async` por la misma razón que en las pruebas de F2.
@MainActor
final class BookLoansViewModelTests: XCTestCase {
    private let bookID = UUID()

    func testPrestarLoGuardaYLoDejaAbierto() async {
        let storage = MockBookLoansStorage()
        let viewModel = BookLoansViewModel(storage: storage)
        let now = Date()

        XCTAssertTrue(viewModel.lend(bookID: bookID, to: "  Ana ", days: 7, now: now))

        let loan = viewModel.openLoan(for: bookID)
        XCTAssertEqual(loan?.borrowerName, "Ana")
        XCTAssertEqual(loan?.loanDate, now)
        XCTAssertEqual(loan?.dueDate, Calendar.current.date(byAdding: .day, value: 7, to: now))
        XCTAssertEqual(storage.loans.count, 1)
    }

    func testNombreVacioNoPresta() async {
        let storage = MockBookLoansStorage()
        let viewModel = BookLoansViewModel(storage: storage)

        XCTAssertFalse(viewModel.lend(bookID: bookID, to: "   "))

        XCTAssertNil(viewModel.openLoan(for: bookID))
        XCTAssertEqual(storage.saveCount, 0)
    }

    func testDiasNoValidosPrestaSinFechaPrevista() async {
        let viewModel = BookLoansViewModel(storage: MockBookLoansStorage())

        XCTAssertTrue(viewModel.lend(bookID: bookID, to: "Ana", days: 0))

        XCTAssertNotNil(viewModel.openLoan(for: bookID))
        XCTAssertNil(viewModel.openLoan(for: bookID)?.dueDate)
    }

    func testNoSePuedePrestarDosVecesUnLibroAbierto() async {
        let viewModel = BookLoansViewModel(storage: MockBookLoansStorage())
        viewModel.lend(bookID: bookID, to: "Ana")

        XCTAssertFalse(viewModel.lend(bookID: bookID, to: "Luis"))

        XCTAssertEqual(viewModel.openLoan(for: bookID)?.borrowerName, "Ana")
        XCTAssertEqual(viewModel.loans.count, 1)
    }

    func testDevolverCierraElPrestamoYPermitePrestarOtraVez() async {
        let viewModel = BookLoansViewModel(storage: MockBookLoansStorage())
        viewModel.lend(bookID: bookID, to: "Ana")
        let id = viewModel.openLoan(for: bookID)!.id

        XCTAssertTrue(viewModel.markReturned(id: id))
        XCTAssertFalse(viewModel.markReturned(id: id))

        XCTAssertNil(viewModel.openLoan(for: bookID))
        XCTAssertEqual(viewModel.history(for: bookID).map(\.borrowerName), ["Ana"])
        XCTAssertTrue(viewModel.lend(bookID: bookID, to: "Luis"))
        XCTAssertEqual(viewModel.openLoan(for: bookID)?.borrowerName, "Luis")
    }

    func testVencidoSoloDesdeElDiaSiguienteAlPrevisto() async {
        let calendar = Calendar.current
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        let afternoon = noon.addingTimeInterval(3 * 3600)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: noon)!
        let loanDate = calendar.date(byAdding: .day, value: -10, to: noon)!
        let late = BookLoan(bookID: bookID, borrowerName: "Ana", loanDate: loanDate, dueDate: yesterday)
        let dueToday = BookLoan(bookID: bookID, borrowerName: "Ana", loanDate: loanDate, dueDate: noon)
        var returned = late
        returned.returnedDate = afternoon

        XCTAssertTrue(late.isOverdue(at: afternoon))
        XCTAssertFalse(dueToday.isOverdue(at: afternoon))
        XCTAssertFalse(returned.isOverdue(at: afternoon))
        XCTAssertFalse(BookLoan(bookID: bookID, borrowerName: "Ana", loanDate: loanDate).isOverdue(at: afternoon))
    }

    func testBorrarLosPrestamosDeUnLibro() async {
        let other = UUID()
        let viewModel = BookLoansViewModel(storage: MockBookLoansStorage())
        viewModel.lend(bookID: bookID, to: "Ana")
        viewModel.lend(bookID: other, to: "Luis")

        viewModel.removeLoans(bookID: bookID)

        XCTAssertNil(viewModel.openLoan(for: bookID))
        XCTAssertNotNil(viewModel.openLoan(for: other))
    }

    func testBorrarLosDeUnLibroSinPrestamosNoGuarda() async {
        let storage = MockBookLoansStorage()
        let viewModel = BookLoansViewModel(storage: storage)

        viewModel.removeLoans(bookID: bookID)

        XCTAssertEqual(storage.saveCount, 0)
    }
}
#endif
