//
//  Category+Emoji.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 12. 10..
//

import Foundation

extension Category {
    var displayEmoji: String {
        let icon = iconSystemName
        
        // Ha emoji van eltárolva, azt használjuk
        if let emoji = extractFirstEmoji(from: icon), !emoji.isEmpty {
            return emoji
        }
        
        // Régi SF Symbol nevekből emoji
        switch icon {
        case "banknote.fill":
            return "💰"
        case "tram.fill":
            return "🚆"
        case "house.fill":
            return "🏠"
        case "gamecontroller.fill":
            return "🎮"
        case "fork.knife":
            return "🍽️"
        default:
            return "🏷️"
        }
    }
}

// Közös emoji-kinyerő
func extractFirstEmoji(from text: String) -> String? {
    for scalar in text.unicodeScalars {
        if scalar.properties.isEmoji &&
            (scalar.value >= 0x238D || scalar.properties.generalCategory == .otherSymbol) {
            return String(scalar)
        }
    }
    return nil
}
