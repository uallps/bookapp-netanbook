#if Notas
import Foundation
import SwiftUI

/// Lo que el detalle de un libro necesita de F2, sin conocer su ViewModel: cómo
/// leer las anotaciones del libro y las acciones sobre ellas, como closures. Lo
/// crea el listado, igual que el enlace `book` del detalle.
struct NotesForBook {
    let notes: () -> [BookNote]
    let add: (NoteKind, String, Int?) -> Bool
    let update: (UUID, NoteKind, String, Int?) -> Bool
    let remove: (UUID) -> Void
}

/// Vista de F2 · Notas y citas para un libro: las anotaciones, cada una con
/// «Editar» y «Borrar», y un formulario para añadir otra o guardar la que se
/// edita. No conoce ningún ViewModel: lee las notas con `data.notes()` en su
/// `body`, así que se vuelve a dibujar sola cuando cambian.
///
/// La sección tiene siempre el mismo alto: la lista va en un área desplazable
/// de alto fijo y la línea del aviso está siempre (vacía si no hay aviso). En
/// Windows, SwiftOpenUI no recoloca las secciones de debajo cuando una crece.
struct BookNotesView: View {
    let data: NotesForBook

    /// Anotación que se está editando; `nil` mientras se añade una nueva.
    @State private var editingID: UUID?
    @State private var kind: NoteKind = .note
    @State private var text = ""
    @State private var pageText = ""
    /// Aviso si no se ha podido guardar (texto vacío o página no válida).
    @State private var warning: String?

    var body: some View {
        let notes = data.notes()
        Section(header: Text("Notas y citas")) {
            ScrollView {
                VStack(alignment: .leading) {
                    if notes.isEmpty {
                        Text("Este libro no tiene notas ni citas")
                            .bookCaption()
                    }
                    ForEach(notes) { note in
                        HStack {
                            Text(label(for: note))
                            Button("Editar") { startEditing(note) }
                            Button("Borrar") { remove(note) }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 100)
            Picker("Tipo", selection: $kind) {
                ForEach(NoteKind.allCases, id: \.self) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            TextField("Texto de la nota o cita", text: $text)
            HStack {
                TextField("Página (opcional)", text: $pageText)
                if editingID == nil {
                    Button("Añadir", action: save)
                } else {
                    Button("Guardar cambios", action: save)
                    Button("Cancelar", action: clearForm)
                }
            }
            Text(warning ?? " ")
                .bookCaption()
        }
    }

    /// Añade la anotación o guarda la que se edita. Si algo no es válido,
    /// avisa y no borra lo escrito.
    private func save() {
        let pageInput = pageText.trimmingCharacters(in: .whitespaces)
        let page = Int(pageInput)
        if !pageInput.isEmpty && BookNote.validPage(page) == nil {
            warning = "La página tiene que ser un número mayor que 0"
            return
        }
        let saved: Bool
        if let editingID {
            saved = data.update(editingID, kind, text, page)
        } else {
            saved = data.add(kind, text, page)
        }
        if saved {
            clearForm()
        } else {
            warning = "Escribe el texto de la nota o de la cita"
        }
    }

    /// Pasa una anotación al formulario para editarla.
    private func startEditing(_ note: BookNote) {
        editingID = note.id
        kind = note.kind
        text = note.text
        pageText = note.page.map { String($0) } ?? ""
        warning = nil
    }

    /// Borra una anotación; si era la que se editaba, vacía el formulario.
    private func remove(_ note: BookNote) {
        data.remove(note.id)
        if editingID == note.id { clearForm() }
    }

    private func clearForm() {
        editingID = nil
        kind = .note
        text = ""
        pageText = ""
        warning = nil
    }

    /// Una línea por anotación: tipo, texto y página si se conoce.
    private func label(for note: BookNote) -> String {
        let page = note.page.map { " (p. \($0))" } ?? ""
        return "\(note.kind.rawValue): \(note.text)\(page)"
    }
}
#endif
