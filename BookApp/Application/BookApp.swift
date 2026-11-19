//
//  BookApp.swift
//  BookApp · Netanbook
//
//  Punto de entrada. En Mac usa el SwiftUI de Apple; en Linux y Windows,
//  el módulo SwiftUI de Compat/ (SwiftOpenUI), sin cambiar el código.
//

import SwiftUI

@main
struct BookApp: App {
    var body: some Scene {
        WindowGroup {
            BookListView()
        }
    }
}
