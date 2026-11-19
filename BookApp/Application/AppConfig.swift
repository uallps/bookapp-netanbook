import Observation

/// Feature flags en ejecución: qué características muestra la app.
/// Es configuración de la aplicación, no datos de los libros.
/// Todos empiezan desactivados: al arrancar se ve la variante Base (solo Core).
///
/// El flag decide si una característica SE MUESTRA; que su código EXISTA en el
/// programa lo decide la compilación (por ahora solo F1, con `#if Progreso`).
@Observable
final class AppConfig {
    var enableProgress = false     // F1 · Progreso
    var enableNotes = false        // F2 · Notas y citas
    var enableCategories = false   // F3 · Categorías
    var enableReviews = false      // F4 · Valoraciones y reseñas
    var enableStatistics = false   // F5 · Estadísticas
}
