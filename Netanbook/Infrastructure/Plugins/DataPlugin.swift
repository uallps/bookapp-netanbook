import Foundation

/// Plugin con datos propios ligados a los libros (progreso, notas, préstamos…).
///
/// Sus datos van en su propio fichero, fuera de `Book`. El registro le avisa
/// cuando se borra o se modifica un libro (patrón observador), así que el núcleo
/// no tiene que saber qué datos existen para borrarlos.
protocol DataPlugin: FeaturePlugin {
    /// Antes de borrar el libro: todavía se puede consultar. Aquí se borran los
    /// datos del plugin para ese libro.
    func willDeleteBook(_ book: Book)
    /// Después de borrarlo: ya solo queda su id.
    func didDeleteBook(id: UUID)
    /// Después de cambiar un libro (título, estado…), ya con sus valores nuevos.
    /// Lo usan los plugins que reaccionan al estado, como el objetivo anual.
    func didUpdateBook(_ book: Book)
}

/// Lo habitual es necesitar solo `willDeleteBook`: los otros dos avisos no hacen
/// nada si el plugin no los implementa.
extension DataPlugin {
    func didDeleteBook(id: UUID) {}
    func didUpdateBook(_ book: Book) {}
}
