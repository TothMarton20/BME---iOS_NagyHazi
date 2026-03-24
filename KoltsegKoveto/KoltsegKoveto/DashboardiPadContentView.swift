//
//  DashboardiPadContentView.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 19..
//

import SwiftUI
import SwiftData

struct DashboardiPadContentView: View {
    // iPaden a fő nézet kívülről kapja, hogy mutassa-e az új tranzakció sheetet
    @Binding var showNewTransactionSheet: Bool
    
    // Minden tranzakció, dátum szerint csökkenő sorrendben
    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]
    
    // Utolsó 14 nap napi egyenlege (bevétel – kiadás), ChartEntry-be rendezve
    private var chartData: [ChartEntry] {
        let calendar = Calendar.current
        let days = (0..<14).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: .now)
        }.reversed()
        return days.map { day in
            let sum = transactions
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .map { $0.isExpense ? -$0.amount : $0.amount }
                .reduce(0, +)
            return ChartEntry(date: day, value: sum)
        }
    }
    
    var body: some View {
        ScrollView {
            // Két oszlopos rács elrendezés iPadre optimalizálva
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                      spacing: 20) {
                DashboardSummaryCard(transactions: transactions)
                DashboardQuickAddCard(showNewTransactionSheet: $showNewTransactionSheet)
                DashboardTrendCard(data: chartData)
                DashboardCategoryCard(transactions: transactions)
            }
            .padding()
        }
        .background(AppColor.background.ignoresSafeArea())
    }
}

// MARK: - Havi összegző kártya

struct DashboardSummaryCard: View {
    let transactions: [Transaction]
    
    // Aktuális hónap kiadásainak összege
    var monthExpense: Double {
        let comp = Calendar.current.dateComponents([.year, .month], from: .now)
        let start = Calendar.current.date(from: comp) ?? .now
        return transactions
            .filter { $0.isExpense && $0.date >= start }
            .map(\.amount)
            .reduce(0, +)
    }
    
    // Aktuális hónap bevételeinek összege
    var monthIncome: Double {
        let comp = Calendar.current.dateComponents([.year, .month], from: .now)
        let start = Calendar.current.date(from: comp) ?? .now
        return transactions
            .filter { !$0.isExpense && $0.date >= start }
            .map(\.amount)
            .reduce(0, +)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Havi összegzés")
                .font(AppFont.title(22))
            HStack {
                // Kiadás blokk
                VStack(alignment: .leading, spacing: 8) {
                    Text("Kiadás")
                        .font(AppFont.caption())
                        .foregroundStyle(.secondary)
                    Text("-\(Int(monthExpense)) Ft")
                        .foregroundStyle(AppColor.negative)
                        .font(AppFont.title(24))
                }
                Spacer()
                // Bevétel blokk
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bevétel")
                        .font(AppFont.caption())
                        .foregroundStyle(.secondary)
                    Text("+\(Int(monthIncome)) Ft")
                        .foregroundStyle(AppColor.positive)
                        .font(AppFont.title(24))
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Gyors műveletek kártya

struct DashboardQuickAddCard: View {
    @Binding var showNewTransactionSheet: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gyors műveletek")
                .font(AppFont.title(22))
            
            // Fő CTA gomb új tranzakcióhoz
            PrimaryButton(title: "Új tranzakció", systemImage: "plus.circle.fill") {
                showNewTransactionSheet = true
            }
            
            HStack {
                ChipView(title: "Étel", systemImage: "fork.knife") {
                    showNewTransactionSheet = true
                }
                ChipView(title: "Közlekedés", systemImage: "tram.fill") {
                    showNewTransactionSheet = true
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Trend kártya (14 napos idősor)

struct DashboardTrendCard: View {
    let data: [ChartEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Időbeli trend")
                .font(AppFont.title(22))
            InteractiveBarChartView(data: data)
        }
        .cardStyle()
    }
}

// MARK: - Top kategóriák kártya

struct DashboardCategoryCard: View {
    let transactions: [Transaction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top kategóriák")
                .font(AppFont.title(22))
            
            let list = topCategories()
            if list.isEmpty {
                // Ha nincs még adat
                Text("Még nincsenek tranzakciók.")
                    .foregroundStyle(.secondary)
            } else {
                // Top 5 kategória kiírása
                ForEach(list, id: \.0) { (name, sum) in
                    HStack {
                        Text(name)
                        Spacer()
                        Text("\(Int(sum)) Ft")
                    }
                    .font(AppFont.body())
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: Top kategóriák kiszámítása
    private func topCategories() -> [(String, Double)] {
        let dict = Dictionary(grouping: transactions, by: { $0.category?.name ?? "Ismeretlen" })
            .mapValues { txs in
                txs.map { $0.isExpense ? $0.amount : -$0.amount }.reduce(0, +)
            }
        return dict
            // abszolút érték alapján sorbarendezve (legnagyobb mozgatott összeg felül)
            .sorted { abs($0.value) > abs($1.value) }
            // csak az első 5 kategória
            .prefix(5)
            .map { ($0.key, $0.value) }
    }
}
