// swift-tools-version: 6.2
// Paquete para Linux y Windows. Compila la MISMA carpeta Netanbook/ que usa Xcode
// (en Mac se abre Netanbook.xcodeproj y se usa el SwiftUI de Apple).
import PackageDescription

#if os(Linux)
let backend: Target.Dependency = .product(name: "BackendGTK4", package: "SwiftOpenUI")
#elseif os(Windows)
let backend: Target.Dependency = .product(name: "BackendWin32", package: "SwiftOpenUI")
#else
let backend: Target.Dependency? = nil
#endif

let package = Package(
    name: "Netanbook",
    // Productos de la línea: cada trait activo es una variable de compilación.
    //   swift run Netanbook                     → producto base (solo Core)
    //   swift run --traits Progreso Netanbook   → Netanbook Progreso (#if Progreso)
    //   swift run --traits Notas,Prestamos Netanbook → con F2 y O2 (#if Notas, #if Prestamos)
    //   swift run --traits Categorias Netanbook → con F3 (#if Categorias)
    //   swift run --traits Valoraciones,ObjetivoAnual Netanbook → con F4 y O4 (#if Valoraciones, #if ObjetivoAnual)
    //   swift run --traits Estadisticas Netanbook → con F5 (#if Estadisticas)
    //   swift run --traits SesionesLectura Netanbook → con O1 y, por la restricción
    //     «O1 requires F1», también con F1 (#if SesionesLectura, #if Progreso)
    //   swift run --traits AltaISBN Netanbook → con O3 (#if AltaISBN); usa la red
    // Los traits se combinan: --traits Progreso,Notas,Categorias,Valoraciones,Estadisticas,SesionesLectura,Prestamos,AltaISBN,ObjetivoAnual.
    // En Xcode, el mismo papel lo cumplen los targets «Netanbook Progreso»,
    // «Netanbook Notas», «Netanbook Categorias», «Netanbook Prestamos» y
    // «Netanbook AltaISBN».
    traits: [
        .trait(name: "Progreso", description: "F1 Progreso: páginas leídas de cada libro"),
        .trait(name: "Notas", description: "F2 Notas y citas: anotaciones de cada libro"),
        .trait(name: "Categorias", description: "F3 Categorías: crear categorías, asignarlas a los libros y filtrar"),
        .trait(name: "Valoraciones", description: "F4 Valoraciones y reseñas: puntuación y reseña de cada libro"),
        .trait(name: "Estadisticas", description: "F5 Estadísticas: total de libros y número de libros en cada estado"),
        // O1 requires F1: activar SesionesLectura activa también Progreso.
        .trait(
            name: "SesionesLectura",
            description: "O1 Sesiones de lectura: iniciar y terminar sesiones con su duración y sus páginas (requiere F1)",
            enabledTraits: ["Progreso"]
        ),
        .trait(name: "Prestamos", description: "O2 Préstamos: a quién se ha prestado cada libro"),
        .trait(name: "AltaISBN", description: "O3 Alta por ISBN: rellenar título y autor desde Open Library"),
        .trait(name: "ObjetivoAnual", description: "O4 Objetivo anual: meta de libros al año y fecha de finalización"),
    ],
    dependencies: [
        .package(url: "https://github.com/uallps/SwiftOpenUI.git", branch: "uallps"),
    ],
    targets: [
        // Sustituye al SwiftUI de Apple: `import SwiftUI` trae SwiftOpenUI y su backend.
        .target(
            name: "SwiftUI",
            dependencies: [.product(name: "SwiftOpenUI", package: "SwiftOpenUI")] + [backend].compactMap { $0 },
            path: "Compat/SwiftUI"
        ),
        // Mismos ajustes de Swift que el proyecto de Xcode.
        .executableTarget(
            name: "Netanbook",
            dependencies: ["SwiftUI"],
            path: "Netanbook",
            exclude: ["Assets.xcassets"],
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
                .enableUpcomingFeature("MemberImportVisibility"),
            ]
        ),
        // Pruebas del ViewModel con MockBookStorageProvider: `swift test`.
        .testTarget(
            name: "NetanbookTests",
            dependencies: ["Netanbook"],
            path: "Tests/NetanbookTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)