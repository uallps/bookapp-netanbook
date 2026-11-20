#if Notas
import SwiftUI

/// Vista de F2 · Notas y citas para un libro: lista de anotaciones y un
/// formulario para añadir otra. No conoce ningún ViewModel: recibe los datos
/// y las acciones como parámetros.
struct BookNotesView: View {
    let notes: [BookNote]
    let add: (NoteKind, String, Int?) -> Bool
    let remove: (UUID) -> Void

    @State private var kind: NoteKind = .note
    @State private var text = ""
    @State private var pageText = ""

    var body: some View {
        Section(header: Text("Notas y citas")) {
            if notes.isEmpty {
                Text("Este libro no tiene notas ni citas")
                    .bookCaption()
            }
            ForEach(notes) { note in
                HStack {
                    Text(label(for: note))
                    Button("Borrar") { remove(note.id) }
                }
            }
            Picker("Tipo", selection: $kind) {
                ForEach(NoteKind.allCases, id: \.self) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            TextField("Texto de la nota o cita", text: $text)
            TextField("Página (opcional)", text: $pageText)
            Button("Añadir") {
                if add(kind, text, Int(pageText)) {
                    text = ""
                    pageText = ""
                }
            }
        }
    }

    /// Una línea por anotación: tipo, texto y página si se conoce.
    private func label(for note: BookNote) -> String {
        let page = note.page.map { " (p. \($0))" } ?? ""
        return "\(note.kind.rawValue): \(note.text)\(page)"
    }
}
#endif
