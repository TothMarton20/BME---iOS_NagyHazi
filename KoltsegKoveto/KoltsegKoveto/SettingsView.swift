//
//  SettingsView.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 19..
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    
    // SwiftData lekérdezés: kategóriák név szerint rendezve
    @Query(sort: \Category.name) private var categories: [Category]
    
    // Tranzakciók lekérdezése: dátum szerint fordított sorrendben (legújabb elöl)
    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]
    
    // Alap pénznem tárolása (UserDefaults-on keresztül)
    @AppStorage("baseCurrency") private var baseCurrency = "HUF"
    
    // Értesítések engedélyezve/tiltva
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    
    // Egyenleg korrekció (pl. manuális beállítás miatt)
    @AppStorage("balanceAdjustment") private var balanceAdjustment: Double = 0
    
    // Az elemzések nullázásának időpontja (referenciaidő óta eltelt másodpercek)
    @AppStorage("analysisResetStartTime") private var analysisResetStartTime: Double = 0
    
    // Egyedi elemzési kezdődátum használata-e
    @AppStorage("analysisCustomStartEnabled") private var analysisCustomStartEnabled: Bool = false
    
    // Egyedi elemzési kezdődátum (időbélyegként tárolva)
    @AppStorage("analysisCustomStartTime") private var analysisCustomStartTime: Double = 0
    
    // Új kategória létrehozásához használt mezők
    @State private var newCategoryName: String = ""
    @State private var newCategoryEmoji: String = ""
    @State private var newCategoryIsExpense: Bool = true
    
    // Figyelmeztető alert megjelenítéséhez
    @State private var showResetAlert = false
    @State private var resetAlertMessage = ""
    
    // Mentett árfolyamok (UserDefaults)
    @AppStorage("eurToHufRate") private var eurToHufRate: Double = 0
    @AppStorage("usdToHufRate") private var usdToHufRate: Double = 0
    
    // Árfolyamok lekérdezésének állapota
    @State private var isLoadingRates = false
    @State private var rateErrorMessage: String?
    
    var body: some View {
        Form {
            // MARK: Árfolyamok (Frankfurter API)
            Section("Árfolyamok") {
                if isLoadingRates {
                    // Betöltés közbeni spinner
                    ProgressView("Árfolyamok frissítése…")
                } else if let error = rateErrorMessage {
                    // Hibaüzenet, ha nem sikerült lekérni az árfolyamokat
                    Text("Hiba: \(error)")
                        .font(AppFont.caption())
                        .foregroundStyle(.red)
                } else {
                    // Ha minden rendben, megjelenítjük az eltárolt árfolyamokat
                    VStack(alignment: .leading, spacing: 4) {
                        Text("1 EUR ≈ \(formattedRate(eurToHufRate)) HUF")
                        Text("1 USD ≈ \(formattedRate(usdToHufRate)) HUF")
                    }
                    .font(AppFont.body())
                }
                
                // Kézi frissítés gomb – async hívás Task-ben
                Button("Árfolyamok frissítése") {
                    Task { await fetchRates() }
                }
            }
            
            // MARK: Kategóriák listája
            Section("Kategóriák") {
                // Navigáció egy külön nézetre, ahol a kategóriákat lehet kezelni
                NavigationLink("Kategóriák kezelése") {
                    CategoryListView()
                }
            }
                        
            // MARK: Értesítések
            Section("Értesítések") {
                // Egyszerű toggle az értesítések engedélyezésére
                Toggle("Értesítések engedélyezése", isOn: $notificationsEnabled)
            }
            
            // MARK: Egyenleg / Elemzések nullázása
            Section("Egyenleg") {
                // Teljes nullázás: egyenleg és elemzések is újrakezdődnek
                Button(role: .destructive) {
                    resetBalance()
                    resetAlertMessage = "A rendelkezésre álló összeg és az elemzések nullázása megtörtént."
                    showResetAlert = true
                } label: {
                    Text("Rendelkezésre álló összeg nullázása")
                }
                
                // Csak az elemzések kezdőidőpontját nullázzuk, az aktuális egyenleget nem
                Button {
                    resetAnalysisOnly()
                    resetAlertMessage = "Az elemzések nullázása megtörtént."
                    showResetAlert = true
                } label: {
                    Text("Csak elemzések nullázása")
                }
            }
            
            // MARK: Elemzések kezdete
            Section("Elemzések kezdete") {
                // Választható, hogy használunk-e egyedi kezdődátumot
                Toggle("Egyedi kezdődátum használata", isOn: $analysisCustomStartEnabled)

                if analysisCustomStartEnabled {
                    // Egyedi kezdődátum kiválasztása
                    DatePicker(
                        "Kezdődátum",
                        selection: customAnalysisStartDateBinding,
                        displayedComponents: .date
                    )
                }

                // Magyarázó szöveg az elemzési időszak működéséről
                Text("Ha be van kapcsolva, az elemzések ezt a dátumot veszik alapul. "
                     + "Ha kikapcsolod, akkor a legutóbbi nullázás dátumát használjuk.")
                    .font(AppFont.caption())
                    .foregroundStyle(.secondary)
            }
            
            // MARK: Névjegy
            Section("Névjegy") {
                Text("KöltségKövető alkalmazás\nSwiftUI + SwiftData.")
                    .font(AppFont.body())
            }
        }
        .navigationTitle("Beállítások")
        // Nullázás után megjelenő alert
        .alert(resetAlertMessage, isPresented: $showResetAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            // A nézet első megjelenésekor automatikus árfolyam-frissítés
            await fetchRates()
        }
    }
    
    // MARK: - Műveletek / Segédfüggvények
    
    // Árfolyam formázása két tizedes jeggyel, vagy "-" ha még nincs érvényes érték
    private func formattedRate(_ rate: Double) -> String {
        guard rate > 0 else { return "-" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: rate)) ?? "\(rate)"
    }
    
    // Csak az elemzések kezdőidőpontját állítjuk mostanira (egyenleghez nem nyúlunk)
    private func resetAnalysisOnly() {
        analysisResetStartTime = Date().timeIntervalSinceReferenceDate
    }
    
    // Binding, ami a mentett `analysisCustomStartTime` Double értéket Date-té alakítja és vissza
    private var customAnalysisStartDateBinding: Binding<Date> {
        Binding(
            get: {
                analysisCustomStartTime > 0
                    ? Date(timeIntervalSinceReferenceDate: analysisCustomStartTime)
                    : Date()
            },
            set: { newValue in
                analysisCustomStartTime = newValue.timeIntervalSinceReferenceDate
            }
        )
    }
    
    // Kategóriák törlése megadott indexek alapján, majd mentés
    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            context.delete(categories[index])
        }
        try? context.save()
    }
    
    // Egyenleg és elemzések nullázása
    private func resetBalance() {
        let total: Double = transactions.reduce(0.0) { partial, tx in
            let amount = Double(tx.amount)
            let signed = tx.isExpense ? -amount : amount
            return partial + signed
        }

        // Rendelkezésre álló összeg kinullázása (eddigi működés)
        balanceAdjustment = -total

        // Elemzések nullázása – innentől számolunk mindent
        analysisResetStartTime = Date().timeIntervalSinceReferenceDate
    }
    
    // Új kategória hozzáadása a felhasználó által megadott név, emoji és típus alapján
    private func addCategory() {
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // csak az első emojit vesszük figyelembe a beírt szövegből
        let emoji = extractFirstEmoji(from: newCategoryEmoji) ?? ""
        
        let category = Category(
            name: trimmedName,
            iconSystemName: emoji,
            isExpense: newCategoryIsExpense
        )
        
        context.insert(category)
        try? context.save()
        
        // Mezők visszaállítása alapértékekre
        newCategoryName = ""
        newCategoryEmoji = ""
        newCategoryIsExpense = true
    }

    // Az első érvényes emojit keresi ki egy szövegből
    private func extractFirstEmoji(from text: String) -> String? {
        for scalar in text.unicodeScalars {
            if scalar.properties.isEmoji &&
                (scalar.value >= 0x238D || scalar.properties.generalCategory == .otherSymbol) {
                return String(scalar)
            }
        }
        return nil
    }
    
    // Frankfurter API válasz struktúrája
    private struct FrankfurterResponse: Decodable {
        let base: String
        let date: String
        let rates: [String: Double]
    }

    // Árfolyamok lekérése a Frankfurter API-ról (EUR→HUF és USD→HUF)
    private func fetchRates() async {
        // Hibák és korábbi állapot alaphelyzetbe
        rateErrorMessage = nil
        isLoadingRates = true
        defer { isLoadingRates = false }
        
        do {
            // 1 EUR → HUF
            let eurUrl = URL(string: "https://api.frankfurter.dev/v1/latest?base=EUR&symbols=HUF")!
            let (eurData, _) = try await URLSession.shared.data(from: eurUrl)
            let eurResponse = try JSONDecoder().decode(FrankfurterResponse.self, from: eurData)
            if let hufRate = eurResponse.rates["HUF"] {
                eurToHufRate = hufRate
            }
            
            // 1 USD → HUF
            let usdUrl = URL(string: "https://api.frankfurter.dev/v1/latest?base=USD&symbols=HUF")!
            let (usdData, _) = try await URLSession.shared.data(from: usdUrl)
            let usdResponse = try JSONDecoder().decode(FrankfurterResponse.self, from: usdData)
            if let hufRate = usdResponse.rates["HUF"] {
                usdToHufRate = hufRate
            }
        } catch {
            // Ha bármelyik hívás hibás, beállítjuk a hibaüzenetet
            rateErrorMessage = "Nem sikerült lekérni az árfolyamokat."
            print("Rate fetch error:", error)
        }
    }
}
