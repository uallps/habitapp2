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
    @State private var sidebarSelection: String? = "habits"

    private var storageProvider: StorageProvider {
        appConfig.storageProvider
    }

    private var notesEnabled: Bool {
        appConfig.isDailyNotesEnabled
    }

    private var pluginTabs: [PluginTabItem] {
        PluginRegistry.shared.getTabItems()
    }

    private var sidebarItems: [AppSidebarItem] {
        var items: [AppSidebarItem] = [
            AppSidebarItem(
                id: "habits",
                title: "Habitos",
                systemImage: "checklist",
                view: AnyView(HabitListView(storageProvider: storageProvider))
            )
        ]
#if PREMIUM || PLUGIN_NOTES
        if notesEnabled {
            items.append(AppSidebarItem(
                id: "notes",
                title: "Notas",
                systemImage: "note.text",
                view: AnyView(NotesListView(storageProvider: storageProvider))
            ))
        }
#endif
        for tab in pluginTabs {
            items.append(AppSidebarItem(
                id: tab.id,
                title: tab.title,
                systemImage: tab.systemImage,
                view: tab.view
            ))
        }
        items.append(AppSidebarItem(
            id: "settings",
            title: "Ajustes",
            systemImage: "gearshape",
            view: AnyView(SettingsView())
        ))
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

#if PREMIUM || PLUGIN_NOTES
                if notesEnabled {
                    NotesListView(storageProvider: storageProvider)
                        .tabItem {
                            Label("Notas", systemImage: "note.text")
                        }
                }
#endif

                ForEach(pluginTabs) { tab in
                    tab.view
                        .tabItem {
                            Label(tab.title, systemImage: tab.systemImage)
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
                    NavigationLink(value: item.id) {
                        Label(item.title, systemImage: item.systemImage)
                    }
                }
            } detail: {
                if let selection = sidebarSelection,
                   let item = sidebarItems.first(where: { $0.id == selection }) {
                    item.view
                } else {
                    Text("Seleccion no disponible")
                }
            }
            .environmentObject(appConfig)
            #endif
        }
    }
}

private struct AppSidebarItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let view: AnyView
}
