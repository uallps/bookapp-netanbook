#if SesionesLectura
// Restricción cruzada del modelo de características: O1 requires F1.
// En SwiftPM el trait `SesionesLectura` ya activa `Progreso` (Package.swift),
// pero un target de Xcode podría definir solo `SesionesLectura`: entonces la
// compilación se para aquí con un mensaje claro.
#if !Progreso
#error("O1 Sesiones de lectura requiere F1 Progreso: añade también la variable Progreso.")
#endif
import Foundation

// O1 · Sesiones de lectura (característica original). Solo se compila con
// `--traits SesionesLectura`.
//
// Relación con el libro: 1 libro → 0..N sesiones, como mucho una en curso.
// La sesión no está dentro de `Book`: apunta al libro con `bookID`.
// F1 guarda *dónde vas*; O1 guarda *cuándo y cuánto lees* en cada sesión.

/// Sesión de lectura: cuándo empezó y terminó y desde qué página hasta cuál.
struct ReadingSession: Identifiable, Codable, Equatable, Sendable {
    let id: UUID

    /// Libro que se está leyendo (`Book.id`).
    let bookID: UUID

    /// Momento en que se inició la sesión.
    let startDate: Date

    /// Página por la que iba el lector al empezar (la página actual de F1).
    let startPage: Int

    /// Momento en que se terminó; `nil` mientras la sesión sigue en curso.
    var endDate: Date?

    /// Página en la que se paró; `nil` mientras la sesión sigue en curso.
    var endPage: Int?

    init(
        id: UUID = UUID(),
        bookID: UUID,
        startDate: Date,
        startPage: Int,
        endDate: Date? = nil,
        endPage: Int? = nil
    ) {
        self.id = id
        self.bookID = bookID
        self.startDate = startDate
        self.startPage = startPage
        self.endDate = endDate
        self.endPage = endPage
    }

    /// Si la sesión sigue en curso.
    var isActive: Bool { endDate == nil }

    /// Duración en segundos; `nil` mientras sigue en curso.
    var duration: TimeInterval? {
        endDate.map { max($0.timeIntervalSince(startDate), 0) }
    }

    /// Páginas leídas en la sesión; `nil` mientras sigue en curso.
    var pagesRead: Int? {
        endPage.map { max($0 - startPage, 0) }
    }
}

extension ReadingSession {
    /// Texto de una duración: «menos de 1 min», «25 min» o «1 h 5 min».
    static func durationText(_ seconds: TimeInterval) -> String {
        let minutes = Int((seconds / 60).rounded(.down))
        if minutes < 1 { return "menos de 1 min" }
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60
        let rest = minutes % 60
        return rest == 0 ? "\(hours) h" : "\(hours) h \(rest) min"
    }
}
#endif
