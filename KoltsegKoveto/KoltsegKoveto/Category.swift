//
//  Category.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 19..
//

import Foundation
import SwiftData

// SwiftData modell osztály – ezt tárolja az adatbázis
@Model
final class Category {
    // Kategórianév, egyedinek jelölve: ugyanazzal a névvel nem lehet több kategória
    @Attribute(.unique) var name: String
    var iconSystemName: String
    var isExpense: Bool
    
    init(name: String, iconSystemName: String, isExpense: Bool = true) {
        self.name = name
        self.iconSystemName = iconSystemName
        self.isExpense = isExpense
    }
}
