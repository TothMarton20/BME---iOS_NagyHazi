//
//  KoltsegKovetoWidget.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 24..
//

import WidgetKit
import SwiftUI

// App Group azonosító – ezzel oszt meg adatot az app és a widget
private let appGroupID = "group.hu.tothmarton.KoltsegKoveto"

// A UserDefaults-ben használt kulcs, ahol a widgetnek szánt egyenleg szöveg van tárolva
private let balanceKey = "widgetAvailableBalanceText"

// A widget egy időpillanathoz tartozó adategysége
struct BalanceEntry: TimelineEntry {
    let date: Date
    let balanceText: String
}

// A widget adatszolgáltatója: megmondja, mit mutasson a widget és mikor frissüljön
struct Provider: TimelineProvider {
    // Placeholder: amikor még nincs valódi adat
    func placeholder(in context: Context) -> BalanceEntry {
        BalanceEntry(date: Date(), balanceText: "0 HUF")
    }

    // Snapshot: gyors előnézethez (pl. widget gallery), vagy ha kevés az adat
    func getSnapshot(in context: Context, completion: @escaping (BalanceEntry) -> ()) {
        completion(makeEntry())
    }

    // Timeline: itt adjuk meg az idővonalat, és hogy mikor frissüljön a widget
    func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceEntry>) -> ()) {
        let entry = makeEntry()
        // .never: a widget csak explicit reload hatására frissül
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }

    // Egy BalanceEntry létrehozása a megosztott UserDefaults-ból kiolvasott érték alapján
    private func makeEntry() -> BalanceEntry {
        // Megosztott UserDefaults az App Group segítségével
        let defaults = UserDefaults(suiteName: appGroupID)
        // Ha nincs érték eltárolva, akkor "0 HUF" az alapértelmezett
        let text = defaults?.string(forKey: balanceKey) ?? "0 HUF"
        return BalanceEntry(date: Date(), balanceText: text)
    }
}

// A widget tényleges megjelenése (UI)
struct KoltsegKovetoWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Címke, hogy mit mutat a widget
            Text("Rendelkezésre álló összeg")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Az egyenleg maga, nagyobb, félkövér betűkkel
            Text(entry.balanceText)
                .font(.title2.bold())
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .padding()
    }
}

// A widget belépési pontja – itt regisztráljuk a widgetet az iOS felé
@main
struct KoltsegKovetoWidget: Widget {
    // A widget egyedi azonosítója
    let kind: String = "KoltsegKovetoWidget"

    var body: some WidgetConfiguration {
        // Statikus konfiguráció: nincs többféle intent / beállítás per widget példa
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            KoltsegKovetoWidgetEntryView(entry: entry)
        }
        // A widget neve a widgetválasztóban
        .configurationDisplayName("Költségkövető")
        // Rövid leírás a widgetválasztóban
        .description("Megjeleníti a rendelkezésre álló összeget.")
        // Milyen méretekben érhető el a widget
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
