//
//  TransactionRowView.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 19..
//

import SwiftUI

struct TransactionRowView: View {
    // A sorban megjelenítendő tranzakció (pl. listából érkezik)
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            // Bal oldalt – kategória emoji (pl. 🍔 stb.)
            Text(transaction.category?.displayEmoji ?? "🏷️")
                .font(.title2)

            // Középen: kategórianév + dátum + deviza info + megjegyzés
            VStack(alignment: .leading, spacing: 2) {
                // Kategórianév, vagy "Kategória nélkül", ha nincs beállítva
                Text(transaction.category?.name ?? "Kategória nélkül")
                    .font(AppFont.body())

                // Tranzakció dátuma rövid formátumban
                Text(transaction.date.formattedShort())
                    .font(AppFont.caption())
                    .foregroundStyle(.secondary)

                // Ha a tranzakció más devizából lett átváltva az eredeti összeget és pénznemet is kiírjuk
                if let originalCode = transaction.originalCurrencyCode,
                   let originalAmount = transaction.originalAmount {
                    Text("Eredeti: \(originalAmount.formattedCurrency(code: originalCode)) (átváltva)")
                        .font(AppFont.caption())
                        .foregroundStyle(.secondary)
                }

                // Megjegyzés – csak akkor jelenik meg, ha nem üres
                if !transaction.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(transaction.note)
                        .font(AppFont.caption())
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Jobb oldalt: az összeg, a tranzakció aktuális pénznemében
            Text(amountText)
                .font(AppFont.body().weight(.semibold))
                // Kiadás piros, bevétel zöld
                .foregroundStyle(transaction.isExpense ? Color.red : Color.green)
        }
        // Függőleges belső margó, hogy a sor ne legyen túl "lapos"
        .padding(.vertical, 4)
    }

    // Az összeg formázva, a tranzakció saját pénznemével
    private var amountText: String {
        transaction.amount.formattedCurrency(code: transaction.currencyCode)
    }
}
