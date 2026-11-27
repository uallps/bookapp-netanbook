/// Plugin que decide qué libros se ven en el listado (por ejemplo, F3 al filtrar
/// por una categoría). El listado muestra un libro solo si **todos** los filtros
/// lo incluyen; sin filtros registrados se ven todos.
protocol BookFilterPlugin: FeaturePlugin {
    /// Si el libro se muestra ahora. Un filtro apagado devuelve siempre `true`.
    func includes(_ book: Book) -> Bool
}
