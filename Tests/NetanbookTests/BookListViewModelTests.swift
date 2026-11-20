import Foundation
import XCTest
@testable import Netanbook

/// Pruebas del ViewModel del listado con `MockBookStorageProvider`: el ViewModel
/// solo conoce el protocolo, así que aquí no se toca ningún fichero.
@MainActor
final class BookListViewModelTests: XCTestCase {
    func testCargaLosLibrosDelAlmacenamiento() async {
        let storage = MockBookStorageProvider()
        let viewModel = BookListViewModel(storageProvider: storage)

        await viewModel.loadBooks()

        XCTAssertEqual(viewModel.books.map(\.title), ["Libro de prueba 1", "Libro de prueba 2"])
    }

    func testCadaCambioSeGuarda() async {
        let storage = MockBookStorageProvider()
        let viewModel = BookListViewModel(storageProvider: storage)
        await viewModel.loadBooks()
        let id = viewModel.books[0].id

        viewModel.advanceStatus(id: id)
        viewModel.addSampleBook()
        await viewModel.waitForPendingSave()

        XCTAssertEqual(storage.storedBooks.count, 3)
        XCTAssertEqual(storage.storedBooks[0].status, .reading)
    }

    func testEditarEnElDetalleYBorrarTambienSeGuardan() async {
        let storage = MockBookStorageProvider()
        let viewModel = BookListViewModel(storageProvider: storage)
        await viewModel.loadBooks()

        var edited = viewModel.books[0]
        edited.title = "Título editado"
        viewModel.updateBook(edited)
        viewModel.removeBook(id: viewModel.books[1].id)
        await viewModel.waitForPendingSave()

        XCTAssertEqual(storage.storedBooks.map(\.title), ["Título editado"])
    }

    func testUnTituloVacioNoSeGuarda() async {
        let storage = MockBookStorageProvider()
        let viewModel = BookListViewModel(storageProvider: storage)
        await viewModel.loadBooks()

        var edited = viewModel.books[0]
        edited.title = "   "
        viewModel.updateBook(edited)
        await viewModel.waitForPendingSave()

        XCTAssertEqual(viewModel.books[0].title, "Libro de prueba 1")
    }

    func testElLibroSeCodificaYDecodificaEnJSON() throws {
        let book = Book(title: "El nombre del viento", author: "Patrick Rothfuss", status: .reading)

        let data = try JSONEncoder().encode([book])
        let decoded = try JSONDecoder().decode([Book].self, from: data)

        XCTAssertEqual(decoded.first?.id, book.id)
        XCTAssertEqual(decoded.first?.title, book.title)
        XCTAssertEqual(decoded.first?.status, .reading)
    }
}

#if Notas
/// Pruebas de F2 · Notas y citas con `MockBookNotesStorage`: no se toca ningún fichero.
@MainActor
final class BookNotesViewModelTests: XCTestCase {
    private let bookID = UUID()

    func testAnadirNotaLaGuarda() async {
        let storage = MockBookNotesStorage()
        let viewModel = BookNotesViewModel(storage: storage)

        XCTAssertTrue(viewModel.addNote(bookID: bookID, kind: .quote, text: "  Hola  ", page: 12))

        XCTAssertEqual(viewModel.notes(for: bookID).map(\.text), ["Hola"])
        XCTAssertEqual(viewModel.notes(for: bookID).first?.page, 12)
        XCTAssertEqual(storage.notes.count, 1)
    }

    func testTextoVacioNoSeAnade() async {
        let storage = MockBookNotesStorage()
        let viewModel = BookNotesViewModel(storage: storage)

        XCTAssertFalse(viewModel.addNote(bookID: bookID, kind: .note, text: "   "))

        XCTAssertTrue(viewModel.notes(for: bookID).isEmpty)
    }

    func testPaginaInvalidaSeIgnora() async {
        let viewModel = BookNotesViewModel(storage: MockBookNotesStorage())

        viewModel.addNote(bookID: bookID, kind: .quote, text: "Cita", page: -3)

        XCTAssertNil(viewModel.notes(for: bookID).first?.page)
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
}
#endif
