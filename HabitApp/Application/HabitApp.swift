//
//  HabitApp.swift
//  HabitApp
//
//  Created by Codex on 03/12/25.
//
import SwiftUI

@main
struct HabitApp: App {
    @StateObject private var appConfig = AppConfig()
    @State private var sidebarSelection: SidebarItem? = .habits

    private var storageProvider: StorageProvider {
        appConfig.storageProvider
    }

    private var notesEnabled: Bool {
        appConfig.enableDailyNotes && appConfig.storageType == .swiftData
    }

    private var statsEnabled: Bool {
        appConfig.enableStatistics
    }

    private var sidebarItems: [SidebarItem] {
        var items: [SidebarItem] = [.habits]
        if notesEnabled { items.append(.notes) }
        if statsEnabled { items.append(.stats) }
        items.append(.settings)
        return items
    }

    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            TabView {
                HabitListView(storageProvider: storageProvider)
                    .tabItem {
                        Label("Habitos", systemImage: "checklist")
                    }

                if notesEnabled {
                    NotesListView(storageProvider: storageProvider)
                        .tabItem {
                            Label("Notas", systemImage: "note.text")
                        }
                }

                if statsEnabled {
                    StatisticsDashboardView(storageProvider: storageProvider)
                        .tabItem {
                            Label("Estadisticas", systemImage: "chart.bar.xaxis")
                        }
                }

                SettingsView()
                    .tabItem {
                        Label("Ajustes", systemImage: "gearshape")
                    }
            }
            .environmentObject(appConfig)
            #else
            NavigationSplitView {
                List(sidebarItems, selection: $sidebarSelection) { item in
                    NavigationLink(value: item) {
                        Label(item.title, systemImage: item.systemImage)
                    }
                }
            } detail: {
                switch sidebarSelection ?? .habits {
                case .habits:
                    HabitListView(storageProvider: storageProvider)
                case .notes:
                    if notesEnabled {
                        NotesListView(storageProvider: storageProvider)
                    } else {
                        Text("Notas desactivadas")
                    }
                case .stats:
                    if statsEnabled {
                        StatisticsDashboardView(storageProvider: storageProvider)
                    } else {
                        Text("Estadisticas desactivadas")
                    }
                case .settings:
                    SettingsView()
                }
            }
            .environmentObject(appConfig)
            #endif
        }
    }
}

private enum SidebarItem: Hashable, Identifiable {
    case habits
    case notes
    case stats
    case settings

    var id: Self { self }

    var title: String {
        switch self {
        case .habits: return "Habitos"
        case .notes: return "Notas"
        case .stats: return "Estadisticas"
        case .settings: return "Ajustes"
        }
    }

    var systemImage: String {
        switch self {
        case .habits: return "checklist"
        case .notes: return "note.text"
        case .stats: return "chart.bar.xaxis"
        case .settings: return "gearshape"
        }
    }
}
