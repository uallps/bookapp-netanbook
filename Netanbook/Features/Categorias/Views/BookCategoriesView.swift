#if Categorias
import Foundation
import SwiftUI

/// Lo que el detalle de un libro necesita de F3, sin conocer su ViewModel: cómo
/// leer las categorías y las acciones sobre ellas, como closures. Lo crea el
/// listado, igual que el enlace `book` del detalle.
struct CategoriesForBook {
    /// Todas las categorías, por orden alfabético.
    let all: () -> [BookCategory]
    /// Si el libro tiene asignada la categoría.
    let isAssigned: (UUID) -> Bool
    /// Asigna (`true`) o quita (`false`) la categoría al libro.
    let setAssigned: (UUID, Bool) -> Void
    /// Si ya existe otra categoría con ese nombre (la del `UUID` no cuenta).
    let nameExists: (String, UUID?) -> Bool
    /// Crea una categoría y se la asigna al libro. `false` si no se ha podido.
    let create: (String) -> Bool
    let rename: (UUID, String) -> Bool
    let remove: (UUID) -> Void
}

/// Vista de F3 · Categorías para un libro: todas las categorías, cada una con
/// un interruptor para asignarla al libro, «Renombrar» y «Borrar», y un
/// formulario para crear otra (que se asigna al libro) o renombrar la elegida.
/// No conoce ningún ViewModel: lee las categorías con closures en su `body`,
/// así que se vuelve a dibujar sola cuando cambian.
///
/// Como en F2, la sección tiene siempre el mismo alto (ver BookNotesView).
struct BookCategoriesView: View {
    let data: CategoriesForBook

    /// Categoría que se está renombrando; `nil` mientras se crea una nueva.
    @State private var editingID: UUID?
    @State private var name = ""
    /// Aviso si no se ha podido guardar (nombre vacío o repetido).
    @State private var warning: String?

    var body: some View {
        let categories = data.all()
        Section(header: Text("Categorías")) {
            ScrollView {
                VStack(alignment: .leading) {
                    if categories.isEmpty {
                        Text("Todavía no hay categorías")
                            .bookCaption()
                    }
                    ForEach(categories) { category in
                        HStack {
                            Toggle(category.name, isOn: assignment(of: category))
                            Button("Renombrar") { startEditing(category) }
                            Button("Borrar") { remove(category) }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 100)
            HStack {
                TextField("Nombre de la categoría", text: $name)
                if editingID == nil {
                    Button("Crear y asignar", action: save)
                } else {
                    Button("Guardar nombre", action: save)
                    Button("Cancelar", action: clearForm)
                }
            }
            Text(warning ?? " ")
                .bookCaption()
        }
    }

    /// Enlace del interruptor: leer y escribir se traducen a closures de F3.
    private func assignment(of category: BookCategory) -> Binding<Bool> {
        Binding(
            get: { data.isAssigned(category.id) },
            set: { data.setAssigned(category.id, $0) }
        )
    }

    /// Crea la categoría o guarda el nombre nuevo. Si el nombre no es válido,
    /// avisa y no borra lo escrito.
    private func save() {
        guard BookCategory.isValidName(name) else {
            warning = "Escribe el nombre de la categoría"
            return
        }
        guard !data.nameExists(name, editingID) else {
            warning = "Ya hay una categoría con ese nombre"
            return
        }
        let saved: Bool
        if let editingID {
            saved = data.rename(editingID, name)
        } else {
            saved = data.create(name)
        }
        if saved {
            clearForm()
        } else {
            warning = "No se ha podido guardar la categoría"
        }
    }

    /// Pasa una categoría al formulario para renombrarla.
    private func startEditing(_ category: BookCategory) {
        editingID = category.id
        name = category.name
        warning = nil
    }

    /// Borra una categoría (de todos los libros); si era la que se renombraba,
    /// vacía el formulario.
    private func remove(_ category: BookCategory) {
        data.remove(category.id)
        if editingID == category.id { clearForm() }
    }

    private func clearForm() {
        editingID = nil
        name = ""
        warning = nil
    }
}
#endif
