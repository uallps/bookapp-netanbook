import SwiftUI
import Observation

/// Punto de entrada de Netanbook.
///
/// En macOS usa el SwiftUI de Apple (proyecto de Xcode). En Linux y Windows,
/// `import SwiftUI` trae SwiftOpenUI a través del módulo `Compat/SwiftUI`.
@main
struct NetanbookApp: App {
    /// Una sola configuración para toda la app: la comparten Libros y Ajustes.
    @State private var config = AppConfig()
#if !os(iOS)
    /// Sección elegida en la barra lateral.
    @State private var navigation = AppNavigation()
#endif

    var body: some Scene {
        WindowGroup(Product.name) {
#if os(iOS)
            TabView {
                BookListView()
                    .tabItem { Label("Libros", systemImage: "books.vertical") }
                SettingsView()
                    .tabItem { Label("Ajustes", systemImage: "gearshape") }
            }
            .environment(config)
#else
            NavigationSplitView {
                SidebarView(navigation: navigation)
            } detail: {
#if os(Windows)
                // En Windows (SwiftOpenUI), las vistas con estado como SectionView
                // se montan después del resto, así que la vista dividida no sabe
                // que el detalle debe ocupar todo el sitio. Color.clear se dibuja
                // en el momento y se lo indica. Va detrás de SectionView porque en
                // Win32 el primer hijo de un ZStack queda encima y recibe los clics.
                // Solo en Windows: en Linux (GTK) el Color quedaría encima de la lista.
                ZStack {
                    SectionView(navigation: navigation)
                    Color.clear
                }
#else
                SectionView(navigation: navigation)
#endif
            }
            .environment(config)
#endif
        }
    }
}

#if !os(iOS)
/// Sección elegida en la barra lateral: Libros o Ajustes.
///
/// Es un objeto observable, y no un `@State` de la app, para que al cambiar de
/// sección solo se vuelvan a dibujar la barra lateral y el detalle, no la
/// ventana entera. En Windows, cuando se redibuja la ventana entera, SwiftOpenUI
/// deja el contenido de la sección nueva encogido a su tamaño mínimo.
@Observable
final class AppNavigation {
    var selection: String? = "libros"
}

/// Barra lateral con las secciones de la app.
private struct SidebarView: View {
    let navigation: AppNavigation

    var body: some View {
        @Bindable var navigation = navigation
        List(selection: $navigation.selection) {
            NavigationLink(value: "libros") {
                Label("Libros", systemImage: "books.vertical")
            }
            NavigationLink(value: "ajustes") {
                Label("Ajustes", systemImage: "gearshape")
            }
        }
    }
}

/// Contenido de la sección elegida en la barra lateral.
private struct SectionView: View {
    let navigation: AppNavigation

    var body: some View {
        switch navigation.selection {
        case "libros":
            BookListView()
        case "ajustes":
            SettingsView()
        default:
            Text("Elige una opción")
        }
    }
}
#endif
