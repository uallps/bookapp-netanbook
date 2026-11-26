#if Valoraciones
import Foundation
import SwiftUI

/// Closures que el detalle de un libro recibe para operar con F4 sin conocer su ViewModel.
struct ReviewForBook {
    let review: () -> BookReview?
    let save: (Int, String?) -> Bool
    let remove: () -> Void
}

/// Vista de F4 · Valoraciones y reseñas dentro del detalle de un libro.
struct BookReviewView: View {
    let data: ReviewForBook

    @State private var rating: Int = 5
    @State private var text: String = ""
    @State private var loaded = false
    @State private var feedback: String?

    var body: some View {
        let existing = data.review()
        Section(header: Text("Valoración y reseña")) {
            HStack {
                Text("Puntuación:")
                ForEach(Array(BookReview.ratingRange), id: \.self) { star in
                    Button {
                        rating = star
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundColor(star <= rating ? .orange : .gray)
                    }
                    .buttonStyle(.plain)
                }
                Text("(\(rating)/5)")
                    .bookCaption()
            }

            TextField("Reseña breve (opcional)", text: $text)

            HStack {
                Button(existing == nil ? "Guardar valoración" : "Actualizar valoración") {
                    if data.save(rating, text) {
                        feedback = "Valoración guardada"
                    }
                }
                if existing != nil {
                    Button("Borrar valoración") {
                        data.remove()
                        rating = 5
                        text = ""
                        feedback = "Valoración eliminada"
                    }
                }
            }

            if let existing {
                Text("Guardada: \(starsText(for: existing.rating))\(existing.text.map { " — \($0)" } ?? "")")
                    .bookCaption()
            } else {
                Text(feedback ?? "Este libro aún no tiene valoración")
                    .bookCaption()
            }
        }
        .onAppear {
            if !loaded, let existing {
                rating = existing.rating
                text = existing.text ?? ""
                loaded = true
            }
        }
    }

    private func starsText(for value: Int) -> String {
        String(repeating: "★", count: value) + String(repeating: "☆", count: 5 - value)
    }
}
#endif