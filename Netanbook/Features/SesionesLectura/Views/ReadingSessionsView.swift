#if SesionesLectura
import Foundation
import SwiftUI

/// Lo que el detalle de un libro necesita de O1, sin conocer ningún ViewModel:
/// cómo leer las sesiones y la página actual (de F1) y las acciones, como
/// closures. Lo crea el listado, que es quien conoce O1 y F1.
struct SessionsForBook {
    let active: () -> ReadingSession?
    let history: () -> [ReadingSession]
    /// Página actual del libro según F1 (desde ella empieza la sesión).
    let currentPage: () -> Int
    /// Total de páginas según F1, si se conoce (la página final no puede pasarlo).
    let totalPages: () -> Int?
    let start: () -> Bool
    /// Termina la sesión en una página y la pasa a F1. Devuelve `false` si no se ha podido.
    let stop: (Int) -> Bool
    let cancel: () -> Void
    let remove: (UUID) -> Void
}

/// Sección de O1 · Sesiones de lectura en el detalle de un libro.
///
/// - Sin sesión en curso: la página desde la que empezará y «Iniciar sesión».
/// - Con sesión en curso: la hora y la página de inicio, un campo para la
///   página en la que se para, «Terminar sesión» y «Descartar».
/// - Debajo, el resumen y el historial de sesiones terminadas, cada una con «Borrar».
///
/// La sección tiene siempre el mismo alto: los dos estados ocupan dos líneas,
/// el historial va en un área desplazable de alto fijo y la línea del aviso
/// está siempre. En Windows, SwiftOpenUI no recoloca las secciones de debajo
/// cuando una crece.
struct ReadingSessionsView: View {
    let data: SessionsForBook

    @State private var endPageText = ""
    @State private var warning: String?

    var body: some View {
        let active = data.active()
        let history = data.history()
        Section(header: Text("Sesiones de lectura")) {
            if let active {
                Text("Sesión en curso desde \(Self.dateText(active.startDate)) · empezó en la página \(active.startPage)")
                HStack {
                    TextField("Página en la que paras", text: $endPageText)
                    Button("Terminar sesión") { stop(active) }
                    Button("Descartar") {
                        data.cancel()
                        clearForm()
                    }
                }
            } else {
                Text("No hay ninguna sesión en curso")
                    .bookCaption()
                HStack {
                    Text("Empezará en la página \(data.currentPage())")
                    Button("Iniciar sesión", action: start)
                }
            }
            Text(summary(history))
                .bookCaption(color: .bookAccent)
            ScrollView {
                VStack(alignment: .leading) {
                    if history.isEmpty {
                        Text("Aún no hay sesiones terminadas")
                            .bookCaption()
                    }
                    ForEach(history) { session in
                        HStack {
                            Text(label(for: session))
                            Button("Borrar") { data.remove(session.id) }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 100)
            Text(warning ?? " ")
                .bookCaption()
        }
    }

    private func start() {
        if data.start() {
            clearForm()
        } else {
            warning = "No se ha podido iniciar la sesión"
        }
    }

    /// Valida la página final y termina la sesión. Si no es válida, avisa y no
    /// borra lo escrito.
    private func stop(_ active: ReadingSession) {
        let input = endPageText.trimmingCharacters(in: .whitespaces)
        guard let page = Int(input) else {
            warning = "Escribe la página en la que paras"
            return
        }
        guard page >= active.startPage else {
            warning = "La página final no puede ser menor que la inicial (\(active.startPage))"
            return
        }
        if let total = data.totalPages(), page > total {
            warning = "El libro tiene \(total) páginas"
            return
        }
        if data.stop(page) {
            clearForm()
        } else {
            warning = "No se ha podido terminar la sesión"
        }
    }

    private func clearForm() {
        endPageText = ""
        warning = nil
    }

    /// Resumen de las sesiones terminadas: número, tiempo y páginas.
    private func summary(_ history: [ReadingSession]) -> String {
        guard !history.isEmpty else { return "Sin sesiones registradas" }
        let time = history.compactMap(\.duration).reduce(0, +)
        let pages = history.compactMap(\.pagesRead).reduce(0, +)
        let count = history.count == 1 ? "1 sesión" : "\(history.count) sesiones"
        return "\(count) · \(ReadingSession.durationText(time)) · \(pages) páginas"
    }

    /// Una línea por sesión: «24/11/2026 18:30 · 25 min · p. 10 → 30».
    private func label(for session: ReadingSession) -> String {
        let duration = session.duration.map(ReadingSession.durationText) ?? "en curso"
        let pages = session.endPage.map { "p. \(session.startPage) → \($0)" } ?? "p. \(session.startPage)"
        return "\(Self.dateText(session.startDate)) · \(duration) · \(pages)"
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: date)
    }
}
#endif
