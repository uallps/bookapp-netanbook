/// Lo que tiene todo plugin: una característica que se añade a la app sin que el
/// núcleo (modelo, ViewModel y vistas del listado) sepa cuál es.
///
/// Un plugin no se usa solo con este protocolo: además cumple `DataPlugin` (si
/// guarda datos ligados a los libros), `ViewPlugin` (si aporta vistas) y
/// `BookFilterPlugin` (si oculta libros del listado), según lo que necesite.
protocol FeaturePlugin: AnyObject {
    /// Nombre del plugin, para los mensajes. No puede haber dos iguales: también
    /// sirve de identificador de sus vistas.
    var name: String { get }
}
