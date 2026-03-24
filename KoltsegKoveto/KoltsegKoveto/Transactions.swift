//
//  Transactions.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 19..
//

import Foundation
import SwiftData

// A tranzakció ismétlődését leíró enum
enum Recurrence: Int, CaseIterable, Identifiable {
    case none = 0
    case daily
    case weekly
    case monthly
    case yearly
    
    // Identifiable megvalósítása – az enum nyers értékét (rawValue) használjuk azonosítónak
    var id: Int { rawValue }
    
    // Felhasználóbarát, lokalizált név minden esethez
    var localizedName: String {
        switch self {
        case .none:    return "Nincs"
        case .daily:   return "Napi"
        case .weekly:  return "Heti"
        case .monthly: return "Havi"
        case .yearly:  return "Éves"
        }
    }
}

@Model
final class Transaction {
    var id: UUID
    var date: Date
    var amount: Double
    var isExpense: Bool
    var note: String
    var currencyCode: String
    var recurrenceRaw: Int
    
    @Relationship var category: Category?
    
    var receiptImageData: Data?
    var originalAmount: Double? = nil
    var originalCurrencyCode: String? = nil
    
    init(
        id: UUID = UUID(),
        date: Date = .now,
        amount: Double,
        isExpense: Bool = true,
        note: String = "",
        currencyCode: String = "HUF",
        recurrence: Recurrence = .none,
        category: Category? = nil,
        receiptImageData: Data? = nil
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.isExpense = isExpense
        self.note = note
        self.currencyCode = currencyCode
        self.recurrenceRaw = recurrence.rawValue
        self.category = category
        self.receiptImageData = receiptImageData
    }
    
    // Computed property az enum használatához
    var recurrence: Recurrence {
        get { Recurrence(rawValue: recurrenceRaw) ?? .none }
        set { recurrenceRaw = newValue.rawValue }
    }
}
