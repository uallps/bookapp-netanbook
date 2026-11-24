import SwiftUI

/// Pantalla de Ajustes: activa o desactiva en ejecución las características
/// que lleva el producto compilado.
///
/// Lee la configuración del entorno (la misma que usa el listado) y la edita
/// con `@Bindable`. Cada cambio se guarda en `UserDefaults` desde `AppConfig`.
struct SettingsView: View {
    @Environment(AppConfig.self) private var config

    var body: some View {
        @Bindable var config = config
        Form {
#if Progreso || Notas || Prestamos
            Section(header: Text("Características de este producto")) {
#if Progreso
                Toggle("Mostrar el progreso de lectura", isOn: $config.showProgress)
#endif
#if Notas
                Toggle("Mostrar notas y citas", isOn: $config.showNotes)
#endif
#if Prestamos
                Toggle("Mostrar préstamos", isOn: $config.showLoans)
#endif
            }
#endif
            // F3–F5 todavía no tienen código: su interruptor se guarda, pero
            // aún no cambia nada en el listado.
            Section(header: Text("Próximas características (sin implementar)")) {
                Toggle("Categorías", isOn: $config.showCategories)
                Toggle("Valoraciones y reseñas", isOn: $config.showReviews)
                Toggle("Estadísticas", isOn: $config.showStatistics)
            }
        }
        .navigationTitle("Ajustes")
    }
}
