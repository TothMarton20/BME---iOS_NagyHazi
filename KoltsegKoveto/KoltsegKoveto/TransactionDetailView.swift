//
//  TransactionDetailView.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 19..
//

import SwiftUI

#if canImport(UIKit)
import UIKit   // Kép (UIImage) kezeléséhez kell – csak olyan platformon, ahol van UIKit
#endif

struct TransactionDetailView: View {
    let transaction: Transaction
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Felső sor: kategórianév és összeg egymás mellett
                HStack {
                    // Tranzakció kategóriája, ha nincs, akkor "Kategória nélkül"
                    Text(transaction.category?.name ?? "Kategória nélkül")
                        .font(AppFont.title(28))
                    
                    Spacer()
                    
                    Text(amountText)
                        .font(AppFont.title(28))
                        // Szín attól függ, hogy kiadás vagy bevétel
                        .foregroundStyle(transaction.isExpense ? AppColor.negative : AppColor.positive)
                }
                
                // Dátum megjelenítése rövid formátumban
                Text(transaction.date.formattedShort())
                    .font(AppFont.body())
                    .foregroundStyle(.secondary)
                
                // Ha van megjegyzés, csak akkor mutatjuk a blokkot
                if !transaction.note.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Megjegyzés")
                            .font(AppFont.body().weight(.semibold))
                        Text(transaction.note)
                            .font(AppFont.body())
                    }
                }
                
                // Ismétlődés típusa
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ismétlődés")
                        .font(AppFont.body().weight(.semibold))
                    Text(transaction.recurrence.localizedName)
                }
                
                // Nyugta képe, ha van eltárolt imageData
                if let data = transaction.receiptImageData,
                   let uiImage = UIImage(data: data) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nyugta")
                            .font(AppFont.body().weight(.semibold))
                        
                        // A nyugta képe: méretezve, lekerekített sarkokkal
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("Részletek")
    }
    
    private var amountText: String {
        let sign = transaction.isExpense ? "-" : "+"
        return "\(sign)\(Int(transaction.amount)) \(transaction.currencyCode)"
    }
}
