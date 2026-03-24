//
//  InteractiveBarChartView.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 19..
//

import SwiftUI
import Charts

// Egyszerű adatmodell egy grafikon ponthoz / oszlophoz:
// egy dátum + ahhoz tartozó érték
struct ChartEntry: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// Interaktív oszlopdiagram: ha ráböksz egy elemre, felül megjelenik a részlete
struct InteractiveBarChartView: View {
    let data: [ChartEntry]
    @State private var selectedEntry: ChartEntry?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Fejléc: ha van kijelölt oszlop, azt mutatjuk, különben egy sima cím
            if let selected = selectedEntry {
                Text("Kiválasztott: \(selected.date.formattedShort()) – \(Int(selected.value)) Ft")
                    .font(AppFont.caption())
                    .foregroundStyle(.secondary)
            } else {
                Text("Havi trend")
                    .font(AppFont.body().weight(.semibold))
            }
            
            Chart(data) { entry in
                BarMark(
                    x: .value("Dátum", entry.date, unit: .day),
                    y: .value("Összeg", entry.value)
                )
                .foregroundStyle(AppColor.primary)
                .cornerRadius(4)
            }
            .chartXAxis {
                // X tengelyen 7 napos lépésekkel jelenítjük meg a dátumokat
                AxisMarks(values: .stride(by: .day, count: 7))
            }
            .frame(height: 180)
        }
    }
}
