////
////  EditDefiNotificationsSheet.swift
////  becap
////
////  Created by Adam Mabrouki on 18/07/2025.
////
//
//import SwiftUI
//
//// Utilitaire pour rendre Int compatible Identifiable
//private struct IdentifiableInt: Identifiable {
//    let value: Int
//    var id: Int { value }
//}
//
//struct EditDefiNotificationsSheet: View {
//    @State var editingDefi: Challenge
//    var onSave: (Challenge) -> Void
//    var onCancel: () -> Void
//
//    @State private var editingDayIndex: IdentifiableInt? = nil
//
//    var body: some View {
//        NavigationView {
//            List {
//                ForEach(0..<editingDefi.duration, id: \.self) { dayIndex in
//                    Button {
//                        editingDayIndex = IdentifiableInt(value: dayIndex)
//                    } label: {
//                        HStack {
//                            Text("Day \(dayIndex + 1)")
//                            Spacer()
//                            Text("\(editingDefi.notificationConfig[dayIndex].times.count) notif(s)")
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Edit notifications")
//            .toolbar {
//                ToolbarItem(placement: .confirmationAction) {
//                    Button("Save") { onSave(editingDefi) }
//                }
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Cancel", role: .cancel) { onCancel() }
//                }
//            }
//        }
//        .sheet(item: $editingDayIndex) { wrapper in
//            EditDayTimesSheet(
//                times: editingDefi.notificationConfig[wrapper.value].times,
//                onUpdate: { newTimes in
//                    editingDefi.notificationConfig[wrapper.value].times = newTimes
//                },
//                onDone: { editingDayIndex = nil },
//                onDuplicateToAllDays: { newTimes in
//                    for i in editingDefi.notificationConfig.indices {
//                        editingDefi.notificationConfig[i].times = newTimes
//                    }
//                },
//                onReset: {
//                    editingDefi.notificationConfig[wrapper.value].times = []
//                }
//            )
//        }
//    }
//}
