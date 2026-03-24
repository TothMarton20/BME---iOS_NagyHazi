//
//  Date+Formatting.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 19..
//

import Foundation

// Kényelmi kiterjesztés a Date-hez: egységes, rövid dátumformátum az appban
extension Date {
    func formattedShort() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}
