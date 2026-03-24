//
//  CategoryListView.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 24..
//

import SwiftUI
import SwiftData

struct CategoryListView: View {
    // SwiftData context az adatműveletekhez (insert, delete, save, stb.)
    @Environment(\.modelContext) private var context
    // Összes kategória lekérdezése, név szerint rendezve
    @Query(sort: \Category.name) private var categories: [Category]

    // Új kategória felvételéhez használt sheet megjelenítésének állapota
    @State private var isPresentingNewCategory = false

    var body: some View {
        List {
            if categories.isEmpty {
                // Üres állapot, ha még nincs egy kategória sem
                Text("Még nincs egy kategória sem.")
                    .font(AppFont.caption())
                    .foregroundStyle(.secondary)
            } else {
                // Meglévő kategóriák listázása
                ForEach(categories) { category in
                    HStack(spacing: 12) {
                        Text(category.displayEmoji)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.name)
                            Text(category.isExpense ? "Kiadás" : "Bevétel")
                                .font(AppFont.caption())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                // Jobbra húzásra törlés engedélyezése
                .onDelete(perform: deleteCategories)
            }
        }
        .navigationTitle("Kategóriák")
        .toolbar {
            // Jobb felső plusz gomb új kategória hozzáadásához
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingNewCategory = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        // Új kategória sheet
        .sheet(isPresented: $isPresentingNewCategory) {
            NewCategoryView()
        }
    }

    // MARK: Kategória törlése
    // Kiválasztott kategóriák törlése a listából és az adatbázisból
    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            context.delete(categories[index])
        }
        try? context.save()
    }
}

// MARK: Új kategória
struct NewCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    // Felhasználó által beírt adatok
    @State private var name: String = ""
    @State private var emojiText: String = ""
    @State private var isExpense: Bool = true

    // Validálás: legyen nem üres név, és legyen benne legalább egy emoji
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        extractFirstEmoji(from: emojiText) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Kategória neve") {
                    TextField("Pl. Étel", text: $name)
                }

                Section("Ikon (emoji)") {
                    TextField("Pl. 🍔", text: $emojiText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.default)

                    Text("Csak egy emojit adj meg!")
                        .font(AppFont.caption())
                        .foregroundStyle(.secondary)
                }

                Section("Típus") {
                    Picker("Típus", selection: $isExpense) {
                        Text("Kiadás").tag(true)
                        Text("Bevétel").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Új kategória")
            .toolbar {
                // Mégse gomb – bezárja a sheetet mentés nélkül
                ToolbarItem(placement: .cancellationAction) {
                    Button("Mégse") { dismiss() }
                }
                // Mentés gomb – új kategória létrehozása
                ToolbarItem(placement: .confirmationAction) {
                    Button("Mentés") {
                        saveCategory()
                    }
                    // Amíg az adatok nem validak, a gomb le van tiltva
                    .disabled(!isValid)
                }
            }
        }
    }

    // MARK: új kategória mentése
    private func saveCategory() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        // Ha mégis valamiért nincs érvényes emoji, adunk egy alapértelmezettet
        let emoji = extractFirstEmoji(from: emojiText) ?? "🏷️"

        let category = Category(
            name: trimmedName,
            iconSystemName: emoji,
            isExpense: isExpense
        )

        context.insert(category)
        try? context.save()
        dismiss()
    }
}
