/// F5 · Estadísticas (boceto). Son datos derivados: no se guardan, se calculan
/// a partir de los libros del Core. Por eso F5 no requiere F1.
struct LibraryStatistics {
    let total: Int
    let byStatus: [ReadingStatus: Int]

    init(books: [Book]) {
        total = books.count
        var counts: [ReadingStatus: Int] = [:]
        for status in ReadingStatus.allCases {
            counts[status] = books.filter { $0.status == status }.count
        }
        byStatus = counts
    }
}
