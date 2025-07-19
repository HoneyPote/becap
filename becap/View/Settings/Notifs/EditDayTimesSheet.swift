//
//  EditDayTimesSheet.swift
//  becap
//
//  Created by Adam Mabrouki on 18/07/2025.
//

import SwiftUI

struct EditDayTimesSheet: View {
    @State var times: [Date]
    var onUpdate: ([Date]) -> Void
    var onDone: () -> Void
    var onDuplicateToAllDays: (([Date]) -> Void)? = nil
    var onReset: (() -> Void)? = nil

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Up to 3 notifications")) {
                    ForEach(times.indices, id: \.self) { idx in
                        HStack {
                            DatePicker(
                                "Notification \(idx + 1)",
                                selection: Binding(
                                    get: { times[idx] },
                                    set: { newVal in
                                        times[idx] = newVal
                                        onUpdate(times)
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            Spacer()
                            if times.count > 1 {
                                Button(role: .destructive) {
                                    times.remove(at: idx)
                                    onUpdate(times)
                                } label: {
                                    Image(systemName: "minus.circle.fill").foregroundColor(.red)
                                }
                            }
                        }
                    }
                    if times.count < 3 {
                        Button {
                            let baseHours = [9, 13, 18]
                            let hour = baseHours[times.count]
                            let calendar = Calendar.current
                            let newDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
                            times.append(newDate)
                            onUpdate(times)
                        } label: {
                            Label("Add time", systemImage: "plus.circle.fill")
                        }
                    }
                }
                if let onDuplicate = onDuplicateToAllDays {
                    Button {
                        onDuplicate(times)
                        onDone()
                    } label: {
                        Label("Duplicate on all days", systemImage: "square.stack.3d.down.forward")
                    }
                }
                if let onReset = onReset {
                    Button(role: .destructive) {
                        onReset()
                        times = []
                        onUpdate(times)
                    } label: {
                        Label("Reset this day", systemImage: "arrow.uturn.left")
                    }
                }
            }
            .navigationTitle("Edit day")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDone() }
                }
            }
        }
    }
}
