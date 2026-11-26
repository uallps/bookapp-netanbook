#if AltaISBN
import Foundation
import SwiftUI

/// Sección de O3 · Alta por ISBN, arriba del listado: se escribe el ISBN (o se
/// lee con un lector de códigos de barras, que lo «teclea»), «Buscar» rellena
/// el título y el autor desde Open Library, y «Añadir a la biblioteca» da de
/// alta el libro. Si el catálogo no lo tiene o no hay conexión, el título y el
/// autor se pueden escribir a mano.
///
/// Recibe el ViewModel de O3 (que guarda el formulario y espera la respuesta
/// de la red) y, del listado, solo closures: qué libros existen y cómo añadir
/// uno. No conoce el ViewModel del Core.
///
/// La sección tiene siempre las mismas filas: en Windows, SwiftOpenUI no
/// recoloca las secciones de debajo cuando una crece (ver BookNotesView).
struct ISBNAddView: View {
    let model: ISBNAddViewModel
    /// Libros que siguen en el listado (para no avisar de un ISBN repetido
    /// cuyo libro ya se ha borrado).
    let existingBookIDs: () -> Set<UUID>
    /// Añade un libro con título y autor; devuelve su `id`, o `nil` si no se ha podido.
    let add: (String, String?) -> UUID?

    var body: some View {
        @Bindable var form = model
        Section(header: Text("Alta por ISBN")) {
            HStack {
                TextField("ISBN (10 o 13 cifras)", text: $form.isbnText)
                Button("Buscar") {
                    Task { await model.search() }
                }
                .disabled(model.isSearching)
            }
            TextField("Título", text: $form.title)
            TextField("Autor (opcional)", text: $form.author)
            Button("Añadir a la biblioteca") {
                model.addBook(existingBookIDs: existingBookIDs(), add: add)
            }
            .disabled(model.isSearching)
            Text(model.message)
                .bookCaption()
        }
    }
}
#endif
