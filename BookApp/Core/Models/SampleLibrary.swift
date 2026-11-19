import Foundation

/// Libros de ejemplo con ids fijos, para que las features (por ejemplo F1)
/// puedan tener datos de ejemplo enlazados a ellos.
enum SampleLibrary {
    static let nombreDelViento = UUID(uuidString: "6E1F0B1A-0001-4C5A-9D3E-000000000001")!
    static let cienAnios = UUID(uuidString: "6E1F0B1A-0002-4C5A-9D3E-000000000002")!
    static let sapiens = UUID(uuidString: "6E1F0B1A-0003-4C5A-9D3E-000000000003")!
    static let cleanCode = UUID(uuidString: "6E1F0B1A-0004-4C5A-9D3E-000000000004")!

    static let books: [Book] = [
        Book(id: nombreDelViento, title: "El nombre del viento", author: "Patrick Rothfuss", status: .leyendo),
        Book(id: cleanCode, title: "Clean Code", author: "Robert C. Martin", status: .leyendo),
        Book(id: cienAnios, title: "Cien años de soledad", author: "Gabriel García Márquez", status: .terminado),
        Book(id: sapiens, title: "Sapiens", status: .pendiente),
    ]
}
