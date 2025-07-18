//
//  EditDefiNotificationsSheet.swift
//  becap
//
//  Created by Adam Mabrouki on 18/07/2025.
//

import SwiftUI

struct EditDefiNotificationsSheet: View {
    @State var editingDefi: Defi
    var onSave: (Defi) -> Void
    var onCancel: () -> Void

    @State private var editingDayIndex: Int? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(0..<editingDefi.duration, id: \.self) { dayIndex in
                    Button {
                        editingDayIndex = dayIndex
                    } label: {
                        HStack {
                            Text("Day \(dayIndex + 1)")
                            Spacer()
                            Text("\(editingDefi.notificationConfig[dayIndex].times.count) notif(s)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Edit notifications")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(editingDefi) }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { onCancel() }
                }
            }
            .sheet(item: $editingDayIndex) { idx in
                EditDayTimesSheet(
                    times: editingDefi.notificationConfig[idx].times,
                    onUpdate: { newTimes in
                        editingDefi.notificationConfig[idx].times = newTimes
                    },
                    onDone: { editingDayIndex = nil },
                    onDuplicateToAllDays: { newTimes in
                        for i in editingDefi.notificationConfig.indices {
                            editingDefi.notificationConfig[i].times = newTimes
                        }
                    },
                    onReset: {
                        editingDefi.notificationConfig[idx].times = []
                    }
                )
            }
        }
    }
}

extension Int: Identifiable { public var id: Int { self } }



