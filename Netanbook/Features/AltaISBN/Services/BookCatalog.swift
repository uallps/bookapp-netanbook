#if AltaISBN
import Foundation
#if canImport(FoundationNetworking)
// En Linux y Windows, URLSession está en FoundationNetworking.
import FoundationNetworking
#endif

/// Catálogo público de libros que O3 consulta por ISBN.
///
/// Es lo único de Netanbook que usa la red, y solo existe en los productos con
/// O3: el Core y el resto de características siguen funcionando sin conexión.
protocol BookCatalog {
    /// Busca un ISBN-13 normalizado. Devuelve `nil` si el catálogo no lo
    /// tiene; lanza un error si no se ha podido consultar.
    func lookup(isbn: String) async throws -> ISBNBookInfo?
}

/// Errores al consultar el catálogo. `nonisolated` porque se crea en la
/// respuesta de URLSession, que no llega en el hilo principal.
nonisolated enum BookCatalogError: Error, Equatable {
    /// El servidor ha respondido con un código HTTP que no es 2xx.
    case badStatus(Int)
    /// La respuesta no es el JSON esperado.
    case invalidResponse
}

/// Catálogo de Open Library (openlibrary.org): gratuito y sin clave.
///
/// Usa la API `api/books`, que devuelve título y autores en una sola petición:
/// `https://openlibrary.org/api/books?bibkeys=ISBN:<isbn>&format=json&jscmd=data`.
/// Si no conoce el ISBN, responde `{}`.
final class OpenLibraryCatalog: BookCatalog {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func lookup(isbn: String) async throws -> ISBNBookInfo? {
        var components = URLComponents(string: "https://openlibrary.org/api/books")!
        components.queryItems = [
            URLQueryItem(name: "bibkeys", value: "ISBN:\(isbn)"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "jscmd", value: "data"),
        ]
        var request = URLRequest(url: components.url!, timeoutInterval: 10)
        // Open Library pide que los clientes se identifiquen.
        request.setValue("Netanbook/1.0 (proyecto universitario)", forHTTPHeaderField: "User-Agent")
        let data = try await fetch(request)
        return try Self.parse(data, isbn: isbn)
    }

    /// Descarga con `dataTask` y su closure: es la forma de URLSession que
    /// funciona igual en macOS, Linux y Windows.
    private func fetch(_ request: URLRequest) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            session.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let status = (response as? HTTPURLResponse)?.statusCode,
                          !(200..<300).contains(status) {
                    continuation.resume(throwing: BookCatalogError.badStatus(status))
                } else {
                    continuation.resume(returning: data ?? Data())
                }
            }.resume()
        }
    }

    /// Lee la respuesta de `api/books`. Separado de la red para poder
    /// probarlo con un JSON de ejemplo.
    static func parse(_ data: Data, isbn: String) throws -> ISBNBookInfo? {
        let decoded: [String: OpenLibraryBook]
        do {
            decoded = try JSONDecoder().decode([String: OpenLibraryBook].self, from: data)
        } catch {
            throw BookCatalogError.invalidResponse
        }
        guard let book = decoded["ISBN:\(isbn)"] ?? decoded.values.first else { return nil }
        let title = book.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }
        let names = (book.authors ?? [])
            .map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return ISBNBookInfo(
            isbn: isbn,
            title: title,
            author: names.isEmpty ? nil : names.joined(separator: ", ")
        )
    }
}

/// Lo que se usa de cada libro en la respuesta de Open Library.
private struct OpenLibraryBook: Decodable {
    struct Author: Decodable {
        let name: String
    }

    let title: String
    let authors: [Author]?
}

/// Catálogo en memoria para pruebas y vistas previas: no usa la red.
final class MockBookCatalog: BookCatalog {
    /// Libros que «conoce», por ISBN-13.
    var books: [String: ISBNBookInfo]
    /// Si no es `nil`, cada búsqueda lanza este error (simula estar sin conexión).
    var error: Error?
    /// ISBN buscados, en orden: las pruebas comprueban que no se busca uno no válido.
    private(set) var searched: [String] = []

    init(books: [ISBNBookInfo] = [], error: Error? = nil) {
        self.books = Dictionary(uniqueKeysWithValues: books.map { ($0.isbn, $0) })
        self.error = error
    }

    func lookup(isbn: String) async throws -> ISBNBookInfo? {
        searched.append(isbn)
        if let error { throw error }
        return books[isbn]
    }
}
#endif
