/// Estado de lectura de un libro (Core).
/// El `rawValue` es el texto que se muestra.
enum ReadingStatus: String, CaseIterable {
    case pendiente = "Pendiente"
    case leyendo = "Leyendo"
    case terminado = "Terminado"

    /// Siguiente estado en el ciclo Pendiente → Leyendo → Terminado → Pendiente.
    var next: ReadingStatus {
        switch self {
        case .pendiente: return .leyendo
        case .leyendo: return .terminado
        case .terminado: return .pendiente
        }
    }
}
