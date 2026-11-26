import SwiftUI

/// Pantalla de Ajustes: activa o desactiva en ejecución las características
/// que lleva el producto compilado. Solo aparecen los interruptores de las
/// características que se han compilado.
struct SettingsView: View {
    @Environment(AppConfig.self) private var config

    var body: some View {
        @Bindable var config = config
        Form {
#if Progreso || Notas || Categorias || Valoraciones || Estadisticas || SesionesLectura || Prestamos || ObjetivoAnual
            Section(header: Text("Características de este producto")) {
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
#if Estadisticas
                Toggle("Mostrar estadísticas", isOn: $config.showStatistics)
#endif
#if SesionesLectura
                Toggle("Mostrar sesiones de lectura", isOn: $config.showReadingSessions)
#endif
#if Prestamos
                Toggle("Mostrar préstamos", isOn: $config.showLoans)
#endif
#if ObjetivoAnual
                Toggle("Mostrar objetivo anual", isOn: $config.showAnnualGoal)
#endif
            }
#else
            Section(header: Text("Características de este producto")) {
                Text("Este producto solo incluye el Core: no hay características que activar.")
                    .bookCaption()
            }
#endif
        }
        .navigationTitle("Ajustes")
    }
}
