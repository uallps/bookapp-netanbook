import SwiftUI

/// Pantalla de Ajustes: activa o desactiva en ejecución las características
/// que lleva el producto compilado. Solo aparecen los interruptores de las
/// características que se han compilado.
///
/// Los interruptores de los plugins los aporta cada plugin a través del
/// registro. Los de las características que aún no son plugins siguen aquí,
/// cada uno en su `#if`, hasta que se migren.
struct SettingsView: View {
    @Environment(AppConfig.self) private var config

    var body: some View {
        @Bindable var config = config
        // Los ajustes de los plugins (por ejemplo, «Mostrar estadísticas»).
        let pluginSettings = PluginRegistry.shared.settingsViews()
        Form {
            Section(header: Text("Características de este producto")) {
                ForEach(pluginSettings) { pluginView in
                    pluginView.view
                }
#if Progreso
                Toggle("Mostrar el progreso de lectura", isOn: $config.showProgress)
#endif
#if Notas
                Toggle("Mostrar notas y citas", isOn: $config.showNotes)
#endif
#if Categorias
                Toggle("Mostrar categorías", isOn: $config.showCategories)
#endif
#if Valoraciones
                Toggle("Mostrar valoraciones y reseñas", isOn: $config.showReviews)
#endif
#if SesionesLectura
                Toggle("Mostrar sesiones de lectura", isOn: $config.showReadingSessions)
#endif
#if Prestamos
                Toggle("Mostrar préstamos", isOn: $config.showLoans)
#endif
#if AltaISBN
                Toggle("Mostrar alta por ISBN", isOn: $config.showISBN)
#endif
#if ObjetivoAnual
                Toggle("Mostrar objetivo anual", isOn: $config.showAnnualGoal)
#endif
#if !(Progreso || Notas || Categorias || Valoraciones || SesionesLectura || Prestamos || AltaISBN || ObjetivoAnual)
                // Sin características sin migrar: si tampoco hay plugins, es el producto base.
                if pluginSettings.isEmpty {
                    Text("Este producto solo incluye el Core: no hay características que activar.")
                        .bookCaption()
                }
#endif
            }
        }
        .navigationTitle("Ajustes")
    }
}
