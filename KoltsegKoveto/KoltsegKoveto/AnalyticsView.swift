//
//  AnalyticsView.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 19..
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    // SwiftData lekérdezés: minden Transaction, dátum szerint csökkenő sorrendben
    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]
    
    // Utolsó "nullázás" időpontja (referenciadátumtól eltelt másodpercben tárolva)
    @AppStorage("analysisResetStartTime") private var analysisResetStartTime: Double = 0
    // User egyedi kezdőidőpontot használ-e az elemzéshez
    @AppStorage("analysisCustomStartEnabled") private var analysisCustomStartEnabled: Bool = false
    // Egyedi elemzési kezdőidőpont (ha engedélyezve van)
    @AppStorage("analysisCustomStartTime") private var analysisCustomStartTime: Double = 0

    // Az elemzés tényleges kezdődátuma, amit a grafikonok és számítások használnak
    private var analysisStartDate: Date {
        if analysisCustomStartEnabled, analysisCustomStartTime > 0 {
            // Ha a user beállított egy saját dátumot, azt használjuk
            return Date(timeIntervalSinceReferenceDate: analysisCustomStartTime)
        } else if analysisResetStartTime > 0 {
            // Különben a legutóbbi nullázás ideje számít
            return Date(timeIntervalSinceReferenceDate: analysisResetStartTime)
        } else {
            // Ha még semmi nincs beállítva, minden tranzakció látszik
            return .distantPast
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Elemzések")
                    .font(AppFont.title())
                
                if transactions.isEmpty {
                    // Üres állapot: nincs mit elemezni
                    EmptyStateView(
                        systemImage: "chart.xyaxis.line",
                        title: "Nincs még adat",
                        message: "Adj hozzá néhány tranzakciót, hogy láss statisztikákat."
                    )
                } else {
                    // Kategória szerinti oszlopdiagram
                    categoryBarChart
                        .cardStyle()
                    // Időbeli alakulást mutató vonaldiagram
                    timeSeriesChart
                        .cardStyle()
                }
            }
            .padding()
        }
        .background(AppColor.background.ignoresSafeArea())
    }
    
    // MARK: - Kategória szerinti oszlopdiagram

    private var categoryBarChart: some View {
        // Előre aggregált adatok: (kategórianév, összeg)
        let aggregated = aggregateByCategory()
        return VStack(alignment: .leading, spacing: 8) {
            Text("Kategóriák szerinti kiadások")
                .font(AppFont.body().weight(.semibold))
            
            Chart(aggregated, id: \.0) { (name, sum) in
                BarMark(
                    x: .value("Összeg", sum),
                    y: .value("Kategória", name)
                )
            }
            .frame(height: 200)
        }
    }
    
    // MARK: - Idősoros vonaldiagram

    private var timeSeriesChart: some View {
        // Előállított idősort adó tömb (ChartEntry: date + value)
        let data = makeTimeSeries()
        return VStack(alignment: .leading, spacing: 8) {
            Text("Időbeli alakulás")
                .font(AppFont.body().weight(.semibold))
            
            Chart(data) { entry in
                LineMark(
                    x: .value("Dátum", entry.date),
                    y: .value("Összeg", entry.value)
                )
            }
            .frame(height: 200)
        }
    }
    
    // MARK: - Adat aggregálás kategória szerint

    private func aggregateByCategory() -> [(String, Double)] {
        // Csak a beállított elemzési kezdőidőponttól számított tranzakciók
        let filtered = transactions.filter { $0.date >= analysisStartDate }
        
        // Csoportosítás kategória szerint, majd kategóriánként a kiadások összege
        let dict = Dictionary(grouping: filtered, by: { $0.category?.name ?? "Ismeretlen" })
            .mapValues { txs in
                // Csak a kiadás jellegű tranzakciók összege
                txs.filter { $0.isExpense }.map(\.amount).reduce(0, +)
            }
        
        // Visszaadjuk csökkenő sorrendben (legnagyobb kiadású kategória elől)
        return dict.sorted { $0.value > $1.value }
    }
    
    // MARK: - Idősor építés (futó egyenleg)

    private func makeTimeSeries() -> [ChartEntry] {
        let calendar = Calendar.current
        let today = Date()
        
        // Utolsó 30 nap dátumai, legrégebbitől a legújabbig
        let days = (0..<30).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }.sorted()
        
        guard let firstDay = days.first else { return [] }
        
        // Csak az elemzés kezdete óta lévő tranzakciók
        let filtered = transactions.filter { $0.date >= analysisStartDate }
        
        // Baseline: ami az elemzés kezdete és az első megjelenített nap KÖZÖTT történt
        // Itt számoljuk ki a kezdeti futó egyenleget, hogy a grafikon ne 0-ról induljon,
        // hanem valós, korábbi mozgásokat is figyelembe vegyen.
        let baseline = filtered
            .filter { $0.date < firstDay }
            .map { $0.isExpense ? -$0.amount : $0.amount }
            .reduce(0, +)
        
        // runningTotal: a futó egyenleg, ami napról napra változik
        var runningTotal = baseline
        
        return days.map { day in
            let dayDelta = filtered
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .map { $0.isExpense ? -$0.amount : $0.amount }
                .reduce(0, +)
            
            runningTotal += dayDelta
            
            // A futó egyenleget rajzoljuk ki a grafikonon
            return ChartEntry(date: day, value: runningTotal)
        }
    }
}
