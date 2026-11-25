#if Notas
import Foundation
import XCTest
@testable import Netanbook

/// Pruebas de F2 · Notas y citas con `MockBookNotesStorage`: no se toca ningún fichero.
/// Los métodos son `async` porque XCTest en Windows no ejecuta los métodos
/// síncronos de una clase `@MainActor` (falla al convertir el método).
@MainActor
final class BookNotesViewModelTests: XCTestCase {
    private let bookID = UUID()

    func testAnadirNotaLaGuarda() async {
        let storage = MockBookNotesStorage()
        let viewModel = BookNotesViewModel(storage: storage)

        XCTAssertTrue(viewModel.addNote(bookID: bookID, kind: .quote, text: "  Hola  ", page: 12))

        let note = viewModel.notes(for: bookID).first
        XCTAssertEqual(note?.text, "Hola")
        XCTAssertEqual(note?.kind, .quote)
        XCTAssertEqual(note?.page, 12)
        XCTAssertEqual(storage.notes.count, 1)
    }

    func testTextoVacioNoSeAnade() async {
        let storage = MockBookNotesStorage()
        let viewModel = BookNotesViewModel(storage: storage)

        XCTAssertFalse(viewModel.addNote(bookID: bookID, kind: .note, text: "   "))

        XCTAssertTrue(viewModel.notes(for: bookID).isEmpty)
        XCTAssertEqual(storage.saveCount, 0)
    }

    func testPaginaNoValidaSeGuardaSinPagina() async {
        let viewModel = BookNotesViewModel(storage: MockBookNotesStorage())

        viewModel.addNote(bookID: bookID, kind: .quote, text: "Cita", page: -3)
        viewModel.addNote(bookID: bookID, kind: .quote, text: "Otra", page: 0)

        XCTAssertEqual(viewModel.notes(for: bookID).count, 2)
        XCTAssertTrue(viewModel.notes(for: bookID).allSatisfy { $0.page == nil })
    }

    func testEditarCambiaTipoTextoYPagina() async {
        let storage = MockBookNotesStorage()
        let viewModel = BookNotesViewModel(storage: storage)
        viewModel.addNote(bookID: bookID, kind: .note, text: "Borrador", page: 3)
        let id = viewModel.notes(for: bookID)[0].id

        XCTAssertTrue(viewModel.updateNote(id: id, kind: .quote, text: " Definitiva ", page: 40))

        let note = viewModel.notes(for: bookID)[0]
        XCTAssertEqual(note.id, id)
        XCTAssertEqual(note.kind, .quote)
        XCTAssertEqual(note.text, "Definitiva")
        XCTAssertEqual(note.page, 40)
        XCTAssertEqual(storage.notes.first?.text, "Definitiva")
    }

    func testEditarConTextoVacioOAnotacionInexistenteNoCambiaNada() async {
        let storage = MockBookNotesStorage()
        let viewModel = BookNotesViewModel(storage: storage)
        viewModel.addNote(bookID: bookID, kind: .note, text: "Original")
        let id = viewModel.notes(for: bookID)[0].id
        let saves = storage.saveCount

        XCTAssertFalse(viewModel.updateNote(id: id, kind: .quote, text: "  ", page: nil))
        XCTAssertFalse(viewModel.updateNote(id: UUID(), kind: .quote, text: "Otra", page: nil))

        XCTAssertEqual(viewModel.notes(for: bookID).map(\.text), ["Original"])
        XCTAssertEqual(viewModel.notes(for: bookID)[0].kind, .note)
        XCTAssertEqual(storage.saveCount, saves)
    }

    func testBorrarNotaYBorrarLasDeUnLibro() async {
        let other = UUID()
        let viewModel = BookNotesViewModel(storage: MockBookNotesStorage())
        viewModel.addNote(bookID: bookID, kind: .note, text: "A")
        viewModel.addNote(bookID: bookID, kind: .note, text: "B")
        viewModel.addNote(bookID: other, kind: .note, text: "C")

        viewModel.removeNote(id: viewModel.notes(for: bookID)[0].id)
        XCTAssertEqual(viewModel.notes(for: bookID).count, 1)

        viewModel.removeNotes(bookID: bookID)
        XCTAssertTrue(viewModel.notes(for: bookID).isEmpty)
        XCTAssertEqual(viewModel.notes(for: other).count, 1)
    }

    func testBorrarLasDeUnLibroSinNotasNoGuarda() async {
        let storage = MockBookNotesStorage()
        let viewModel = BookNotesViewModel(storage: storage)

        viewModel.removeNotes(bookID: bookID)

        XCTAssertEqual(storage.saveCount, 0)
    }
}
#endif
