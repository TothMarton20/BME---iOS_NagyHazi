//
//  iPadRootView.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 19..
//

import SwiftUI
import SwiftData

// Oldalsó sáv (sidebar) menüpontjai
private enum SidebarItem: Hashable {
    case dashboard
    case transactions
    case analytics
    case settings
}

struct iPadRootView: View {
    @State private var selection: SidebarItem? = .dashboard
    @State private var selectedTransaction: Transaction?
    @State private var showNewTransactionSheet = false
    
    var body: some View {
        NavigationSplitView {
            // Bal oldali sidebar
            sidebar
        } content: {
            // Középső tartalom (lista / fő nézet)
            contentView
        } detail: {
            // Jobb oldali részletező nézet
            detailView
        }
        .sheet(isPresented: $showNewTransactionSheet) {
            // Új tranzakció felvétele külön sheet-ben
            NavigationStack {
                EditTransactionView()
            }
        }
    }
    
    // MARK: - Sidebar
    
    private var sidebar: some View {
        List(selection: $selection) {
            Section("Navigáció") {
                Label("Irányítópult", systemImage: "house.fill")
                    .tag(SidebarItem.dashboard)
                Label("Tranzakciók", systemImage: "list.bullet.rectangle.portrait")
                    .tag(SidebarItem.transactions)
                Label("Elemzések", systemImage: "chart.bar.xaxis")
                    .tag(SidebarItem.analytics)
                Label("Beállítások", systemImage: "gearshape.fill")
                    .tag(SidebarItem.settings)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("KöltségKövető")
        .toolbar {
            // Plusz gomb a jobb felső sarokban – új tranzakciót nyit
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewTransactionSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
    }
    
    // MARK: - Középső oszlop tartalma
    
    @ViewBuilder
    private var contentView: some View {
        switch selection {
        case .dashboard:
            NavigationStack {
                DashboardView(showNewTransactionSheet: $showNewTransactionSheet)
            }
        case .transactions:
            TransactionListView(selectedTransaction: $selectedTransaction)
        case .analytics:
            AnalyticsView()
        case .settings:
            SettingsView()
        case .none:
            Text("Válassz egy nézetet")
                .font(AppFont.title(22))
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Jobb oldali „detail” oszlop
    
    @ViewBuilder
    private var detailView: some View {
        if let transaction = selectedTransaction {
            TransactionDetailView(transaction: transaction)
        } else if selection == .dashboard {
            DashboardDetailChartsView()
        } else {
            Text("Nincs kiválasztott elem")
                .foregroundStyle(.secondary)
        }
    }
}
