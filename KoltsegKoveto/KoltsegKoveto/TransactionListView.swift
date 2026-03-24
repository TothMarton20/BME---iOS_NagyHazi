//
//  TransactionListView.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 19..
//

import SwiftUI
import SwiftData


struct TransactionListView: View {
    @Environment(\.modelContext) private var context
    
    // Az összes tranzakció lekérdezése, dátum szerint csökkenő sorrendben
    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]
    
    // Keresőmező szövege
    @State private var searchText = ""
    // Szűrő sheet megjelenítése
    @State private var showFilter = false
    // Szerkesztő sheet megjelenítése
    @State private var showEditSheet = false
    // Melyik tranzakciót szerkesztjük (nil = új tranzakció)
    @State private var selectedTransactionToEdit: Transaction?
    
    // szűrők
    @State private var filterStartDate: Date?
    @State private var filterEndDate: Date?
    @State private var filterCategory: Category?
    @State private var filterCurrency: String?
    
    // Összes törlése alert
    @State private var showDeleteAllAlert = false
    
    // iPad esetére – kiválasztott tranzakció master-detail nézethez
    @Binding var selectedTransaction: Transaction?
    
    // Rendelkezésre álló összeg kézi korrekciója (UserDefaults / AppStorage)
    @AppStorage("balanceAdjustment") private var balanceAdjustment: Double = 0
    
    init(selectedTransaction: Binding<Transaction?> = .constant(nil)) {
        self._selectedTransaction = selectedTransaction
    }
    
    // Elérhető pénznemek a listában – a tranzakciók alapján gyűjtve
    private var availableCurrencies: [String] {
        Array(Set(transactions.map { $0.currencyCode })).sorted()
    }
    
    // Keresés + szűrők együtt alkalmazva az összes tranzakcióra
    private var filteredTransactions: [Transaction] {
        transactions.filter { tx in
            // Szöveges keresés (megjegyzés + kategórianév)
            if !searchText.isEmpty {
                let matchesText =
                    tx.note.localizedCaseInsensitiveContains(searchText) ||
                    tx.category?.name.localizedCaseInsensitiveContains(searchText) == true
                if !matchesText { return false }
            }
            
            // Dátum intervallum: kezdődátum
            if let start = filterStartDate {
                let startOfDay = Calendar.current.startOfDay(for: start)
                if tx.date < startOfDay { return false }
            }
            if let end = filterEndDate {
                let endOfDay = Calendar.current.date(
                    bySettingHour: 23, minute: 59, second: 59, of: end
                ) ?? end
                if tx.date > endOfDay { return false }
            }
            
            // Kategória szűrő
            if let cat = filterCategory {
                if tx.category != cat { return false }
            }
            
            // Pénznem szűrő
            if let curr = filterCurrency, !curr.isEmpty {
                if tx.currencyCode != curr { return false }
            }
            
            return true
        }
    }
    
    var body: some View {
        List {
            if filteredTransactions.isEmpty {
                // Üres lista esetén egy "üres állapot" nézet jelenik meg
                EmptyStateView(
                    systemImage: "tray",
                    title: "Még nincsenek tranzakciók",
                    message: "Hozz létre egy új tranzakciót a jobb felső sarokban található + gombbal."
                )
            } else {
                // Szűrt tranzakciók listája
                ForEach(filteredTransactions) { tx in
                    HStack(spacing: 12) {
                        // Bal oldalt: kategória emoji
                        Text(tx.category?.displayEmoji ?? "🏷️")
                            .font(.title2)

                        // Középen: kategórianév + megjegyzés + dátum
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tx.category?.name ?? "Kategória nélkül")
                                .font(AppFont.body().weight(.semibold))
                            
                            // Megjegyzés a dátum fölött, ha nem üres
                            if !tx.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(tx.note)
                                    .font(AppFont.caption())
                                    .foregroundColor(.secondary)
                            }

                            Text(tx.date.formattedShort())
                                .font(AppFont.caption())
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Jobb oldalt: az összeg formázva, kiadás piros, bevétel zöld
                        Text(rowAmountText(for: tx))
                            .font(AppFont.body().weight(.semibold))
                            .foregroundColor(tx.isExpense ? .red : .green)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Szerkesztés sheet megnyitása a kiválasztott tranzakcióval
                        selectedTransactionToEdit = tx
                        showEditSheet = true
                    }
                }
                // Jobbra húzással törlés
                .onDelete(perform: delete)
            }
        }
        // Beépített keresősáv a listához
        .searchable(text: $searchText, prompt: "Keresés megjegyzés vagy kategória szerint")
        .navigationTitle("Tranzakciók")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showDeleteAllAlert = true
                } label: {
                    Image(systemName: "trash")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    selectedTransactionToEdit = nil
                    showEditSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showFilter.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        // Szerkesztő nézet sheet formában
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                EditTransactionView(transactionToEdit: selectedTransactionToEdit)
            }
        }
        // Szűrő sheet – a FilterSheet külön view-ban van definiálva
        .sheet(isPresented: $showFilter) {
            FilterSheet(
                currentStartDate: filterStartDate,
                currentEndDate: filterEndDate,
                currentCategory: filterCategory,
                currentCurrency: filterCurrency,
                availableCurrencies: availableCurrencies
            ) { start, end, category, currency in
                // Alkalmazott szűrők visszaadása
                filterStartDate = start
                filterEndDate = end
                filterCategory = category
                filterCurrency = currency
            }
        }
        // Összes törlése megerősítő alert
        .alert("Biztosan törölni szeretnéd az összes tranzakciót?",
               isPresented: $showDeleteAllAlert) {

            Button("Mégse", role: .cancel) { }

            Button("Összes törlése", role: .destructive) {
                deleteAllTransactions()
            }
        } message: {
            Text("Ez a művelet nem vonható vissza.")
        }
    }
    

    // Minden tranzakció törlése + egyenleg korrekció alaphelyzetbe
    private func deleteAllTransactions() {
        for tx in transactions {
            context.delete(tx)
        }
        
        // Rendelkezésre álló összeg lenullázása is
        balanceAdjustment = 0

        do {
            try context.save()
        } catch {
            print("Hiba az összes tranzakció törlésekor: \(error)")
        }
    }
    
    // Egy vagy több sor törlése a listából
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(filteredTransactions[index])
        }
        try? context.save()
    }

    
    // Sorban megjelenő összeg formázása (pl. 1 234 Ft jelleggel)
    private func rowAmountText(for tx: Transaction) -> String {
        tx.amount.formattedCurrency(code: tx.currencyCode)
    }
}

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    // Kategóriák lekérése a kategória-szűrő pickerhez
    @Query(sort: \Category.name) private var categories: [Category]
    
    // Belső, ideiglenes állapotok
    @State private var tempUseStartDate: Bool
    @State private var tempStartDate: Date
    @State private var tempUseEndDate: Bool
    @State private var tempEndDate: Date
    @State private var tempSelectedCategory: Category?
    @State private var tempSelectedCurrency: String
    
    // Elérhető pénznemek
    let availableCurrencies: [String]
    
    // Callback: Alkalmaz gomb megnyomásakor ezzel adjuk vissza a kiválasztott szűrőket
    let onApply: (Date?, Date?, Category?, String?) -> Void
    
    init(
        currentStartDate: Date?,
        currentEndDate: Date?,
        currentCategory: Category?,
        currentCurrency: String?,
        availableCurrencies: [String],
        onApply: @escaping (Date?, Date?, Category?, String?) -> Void
    ) {
        // A meglévő beállításokból inicializáljuk az ideiglenes állapotokat
        _tempUseStartDate = State(initialValue: currentStartDate != nil)
        _tempStartDate = State(initialValue: currentStartDate ?? Date())
        _tempUseEndDate = State(initialValue: currentEndDate != nil)
        _tempEndDate = State(initialValue: currentEndDate ?? Date())
        _tempSelectedCategory = State(initialValue: currentCategory)
        _tempSelectedCurrency = State(initialValue: currentCurrency ?? "")
        self.availableCurrencies = availableCurrencies
        self.onApply = onApply
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Időszak szűrő
                Section("Időszak") {
                    Toggle("Kezdődátum használata", isOn: $tempUseStartDate)
                    if tempUseStartDate {
                        DatePicker("Ettől a dátumtól",
                                   selection: $tempStartDate,
                                   displayedComponents: .date)
                    }
                    
                    Toggle("Végdátum használata", isOn: $tempUseEndDate)
                    if tempUseEndDate {
                        DatePicker("Eddig a dátumig",
                                   selection: $tempEndDate,
                                   displayedComponents: .date)
                    }
                    
                    Button("Időszak törlése") {
                        tempUseStartDate = false
                        tempUseEndDate = false
                    }
                    .foregroundColor(.red)
                }
                
                // Kategória szűrő
                Section("Kategória") {
                    Picker("Kategória", selection: $tempSelectedCategory) {
                        Text("Összes kategória").tag(Category?.none)
                        ForEach(categories) { cat in
                            Text(cat.name).tag(Category?.some(cat))
                        }
                    }
                }
                
                // Pénznem szűrő
                Section("Pénznem") {
                    Picker("Pénznem", selection: $tempSelectedCurrency) {
                        Text("Összes pénznem").tag("")
                        ForEach(availableCurrencies, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                }
            }
            .navigationTitle("Szűrők")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Mégse") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Alkalmaz") {
                        let start = tempUseStartDate ? tempStartDate : nil
                        let end = tempUseEndDate ? tempEndDate : nil
                        let currency = tempSelectedCurrency.isEmpty ? nil : tempSelectedCurrency
                        onApply(start, end, tempSelectedCategory, currency)
                        dismiss()
                    }
                }
            }
        }
    }
}
