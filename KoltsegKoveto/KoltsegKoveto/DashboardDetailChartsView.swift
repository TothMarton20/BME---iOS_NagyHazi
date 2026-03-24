//
//  DashboardDetailChartsView.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 19..
//

import SwiftUI
import SwiftData
import Charts

struct DashboardDetailChartsView: View {
    // Minden tranzakció lekérdezése SwiftData-ból, dátum szerint csökkenő sorrendben
    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]
    
    // Elemzés nullázásának időpontja (referenciadátumtól eltelt másodpercben)
    @AppStorage("analysisResetStartTime") private var analysisResetStartTime: Double = 0
    // Saját (custom) elemzési kezdőidőpont engedélyezve van-e
    @AppStorage("analysisCustomStartEnabled") private var analysisCustomStartEnabled: Bool = false
    // Saját elemzési kezdőidőpont
    @AppStorage("analysisCustomStartTime") private var analysisCustomStartTime: Double = 0

    // A tényleges elemzési kezdődátum, amit minden számítás használ
    private var analysisStartDate: Date {
        if analysisCustomStartEnabled, analysisCustomStartTime > 0 {
            // Ha a user beállított egy saját dátumot, azt használjuk
            return Date(timeIntervalSinceReferenceDate: analysisCustomStartTime)
        } else if analysisResetStartTime > 0 {
            // Különben a legutóbbi nullázás ideje számít
            return Date(timeIntervalSinceReferenceDate: analysisResetStartTime)
        } else {
            return .distantPast
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Részletes grafikonok")
                    .font(AppFont.title(26))
                
                // Interaktív oszlopdiagram, amely a makeChartData-t használja inputként
                InteractiveBarChartView(data: makeChartData)
                    .cardStyle()
            }
            .padding()
        }
        .background(AppColor.background.ignoresSafeArea())
    }
    
    // MARK: - Grafikon adatok előállítása

    // A hónapra vonatkozó, baseline-hoz képest számolt futó egyenleg idősor
    private var makeChartData: [ChartEntry] {
        let calendar = Calendar.current
        let now = Date()
        
        // Aktuális hónap első napjának kiszámítása
        let comps = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: comps) else { return [] }
        
        let effectiveStart = max(startOfMonth, analysisStartDate)
        
        // Napok listája az effektív kezdettől a mai napig
        var days: [Date] = []
        var current = effectiveStart
        while current <= now {
            days.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        
        let baseline = transactions
            .filter { $0.date < effectiveStart }
            .map { $0.isExpense ? -$0.amount : $0.amount }
            .reduce(0, +)
        
        // runningTotal: az aktuális futó egyenleg a baseline-hoz képest
        var runningTotal = baseline
        
        return days.map { day in
            // Az adott napra eső „mozgás” (bevételek - kiadások)
            let dayDelta = transactions
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .map { $0.isExpense ? -$0.amount : $0.amount }
                .reduce(0, +)
            
            runningTotal += dayDelta
            
            return ChartEntry(date: day, value: runningTotal - baseline)
        }
    }
}
