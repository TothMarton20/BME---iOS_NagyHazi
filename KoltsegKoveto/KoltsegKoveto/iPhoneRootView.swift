//
//  iPhoneRootView.swift
//  KoltsegKoveto
//
//  Created by Márton Tóth on 2025. 11. 19..
//

import SwiftUI

struct iPhoneRootView: View {
    // Új tranzakció felvételéhez használt sheet állapota
    @State private var showNewTransactionSheet = false
    
    var body: some View {
        TabView {
            // FŐOLDAL / IRÁNYÍTÓPULT TAB
            NavigationStack {
                DashboardView(showNewTransactionSheet: $showNewTransactionSheet)
            }
            .tabItem {
                Label("Főoldal", systemImage: "house.fill")
            }

            // TRANZAKCIÓK LISTA TAB
            NavigationStack {
                TransactionListView()
            }
            .tabItem {
                Label("Tranzakciók", systemImage: "list.bullet.rectangle.portrait")
            }

            // ELEMZÉSEK TAB
            NavigationStack {
                AnalyticsView()
            }
            .tabItem {
                Label("Elemzések", systemImage: "chart.pie.fill")
            }

            // BEÁLLÍTÁSOK TAB
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Beállítások", systemImage: "gearshape.fill")
            }
        }
        // Globális „+” művelethez tartozó sheet (DashboardView-ból vezérelve)
        .sheet(isPresented: $showNewTransactionSheet) {
            NavigationStack {
                EditTransactionView()
            }
        }
    }
}
