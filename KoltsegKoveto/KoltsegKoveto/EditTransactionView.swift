//
//  EditTransactionView.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 19..
//

import SwiftUI
import SwiftData
import PhotosUI

#if canImport(UIKit)
import UIKit
#endif

struct EditTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    // Összes kategória lekérdezése (Pickerhez)
    @Query private var categories: [Category]
    
    // Ha nil → új tranzakció, ha nem nil → szerkesztés
    var transactionToEdit: Transaction?
    
    // UI állapot
    @State private var selectedCategory: Category?
    @State private var isExpense: Bool = true
    @State private var amountText: String = ""
    @State private var currencyCode: String = "HUF"
    @State private var date: Date = .now
    @State private var note: String = ""
    @State private var recurrence: Recurrence = .none
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var receiptImageData: Data?
    
    // Árfolyamok HUF-hoz (widget / app beállításokból)
    @AppStorage("eurToHufRate") private var eurToHufRate: Double = 0
    @AppStorage("usdToHufRate") private var usdToHufRate: Double = 0
    
    // Eredeti deviza adatok megőrzéséhez (ha nem HUF-ban jött)
    var originalAmount: Double?
    var originalCurrencyCode: String?

    @State private var selectedCurrency: String = "HUF"
    
    init(transactionToEdit: Transaction? = nil) {
        self.transactionToEdit = transactionToEdit
        // Ha szerkesztünk, előtöltjük a mezőket a meglévő tranzakció adataival
        if let tx = transactionToEdit {
            _selectedCategory = State(initialValue: tx.category)
            _isExpense = State(initialValue: tx.isExpense)
            _amountText = State(initialValue: "\(Int(tx.amount))")
            _currencyCode = State(initialValue: tx.currencyCode)
            _date = State(initialValue: tx.date)
            _note = State(initialValue: tx.note)
            _recurrence = State(initialValue: tx.recurrence)
            _receiptImageData = State(initialValue: tx.receiptImageData)
        }
    }
    
    var body: some View {
        Form {
            // Összeg + deviza + típus
            Section("Összeg") {
                TextField("Összeg", text: $amountText)
                    .keyboardType(.decimalPad)
                
                Picker("Pénznem", selection: $currencyCode) {
                    Text("HUF").tag("HUF")
                    Text("EUR").tag("EUR")
                    Text("USD").tag("USD")
                }
                
                Picker("Típus", selection: $isExpense) {
                    Text("Kiadás").tag(true)
                    Text("Bevétel").tag(false)
                }
                .pickerStyle(.segmented)
            }
            
            // Kategória választó
            Section("Kategória") {
                Picker("Kategória", selection: $selectedCategory) {
                    Text("Nincs").tag(Category?.none)
                    ForEach(categories) { cat in
                        Text(cat.name).tag(Category?.some(cat))
                    }
                }
            }
            .onChange(of: selectedCategory) { newCategory in
                // Ha kiválasztunk egy kategóriát, annak típusát átvesszük (kiadás/bevétel)
                if let cat = newCategory {
                    isExpense = cat.isExpense
                }
            }
            
            // Megjegyzés
            Section("Megjegyzés") {
                TextField("Megjegyzés", text: $note, axis: .vertical)
            }
            
            // Dátum
            Section("Dátum") {
                DatePicker("Dátum", selection: $date, displayedComponents: .date)
            }
            
            // Ismétlődés (pl. havi, éves, stb.)
            Section("Ismétlődés") {
                Picker("Ismétlődés", selection: $recurrence) {
                    ForEach(Recurrence.allCases) { rec in
                        Text(rec.localizedName).tag(rec)
                    }
                }
            }
            
            // Nyugta fotó hozzácsatolása
            Section("Nyugta fotó") {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Fotó kiválasztása")
                    }
                }
                
                // Ha már van elmentett kép, megjelenítjük
                if let data = receiptImageData,
                   let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .navigationTitle(transactionToEdit == nil ? "Új tranzakció" : "Tranzakció szerkesztése")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Mégse") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Mentés") {
                    save()
                }
            }
        }
        // Fotó beolvasása aszinkron módon, ha kiválasztottunk egyet
        .task(id: selectedPhoto) {
            if let item = selectedPhoto {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    receiptImageData = data
                }
            }
        }
    }
    
    // MARK: - Mentés logika
    
    private func save() {
        // Összeg parse-olása (szóközök nélkül, vessző → pont)
        let normalized = amountText
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        
        guard let rawAmount = Double(normalized), rawAmount > 0 else {
            // Ha érvénytelen az összeg, egyszerűen kilépünk
            dismiss()
            return
        }
        
        // Átváltás HUF-ra, minden HUF-ban kerül tárolásra
        let (amountHUF, originalAmount, originalCurrency) =
            convertToHUF(value: rawAmount, currency: currencyCode)
        
        if let tx = transactionToEdit {
            tx.amount = amountHUF
            tx.isExpense = isExpense
            tx.currencyCode = "HUF"            // belső tárolás mindig HUF-ban
            tx.date = date
            tx.note = note
            tx.recurrence = recurrence
            tx.category = selectedCategory
            tx.receiptImageData = receiptImageData
            
            // csak akkor lesz érték, ha nem HUF-ban vittük fel
            tx.originalAmount = originalAmount
            tx.originalCurrencyCode = originalCurrency
            
        } else {
            // ÚJ tranzakció létrehozása
            let newTx = Transaction(
                date: date,
                amount: amountHUF,
                isExpense: isExpense,
                note: note,
                currencyCode: "HUF",
                recurrence: recurrence,
                category: selectedCategory,
                receiptImageData: receiptImageData
            )
            
            // eredeti deviza adatok elmentése
            newTx.originalAmount = originalAmount
            newTx.originalCurrencyCode = originalCurrency
            
            context.insert(newTx)
        }
        
        try? context.save()
        dismiss()
    }
    
    // MARK: - Deviza → HUF konverzió
    
    private func convertToHUF(value: Double, currency: String) -> (Double, Double?, String?) {
        switch currency {
        case "EUR":
            guard eurToHufRate > 0 else {
                // Ha nincs beállított árfolyam, fallback: mintha HUF lenne (nem szorozzuk)
                return (value, nil, nil)
            }
            let huf = value * eurToHufRate
            return (huf, value, "EUR")
            
        case "USD":
            guard usdToHufRate > 0 else {
                // Ugyanaz a fallback logika, mint EUR-nál
                return (value, nil, nil)
            }
            let huf = value * usdToHufRate
            return (huf, value, "USD")
            
        default: // "HUF" vagy bármi ismeretlen → úgy kezeljük, mintha HUF lenne
            return (value, nil, nil)
        }
    }
}
