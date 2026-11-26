#if Categorias
import Foundation
import SwiftUI

/// Filtro del listado por categoría (F3): un botón «Todas» y uno por categoría.
/// La elegida lleva una marca delante. No conoce ningún ViewModel: recibe las
/// categorías, la elegida y la acción de elegir.
struct CategoryFilterView: View {
    let categories: [BookCategory]
    /// Categoría elegida; `nil` si se muestran todos los libros.
    let selected: UUID?
    let select: (UUID?) -> Void

    var body: some View {
        Section(header: Text("Filtrar por categoría")) {
            HStack {
                Button(label("Todas", isSelected: selected == nil)) { select(nil) }
                ForEach(categories) { category in
                    Button(label(category.name, isSelected: selected == category.id)) {
                        select(category.id)
                    }
                }
            }
        }
    }

    private func label(_ text: String, isSelected: Bool) -> String {
        isSelected ? "✓ \(text)" : text
    }
}
#endif
