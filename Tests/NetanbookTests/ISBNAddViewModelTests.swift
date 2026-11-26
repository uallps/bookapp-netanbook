#if AltaISBN
import Foundation
import XCTest
@testable import Netanbook

/// Pruebas de las reglas del ISBN (O3).
@MainActor
final class ISBNTests: XCTestCase {
    func testISBN13ValidoConGuionesYEspacios() async {
        XCTAssertEqual(ISBN.normalized("978-84-376-0494-7"), "9788437604947")
        XCTAssertEqual(ISBN.normalized(" 978 84 376 0494 7 "), "9788437604947")
        XCTAssertEqual(ISBN.normalized("979-10-90636-07-1"), "9791090636071")
    }

    func testISBN10SePasaAISBN13() async {
        XCTAssertEqual(ISBN.normalized("84-376-0494-X"), "9788437604947")
        // La X final vale 10, en mayúscula o en minúscula.
        XCTAssertEqual(ISBN.normalized("0-8044-2957-X"), "9780804429573")
        XCTAssertEqual(ISBN.normalized("080442957x"), "9780804429573")
    }

    func testISBNNoValidos() async {
        XCTAssertNil(ISBN.normalized(""))
        XCTAssertNil(ISBN.normalized("12345"))
        XCTAssertNil(ISBN.normalized("9788437604946"))   // dígito de control mal
        XCTAssertNil(ISBN.normalized("8437604942"))      // dígito de control mal
        XCTAssertNil(ISBN.normalized("978843760494A"))   // letra en un ISBN-13
        XCTAssertNil(ISBN.normalized("84376X4941"))      // X que no está al final
        XCTAssertNil(ISBN.normalized("1234567890128"))   // no empieza por 978 o 979
    }
}

/// Pruebas de cómo se lee la respuesta de Open Library, sin red.
@MainActor
final class OpenLibraryCatalogTests: XCTestCase {
    func testLeeTituloYAutores() async throws {
        let json = """
        {"ISBN:9788437604947": {"title": " Cien años de soledad ",
          "authors": [{"name": "Gabriel García Márquez", "url": "x"}, {"name": "Otro Autor"}],
          "publishers": [{"name": "Cátedra"}]}}
        """
        let info = try OpenLibraryCatalog.parse(Data(json.utf8), isbn: "9788437604947")

        XCTAssertEqual(info, ISBNBookInfo(isbn: "9788437604947", title: "Cien años de soledad",
                                          author: "Gabriel García Márquez, Otro Autor"))
    }

    func testSinAutoresElAutorEsNil() async throws {
        let json = #"{"ISBN:9788437604947": {"title": "Anónimo"}}"#
        let info = try OpenLibraryCatalog.parse(Data(json.utf8), isbn: "9788437604947")

        XCTAssertEqual(info?.title, "Anónimo")
        XCTAssertNil(info?.author)
    }

    func testRespuestaVaciaEsQueNoLoTiene() async throws {
        XCTAssertNil(try OpenLibraryCatalog.parse(Data("{}".utf8), isbn: "9788437604947"))
    }

    func testRespuestaQueNoEsJSONEsUnError() async {
        XCTAssertThrowsError(try OpenLibraryCatalog.parse(Data("<html>".utf8), isbn: "9788437604947")) {
            XCTAssertEqual($0 as? BookCatalogError, .invalidResponse)
        }
    }
}

/// Pruebas del ViewModel de O3 con `MockBookCatalog` y `MockBookISBNStorage`:
/// no se usa la red ni se toca ningún fichero.
@MainActor
final class ISBNAddViewModelTests: XCTestCase {
    private let cienAnos = ISBNBookInfo(isbn: "9788437604947", title: "Cien años de soledad",
                                        author: "Gabriel García Márquez")

    /// Closure de alta que imita al listado: guarda lo que recibe y devuelve un `id` nuevo.
    private final class FakeLibrary {
        var added: [(id: UUID, title: String, author: String?)] = []
        var ids: Set<UUID> { Set(added.map(\.id)) }

        func add(_ title: String, _ author: String?) -> UUID? {
            let id = UUID()
            added.append((id, title, author))
            return id
        }
    }

    func testISBNNoValidoNoConsultaElCatalogo() async {
        let catalog = MockBookCatalog(books: [cienAnos])
        let viewModel = ISBNAddViewModel(catalog: catalog, storage: MockBookISBNStorage())
        viewModel.isbnText = "978-84-376-0494-6"

        await viewModel.search()

        XCTAssertEqual(viewModel.status, .invalidISBN)
        XCTAssertTrue(catalog.searched.isEmpty)
    }

    func testBuscarRellenaTituloYAutor() async {
        let catalog = MockBookCatalog(books: [cienAnos])
        let viewModel = ISBNAddViewModel(catalog: catalog, storage: MockBookISBNStorage())
        viewModel.isbnText = "84-376-0494-X"   // ISBN-10 del mismo libro

        await viewModel.search()

        XCTAssertEqual(catalog.searched, ["9788437604947"])
        XCTAssertEqual(viewModel.status, .found)
        XCTAssertEqual(viewModel.title, "Cien años de soledad")
        XCTAssertEqual(viewModel.author, "Gabriel García Márquez")
    }

    func testISBNQueNoEstaEnElCatalogo() async {
        let viewModel = ISBNAddViewModel(catalog: MockBookCatalog(), storage: MockBookISBNStorage())
        viewModel.isbnText = "9788437604947"

        await viewModel.search()

        XCTAssertEqual(viewModel.status, .notFound)
        XCTAssertEqual(viewModel.title, "")
    }

    func testSinConexionAvisaYDejaEscribirAMano() async {
        // Un error cualquiera: URLError está en FoundationNetworking en Linux y Windows.
        struct NoConnection: Error {}
        let catalog = MockBookCatalog(error: NoConnection())
        let viewModel = ISBNAddViewModel(catalog: catalog, storage: MockBookISBNStorage())
        viewModel.isbnText = "9788437604947"

        await viewModel.search()
        XCTAssertEqual(viewModel.status, .failed)

        let library = FakeLibrary()
        viewModel.title = "Escrito a mano"
        XCTAssertTrue(viewModel.addBook(existingBookIDs: library.ids, add: library.add))
        XCTAssertEqual(library.added.map(\.title), ["Escrito a mano"])
    }

    func testAnadirDaDeAltaElLibroYGuardaSuISBN() async {
        let storage = MockBookISBNStorage()
        let viewModel = ISBNAddViewModel(catalog: MockBookCatalog(books: [cienAnos]), storage: storage)
        let library = FakeLibrary()
        viewModel.isbnText = "978-84-376-0494-7"
        await viewModel.search()

        XCTAssertTrue(viewModel.addBook(existingBookIDs: library.ids, add: library.add))

        let added = library.added[0]
        XCTAssertEqual(added.title, "Cien años de soledad")
        XCTAssertEqual(added.author, "Gabriel García Márquez")
        XCTAssertEqual(viewModel.isbn(for: added.id), "9788437604947")
        XCTAssertEqual(storage.records, [BookISBN(bookID: added.id, isbn: "9788437604947")])
        XCTAssertEqual(viewModel.status, .added(title: "Cien años de soledad"))
        // El formulario queda vacío para el siguiente libro.
        XCTAssertEqual(viewModel.isbnText, "")
        XCTAssertEqual(viewModel.title, "")
        XCTAssertEqual(viewModel.author, "")
    }

    func testNoSeAnadeSinTituloNiConISBNNoValido() async {
        let storage = MockBookISBNStorage()
        let viewModel = ISBNAddViewModel(catalog: MockBookCatalog(), storage: storage)
        let library = FakeLibrary()

        viewModel.isbnText = "9788437604947"
        viewModel.title = "   "
        XCTAssertFalse(viewModel.addBook(existingBookIDs: library.ids, add: library.add))
        XCTAssertEqual(viewModel.status, .missingTitle)

        viewModel.isbnText = "123"
        viewModel.title = "Título"
        XCTAssertFalse(viewModel.addBook(existingBookIDs: library.ids, add: library.add))
        XCTAssertEqual(viewModel.status, .invalidISBN)

        XCTAssertTrue(library.added.isEmpty)
        XCTAssertEqual(storage.saveCount, 0)
    }

    func testISBNRepetidoNoSeAnadeDosVeces() async {
        let viewModel = ISBNAddViewModel(catalog: MockBookCatalog(), storage: MockBookISBNStorage())
        let library = FakeLibrary()
        viewModel.isbnText = "9788437604947"
        viewModel.title = "Primero"
        viewModel.addBook(existingBookIDs: library.ids, add: library.add)

        // El mismo libro escrito como ISBN-10.
        viewModel.isbnText = "843760494X"
        viewModel.title = "Segundo"
        XCTAssertFalse(viewModel.addBook(existingBookIDs: library.ids, add: library.add))

        XCTAssertEqual(viewModel.status, .duplicate)
        XCTAssertEqual(library.added.count, 1)
    }

    func testISBNDeUnLibroBorradoSePuedeVolverADarDeAlta() async {
        let viewModel = ISBNAddViewModel(catalog: MockBookCatalog(), storage: MockBookISBNStorage())
        let library = FakeLibrary()
        viewModel.isbnText = "9788437604947"
        viewModel.title = "Primero"
        viewModel.addBook(existingBookIDs: library.ids, add: library.add)
        let firstID = library.added[0].id

        // El libro ya no está en el listado (se borró en un producto sin O3).
        viewModel.isbnText = "9788437604947"
        viewModel.title = "Otra vez"
        XCTAssertTrue(viewModel.addBook(existingBookIDs: [], add: library.add))

        XCTAssertNil(viewModel.isbn(for: firstID))
        XCTAssertEqual(viewModel.records.count, 1)
    }

    func testBorrarLibroOlvidaSuISBN() async {
        let storage = MockBookISBNStorage()
        let viewModel = ISBNAddViewModel(catalog: MockBookCatalog(), storage: storage)
        let library = FakeLibrary()
        viewModel.isbnText = "9788437604947"
        viewModel.title = "Libro"
        viewModel.addBook(existingBookIDs: library.ids, add: library.add)
        let saves = storage.saveCount

        viewModel.removeISBN(bookID: UUID())
        XCTAssertEqual(storage.saveCount, saves)

        viewModel.removeISBN(bookID: library.added[0].id)
        XCTAssertTrue(viewModel.records.isEmpty)
        XCTAssertTrue(storage.records.isEmpty)
    }
}
#endif
