//
//  ChipView.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 19..
//

import SwiftUI

// Egy egyszerű "chip" stílusú gomb (pl. szűrők, gyors akciók megjelenítésére)
struct ChipView: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(AppFont.caption())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppColor.cardBackground.opacity(0.9))
            .clipShape(Capsule())
            .shadow(radius: 1, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}
