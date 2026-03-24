//
//  Rootview.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 19..
//

import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

struct RootView: View {
    // A SwiftData ModelContext, ezen keresztül tudunk olvasni/írni az adatbázisba
    @Environment(\.modelContext) private var context
    
    // A Category típusú objektumok lekérése az adatbázisból
    @Query private var categories: [Category]
    
    var body: some View {
        Group {
            // iOS specifikus kód – ellenőrizzük, hogy milyen eszközön fut az app
            #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad esetén iPad-re optimalizált root nézet
                iPadRootView()
            } else {
                // iPhone (vagy iPod touch) esetén iPhone nézet
                iPhoneRootView()
            }
            #else
            iPhoneRootView()
            #endif
        }
        .onAppear {
            // Amikor a RootView megjelenik, létrehozunk alapértelmezett kategóriákat, ha még nincsenek
            seedDefaultCategoriesIfNeeded()
        }
    }
    
    // Alapértelmezett kategóriák feltöltése, ha még egy sincs az adatbázisban
    private func seedDefaultCategoriesIfNeeded() {
        // Ha már vannak kategóriák, nem csinálunk semmit
        guard categories.isEmpty else { return }
        
        // Alapértelmezett költés/bevétel kategóriák definiálása
        let defaults: [Category] = [
            Category(name: "Étel",        iconSystemName: "🍽️"),
            Category(name: "Közlekedés",  iconSystemName: "🚆"),
            Category(name: "Lakhatás",    iconSystemName: "🏠"),
            Category(name: "Szórakozás",  iconSystemName: "🎮"),
            Category(name: "Fizetés",     iconSystemName: "💰", isExpense: false)
        ]
        
        // Az alapértelmezett kategóriák beszúrása a SwiftData context-be
        for c in defaults {
            context.insert(c)
        }
        
        // A módosítások mentése
        try? context.save()
    }
}
