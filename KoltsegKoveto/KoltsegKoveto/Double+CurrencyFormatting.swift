//
//  Double+CurrencyFormatting.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 19..
//

import Foundation

// Extra függvény pénznemmel formázott megjelenítéshez
extension Double {
    func formattedCurrency(code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 0
        
        // Ha valamiért nem sikerül a formázás, fallbackként kiírjuk simán
        return formatter.string(from: NSNumber(value: self)) ?? "\(self) \(code)"
    }
}
