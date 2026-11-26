#if Categorias
import Foundation
import Observation

/// ViewModel de F3 · Categorías.
///
/// Guarda las categorías y a qué libros están asignadas. Es independiente del
/// ViewModel del listado: el Core no sabe que existe. Cada cambio se guarda en
/// el almacenamiento propio de F3 (`BookCategoriesStorage`).
@Observable
final class BookCategoriesViewModel {
    /// Todas las categorías. Solo este ViewModel puede modificarlas.
    private(set) var categories: [BookCategory] = []

    /// Asignaciones libro–categoría. Nunca hay dos iguales ni apuntan a una
    /// categoría que no existe.
    private(set) var assignments: [BookCategoryAssignment] = []

    @ObservationIgnored private let storage: BookCategoriesStorage

    /// Carga las categorías guardadas. Si aún no hay nada guardado, empieza con
    /// las categorías de ejemplo asignadas a los libros de ejemplo.
    init(storage: BookCategoriesStorage = JSONBookCategoriesStorage()) {
        self.storage = storage
        let data = (try? storage.loadCategories()) ?? BookCategoriesData.samples
        categories = data.categories
        assignments = data.assignments
    }

    private func save() {
        do {
            try storage.saveCategories(BookCategoriesData(categories: categories, assignments: assignments))
        } catch {
            print("No se han guardado las categorías: \(error)")
        }
    }

    // MARK: - Consultas

    /// Todas las categorías, por orden alfabético.
    func sortedCategories() -> [BookCategory] {
        categories.sorted {
            BookCategory.comparableName($0.name) < BookCategory.comparableName($1.name)
        }
    }

    /// La categoría con ese `id`, si existe.
    func category(id: UUID) -> BookCategory? {
        categories.first { $0.id == id }
    }

    /// Categorías asignadas a un libro, por orden alfabético.
    func categories(for bookID: UUID) -> [BookCategory] {
        let ids = Set(assignments.filter { $0.bookID == bookID }.map(\.categoryID))
        return sortedCategories().filter { ids.contains($0.id) }
    }

    /// Si el libro tiene asignada la categoría.
    func isAssigned(bookID: UUID, categoryID: UUID) -> Bool {
        assignments.contains(BookCategoryAssignment(bookID: bookID, categoryID: categoryID))
    }

    /// Libros que tienen asignada la categoría (para filtrar el listado).
    func bookIDs(in categoryID: UUID) -> Set<UUID> {
        Set(assignments.filter { $0.categoryID == categoryID }.map(\.bookID))
    }

    /// Si ya hay otra categoría con ese nombre (sin distinguir mayúsculas ni
    /// tildes). `excluding` deja fuera la categoría que se está renombrando.
    func nameExists(_ name: String, excluding id: UUID? = nil) -> Bool {
        let wanted = BookCategory.comparableName(name)
        return categories.contains { $0.id != id && BookCategory.comparableName($0.name) == wanted }
    }

    // MARK: - Categorías

    /// Crea una categoría. Devuelve `nil` si el nombre está vacío o ya existe.
    @discardableResult
    func addCategory(name: String) -> BookCategory? {
        guard BookCategory.isValidName(name), !nameExists(name) else { return nil }
        let category = BookCategory(name: name)
        categories.append(category)
        save()
        return category
    }

    /// Cambia el nombre de una categoría. Devuelve `false` si no existe, si el
    /// nombre está vacío o si ya lo usa otra; en ese caso no cambia nada.
    @discardableResult
    func renameCategory(id: UUID, to name: String) -> Bool {
        guard BookCategory.isValidName(name), !nameExists(name, excluding: id),
              let index = categories.firstIndex(where: { $0.id == id }) else { return false }
        categories[index].name = BookCategory.cleanName(name)
        save()
        return true
    }

    /// Borra una categoría y la quita de todos los libros que la tenían.
    func removeCategory(id: UUID) {
        guard categories.contains(where: { $0.id == id }) else { return }
        categories.removeAll { $0.id == id }
        assignments.removeAll { $0.categoryID == id }
        save()
    }

    // MARK: - Asignaciones

    /// Asigna o quita una categoría a un libro. Si ya estaba así, o si la
    /// categoría no existe, no hace nada.
    func setAssigned(_ assigned: Bool, bookID: UUID, categoryID: UUID) {
        guard category(id: categoryID) != nil,
              isAssigned(bookID: bookID, categoryID: categoryID) != assigned else { return }
        let assignment = BookCategoryAssignment(bookID: bookID, categoryID: categoryID)
        if assigned {
            assignments.append(assignment)
        } else {
            assignments.removeAll { $0 == assignment }
        }
        save()
    }

    /// Quita todas las asignaciones de un libro (cuando el libro se elimina del
    /// listado). Las categorías se conservan. Si el libro no tenía ninguna, no
    /// toca el fichero.
    func removeAssignments(bookID: UUID) {
        let before = assignments.count
        assignments.removeAll { $0.bookID == bookID }
        if assignments.count != before { save() }
    }
}
#endif
