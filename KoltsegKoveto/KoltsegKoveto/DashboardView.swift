//
//  DashboardView.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 19..
//

import SwiftUI
import SwiftData
import Charts
import WidgetKit

// Egy kategória részesedését leíró struktúra a kördiagramhoz
struct CategoryShare: Identifiable {
    let id = UUID()
    let name: String
    let total: Double
    let percentage: Double
}

struct DashboardView: View {
    // App Group az app–widget közti megosztott UserDefaults-hoz
    private let appGroupID = "group.hu.tothmarton.KoltsegKoveto"
    
    // Fő képernyőről felugró "új tranzakció" sheet vezérlése
    @Binding var showNewTransactionSheet: Bool
    
    // Összes tranzakció, dátum szerint csökkenő sorrendben
    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]
    
    // Alap pénznem beállítás (UserDefaults/AppStorage)
    @AppStorage("baseCurrency") private var baseCurrency: String = "HUF"
    
    // Manuális korrekció az egyenleghez (pl. készpénz különbség)
    @AppStorage("balanceAdjustment") private var balanceAdjustment: Double = 0
    
    // Elemzés kezdőpontja: nullázás / egyéni dátum
    @AppStorage("analysisResetStartTime") private var analysisResetStartTime: Double = 0
    @AppStorage("analysisCustomStartEnabled") private var analysisCustomStartEnabled: Bool = false
    @AppStorage("analysisCustomStartTime") private var analysisCustomStartTime: Double = 0
    
    // Összes kategória listázása név szerint
    @Query(sort: \Category.name)
    private var categories: [Category]
    
    // Gyors hozzáadásnál kiválasztott kategória (sheet-et is ez vezérli)
    @State private var quickAddCategory: Category?

    // Elemzés tényleges kezdődátuma a beállítások alapján
    private var analysisStartDate: Date {
        if analysisCustomStartEnabled, analysisCustomStartTime > 0 {
            // Ha a user egyéni dátumot állított be, azt használjuk
            return Date(timeIntervalSinceReferenceDate: analysisCustomStartTime)
        } else if analysisResetStartTime > 0 {
            // Ha volt "nullázás", akkor attól az időponttól számolunk
            return Date(timeIntervalSinceReferenceDate: analysisResetStartTime)
        } else {
            // Nincs semmi beállítva → minden tranzakciót számolunk
            return .distantPast
        }
    }
    
    // MARK: - Gyors hozzáadás szekció
    
    // Gyors, kategória alapú tranzakció felvétel UI
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gyors hozzáadás")
                .font(AppFont.body().weight(.semibold))
            
            if categories.isEmpty {
                Text("Még nincs kategória beállítva.")
                    .font(AppFont.caption())
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories) { category in
                            Button {
                                // Kategória kiválasztása → sheet megnyitása
                                quickAddCategory = category
                            } label: {
                                HStack(spacing: 6) {
                                    Text(category.displayEmoji)
                                        .font(.title3)
                                    Text(category.name)
                                        .font(AppFont.caption())
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
    
    
    // Rendelkezésre álló összeg szöveges formában (megosztáshoz)
    private var shareAvailableBalanceText: String {
        // Összes tranzakció végigiterálása, kiadás mínusz, bevétel plusz
        let total: Double = transactions.reduce(0.0) { partial, tx in
            let amount = Double(tx.amount)
            let signed = tx.isExpense ? -amount : amount
            return partial + signed
        } + balanceAdjustment

        return total.formattedCurrency(code: baseCurrency)
    }

    // Tranzakciók, amelyek az elemzés kezdete óta történtek (megosztáshoz)
    private var recentTransactionsForShare: [Transaction] {
        transactions.filter { $0.date >= analysisStartDate }
    }

    // Kiadások kategóriánként az elemzés kezdete óta (megosztáshoz)
    private var categoryExpensesForShare: [(name: String, amount: Double)] {
        // Csak kiadások, elemzés kezdete óta
        let filtered = transactions.filter { $0.isExpense && $0.date >= analysisStartDate }

        // Csoportosítás kategória név szerint, összegzés
        let dict = Dictionary(grouping: filtered, by: { $0.category?.name ?? "Ismeretlen" })
            .mapValues { txs in
                txs.map(\.amount).reduce(0, +)
            }

        // Tuple lista név–összeg párokkal, összeg szerint csökkenő sorrendben
        return dict
            .map { (name: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
    

    // A ShareLink-hez használt teljes szöveges összefoglaló
    private var shareSummaryText: String {
        var lines: [String] = []

        lines.append("Irányítópult összefoglaló")
        lines.append("")
        lines.append("Rendelkezésre álló összeg: \(shareAvailableBalanceText)")
        lines.append("Elemzések kezdete: \(analysisStartDate.formatted(date: .abbreviated, time: .omitted))")
        lines.append("")

        // Tranzakciók listázása időrendben
        lines.append("Tranzakciók a grafikon nullázása óta:")
        if recentTransactionsForShare.isEmpty {
            lines.append(" – Nincs tranzakció.")
        } else {
            for tx in recentTransactionsForShare.sorted(by: { $0.date < $1.date }) {
                let dateStr = tx.date.formatted(date: .abbreviated, time: .omitted)
                let categoryName = tx.category?.name ?? "Kategória nélkül"
                let sign = tx.isExpense ? "-" : "+"
                let amountText = tx.amount.formattedCurrency(code: tx.currencyCode)
                let notePart = tx.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? ""
                    : " (\(tx.note))"

                lines.append(" – \(dateStr): \(categoryName) \(sign)\(amountText)\(notePart)")
            }
        }

        lines.append("")
        lines.append("Kiadások kategóriánként a grafikon nullázása óta:")

        if categoryExpensesForShare.isEmpty {
            lines.append(" – Nincs kiadás.")
        } else {
            for item in categoryExpensesForShare {
                let amountText = item.amount.formattedCurrency(code: baseCurrency)
                lines.append(" – \(item.name): \(amountText)")
            }
        }

        return lines.joined(separator: "\n")
    }
    
    
    // MARK: - NAPI / HAVI ÖSSZESÍTÉSEK – widgethez, statisztikákhoz
    
    // Napi nettó összeg (bevétel – kiadás) az adott napra, widgethez
    private var todayTotal: Double {
        let calendar = Calendar.current
        return transactions
            .filter { calendar.isDateInToday($0.date) }
            .map { $0.isExpense ? -$0.amount : $0.amount }
            .reduce(0, +)
    }
    
    // Aktuális hónap összesített kiadása
    private var monthTotalExpense: Double {
        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: comps) else { return 0 }
        
        return transactions
            .filter { $0.isExpense && $0.date >= startOfMonth }
            .map { $0.amount }
            .reduce(0, +)
    }
    
    // Aktuális hónap összesített bevétele
    private var monthTotalIncome: Double {
        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: comps) else { return 0 }
        
        return transactions
            .filter { !$0.isExpense && $0.date >= startOfMonth }
            .map { $0.amount }
            .reduce(0, +)
    }
    
    // Rendelkezésre álló teljes egyenleg: összes bevétel – összes kiadás + korrekció
    private var availableBalance: Double {
        let total: Double = transactions.reduce(0.0) { partial, tx in
            let amount = Double(tx.amount)
            let signed = tx.isExpense ? -amount : amount
            return partial + signed
        }

        return total + balanceAdjustment
    }
    
    // Kiadások megoszlása kategóriák szerint (kördiagram adatforrása)
    private var categoryShares: [CategoryShare] {
        // Csak a kiadások, és csak az elemzés kezdete óta
        let expenseTransactions = transactions.filter {
            $0.isExpense && $0.date >= analysisStartDate
        }
        
        // Csoportosítás kategóriák szerint
        let grouped = Dictionary(grouping: expenseTransactions) { tx in
            tx.category?.name ?? "Egyéb"
        }

        // Összegzés kategóriánként
        var shares: [CategoryShare] = []

        // Kategóriánkénti összesítés lista formában
        let totalsPerCategory: [(String, Double)] = grouped.map { name, txs in
            let sum = txs.reduce(0.0) { partial, tx in
                partial + Double(tx.amount)
            }
            return (name, sum)
        }

        // Összes kiadás a százalékokhoz
        let grandTotal = totalsPerCategory.reduce(0.0) { $0 + $1.1 }

        // CategoryShare objektumok létrehozása
        for (name, sum) in totalsPerCategory {
            let percent = grandTotal > 0 ? (sum / grandTotal * 100.0) : 0
            shares.append(
                CategoryShare(name: name, total: sum, percentage: percent)
            )
        }

        // Rendezés összeg szerint csökkenő sorrendben
        return shares.sorted { $0.total > $1.total }
    }
    
    // MARK: Kiadások megoszlását megjelenítő kördiagram szekció
    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kiadások megoszlása")
                .font(AppFont.body().weight(.semibold))

            if categoryShares.isEmpty {
                Text("Még nincs elég adat a diagramhoz.")
                    .font(AppFont.caption())
                    .foregroundStyle(.secondary)
            } else {
                Chart(categoryShares) { share in
                    SectorMark(
                        angle: .value("Összeg", share.total),
                        innerRadius: .ratio(0.6)   // „fánk” diagram
                    )
                    .foregroundStyle(by: .value("Kategória", share.name))
                    .annotation(position: .overlay) {
                        // Csak a nagyobb szeletekre írjuk ki a százalékot
                        if share.percentage >= 5 {
                            Text("\(share.name) \(Int(share.percentage))%")
                                .font(.caption2)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(height: 240)
                .chartLegend(.visible)
            }
        }
        .cardStyle()
    }
    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                chartsSection
                quickAddSection
                recentTransactionsSection
            }
            .padding()
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("Irányítópult")
        .toolbar {
            // Összefoglaló megosztása (szöveges riport)
            ToolbarItem(placement: .topBarLeading) {
                ShareLink(item: shareSummaryText) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            
            // Új tranzakció felvétel gomb
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showNewTransactionSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        // Napi összeg mentése widgetnek
        .onAppear {
            saveTodayTotalToSharedDefaults()
        }
        .onChange(of: todayTotal) { _ in
            saveTodayTotalToSharedDefaults()
        }
        // Widget egyenleg frissítése megjelenéskor és változáskor
        .onAppear {
            updateWidgetBalance()
        }
        .onChange(of: transactions) { _ in
            updateWidgetBalance()
        }
        .onChange(of: balanceAdjustment) { _ in
            updateWidgetBalance()
        }
        // Gyors hozzáadás sheet
        .sheet(item: $quickAddCategory) { category in
            QuickAddTransactionView(category: category, baseCurrency: baseCurrency)
        }
    }
    
    // MARK: - Helper függvények
    
    // Widgetben megjelenő egyenleg frissítése App Group UserDefaults-ban
    private func updateWidgetBalance() {
        let text = availableBalance.formattedCurrency(code: baseCurrency)
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(text, forKey: "widgetAvailableBalanceText")
        
        // Widget idővonal frissítése
        WidgetCenter.shared.reloadTimelines(ofKind: "KoltsegKovetoWidget")
    }
    
    // Felső fejléc nézet: dátum + elérhető egyenleg
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date().formattedShort())
                .font(AppFont.caption())
                .foregroundStyle(.secondary)

            Text("Rendelkezésre álló összeg")
                .font(AppFont.title())

            // Itt jelenik meg a kiszámolt egyenleg
            Text(availableBalance, format: .currency(code: baseCurrency))
                .font(AppFont.title(32))
                .foregroundColor(.primary)
        }
    }
    
    // Egyszerű "kártya" összeg megjelenítéséhez (ha később használod)
    private func totalCard(title: String, value: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(AppFont.caption())
            }
            .foregroundStyle(.secondary)
            
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
        }
    }
    
    // Napi összeg mentése a widget számára megosztott UserDefaults-ba
    private func saveTodayTotalToSharedDefaults() {
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(todayTotal, forKey: "todayTotal")
    }
    
    // Legutóbbi tranzakciók szekció, max. 5 elem + link az összeshez
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Legutóbbi tranzakciók")
                    .font(AppFont.body().weight(.semibold))
                Spacer()
                NavigationLink("Összes", destination: TransactionListView())
            }

            if transactions.isEmpty {
                EmptyStateView(
                    systemImage: "tray",
                    title: "Nincs még tranzakció",
                    message: "A + gombbal vehetsz fel új tranzakciót."
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(transactions.prefix(5)) { tx in
                        TransactionRowView(transaction: tx)
                        Divider()
                    }
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Gyors tranzakció felvétel nézet (sheet)

struct QuickAddTransactionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    let category: Category
    let baseCurrency: String
    
    @State private var amountText: String = ""
    @State private var showValidationError = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Kiválasztott kategória megjelenítése
                Section {
                    HStack {
                        Text(category.displayEmoji)
                            .font(.title2)
                        Text(category.name)
                            .font(AppFont.body().weight(.semibold))
                    }
                }
                
                // Összeg megadása
                Section("Összeg") {
                    TextField("Pl. 2500", text: $amountText)
                        .keyboardType(.decimalPad)
                    
                    Text("Pénznem: \(baseCurrency)")
                        .font(AppFont.caption())
                        .foregroundStyle(.secondary)
                    
                    if showValidationError {
                        Text("Adj meg egy 0-nál nagyobb összeget.")
                            .font(AppFont.caption())
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Gyors hozzáadás")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Mégse") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Mentés") { save() }
                }
            }
        }
    }
    
    // Tranzakció mentése az adatbázisba
    private func save() {
        // Számformátum normalizálása (szóköz, vessző → pont)
        let normalized = amountText
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        
        // Érvényes, 0-nál nagyobb összeg ellenőrzése
        guard let value = Double(normalized), value > 0 else {
            showValidationError = true
            return
        }
        
        // Új tranzakció létrehozása a kiválasztott kategóriához
        let tx = Transaction(
            date: Date(),
            amount: value,
            isExpense: category.isExpense,
            note: "",
            currencyCode: baseCurrency,
            category: category
        )
        
        context.insert(tx)
        try? context.save()
        dismiss()
    }
}
