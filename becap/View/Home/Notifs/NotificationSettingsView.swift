//
//  NotificationSettingsView.swift
//  becap
//
//  Created by Adam Mabrouki on 16/07/2025.
//

import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject var defiManager: DefiManager
    @State private var editingDefi: Defi? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(defiManager.defis) { defi in
                    NavigationLink(
                        destination: EmptyView(), // Pas de navigation réelle
                        label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(defi.name)
                                        .font(.headline)
                                    Text("\(defi.duration) days")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "bell.badge")
                                    .imageScale(.large)
                                    .padding(8)
                                    .foregroundColor(.accentColor)
                            }
                            .padding(.vertical, 8)
                        }
                    )
                    .contentShape(Rectangle()) // toute la zone devient cliquable
                    .simultaneousGesture(TapGesture().onEnded {
                        editingDefi = defi
                    })
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Notifications")
            .sheet(item: $editingDefi) { defi in
                EditDefiNotificationsSheet(
                    editingDefi: defi,
                    onSave: { updatedDefi in
                        if let idx = defiManager.defis.firstIndex(where: { $0.id == updatedDefi.id }) {
                            defiManager.defis[idx] = updatedDefi
                            NotificationManager.shared.scheduleAllNotifications(for: updatedDefi)
                        }
                        editingDefi = nil
                    },
                    onCancel: { editingDefi = nil }
                )
            }
        }
    }
}
