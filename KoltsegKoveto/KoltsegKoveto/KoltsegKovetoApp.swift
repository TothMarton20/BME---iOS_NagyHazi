//
//  KoltsegKovetoApp.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 19..
//

import SwiftUI
import SwiftData

@main
struct KoltsegKovetoApp: App {
    var body: some Scene {
        WindowGroup {
            // Az app belépési pontja – innen indul minden UI
            RootView()
        }
        // SwiftData modellek regisztrálása:
        // ezekből lesz adatbázis-tábla, query, stb.
        .modelContainer(for: [Transaction.self, Category.self])
    }
}
