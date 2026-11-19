import Foundation

/// F2 · Notas y citas (boceto). Un libro puede tener 0..n notas.
/// La relación va de la nota al libro (`bookID`), nunca al revés.
enum NoteKind: String, CaseIterable {
    case nota = "Nota"
    case cita = "Cita"
}

struct Note: Identifiable {
    let id = UUID()
    var bookID: UUID
    var kind: NoteKind = .nota
    var text: String
    /// Página en la que se tomó la nota (opcional).
    var page: Int?
}
