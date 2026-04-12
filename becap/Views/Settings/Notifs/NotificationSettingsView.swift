//
//  NotificationSettingsView.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: NotificationSettingsViewModel

    @State private var isEditTimeSheetOpen = false
    @State private var editedNotificationTime = Date()
    @State private var editedNotificationIndex: Int?
    @State private var editedNotificationScope: NotificationConfigScope?

    private let notificationColumns = [GridItem(.flexible(), spacing: 12),
                                       GridItem(.flexible(), spacing: 12)]

    init(challenge: any ChallengeRepresentable, currentPartipicant: ParticipantUIModel) {
        _viewModel = StateObject(wrappedValue: NotificationSettingsViewModel(currentChallenge: challenge, currentParticipant: currentPartipicant))
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 27/255, green: 40/255, blue: 74/255),
                                    Color(red: 21/255, green: 73/255, blue: 114/255)],
                           startPoint: .top,
                           endPoint: .bottom)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: { DispatchQueue.main.async { dismiss() } }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 5, x: 0, y: 2)
                    }

                    Spacer()

                    Text("Notifications")
                        .font(.system(.title, design: .rounded).weight(.heavy))
                        .foregroundColor(.white)

                    Spacer(minLength: 36)
                }
                .padding(.horizontal)
                .padding(.top, 30)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        notificationSection(title: "Notifications du défi",
                                            subtitle: "Heures définies par le créateur du défi",
                                            scope: .challenge,
                                            isEditable: viewModel.currentParticipant.isAdmin)

                        notificationSection(title: "Mes notifications",
                                            subtitle: "Personnalise tes rappels quotidiens",
                                            scope: .user,
                                            isEditable: true)
                    }
                    .padding()
                }

                Button(action: {
                    viewModel.saveConfigs()
                    dismiss()
                }) {
                    Text("Enregistrer")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 82/255, green: 207/255, blue: 144/255),
                                         Color(red: 27/255, green: 188/255, blue: 155/255)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(Color(red: 9/255, green: 34/255, blue: 44/255))
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 12)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
                .padding(.top, 2)
            }
        }
        .interactiveDismissDisabled()
        .navigationBarHidden(true)
        .sheet(isPresented: $isEditTimeSheetOpen, onDismiss: {
            guard let scope = editedNotificationScope, let index = editedNotificationIndex else { return }

            viewModel.updateNotificationTime(scope: scope, index: index, newDate: editedNotificationTime)
        }) {
            VStack {
                DatePicker(
                    "Choisir une heure",
                    selection: Binding(
                        get: { editedNotificationTime },
                        set: { newValue in
                            editedNotificationTime = newValue
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 150)
                .background(Color.clear)
            }
            .presentationDetents([.height(150)])
            .presentationDragIndicator(.hidden)
        }
    }

    private func notificationSection(title: String, subtitle: String, scope: NotificationConfigScope, isEditable: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }

            if isEditable {
                actionButtons(scope: scope)
            }

            LazyVGrid(columns: notificationColumns, spacing: 12) {
                let notifs = viewModel.getNotifications(for: scope)

                ForEach(Array(notifs.enumerated()), id: \.element.id) { index, item in
                    notificationTimeCell(date: item.fullDate, scope: scope, index: index, isEditable: isEditable)
                }

                if isEditable, notifs.count < 3 {
                    addNotificationCell(scope: scope)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .allowsHitTesting(isEditable)
    }

    private func actionButtons(scope: NotificationConfigScope) -> some View {
        HStack(spacing: 12) {
            Button {
                viewModel.resetNotificationTime(scope: scope)
            } label: {
                Label("Tout supprimer", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.plain)
            .font(.system(.footnote, design: .rounded).weight(.semibold))
            .foregroundColor(.white.opacity(0.85))

            Spacer()

            if scope == .user {
                Button {
                    viewModel.copyChallengeNotifToUser()
                } label: {
                    Label("Copier les heures par défaut du défi", systemImage: "arrow.down.circle")
                }
                .buttonStyle(.plain)
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundColor(.white.opacity(0.9))
            }
        }
    }

    private func notificationTimeCell(date: Date, scope: NotificationConfigScope, index: Int, isEditable: Bool) -> some View {
        HStack(spacing: 8) {
            Button {
                editedNotificationTime = date
                editedNotificationScope = scope
                editedNotificationIndex = index
                isEditTimeSheetOpen = true
            } label: {
                if isEditable {
                    HStack(spacing: .zero) {
                        Text(date, style: .time)
                            .foregroundColor(.white)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                        Spacer()
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.white.opacity(0.85))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                } else {
                    Spacer()
                    Text(date, style: .time)
                        .foregroundColor(.white)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if isEditable {
                Button {
                    viewModel.removeNotificationTime(scope: scope, index: index)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red.opacity(0.9))
                        .font(.system(size: 16, weight: .semibold))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private func addNotificationCell(scope: NotificationConfigScope) -> some View {
        Button {
            viewModel.addNotificationTime(scope: scope)
            editedNotificationTime = Date()
            editedNotificationScope = scope
            editedNotificationIndex = viewModel.getNotifications(for: scope).count - 1
            isEditTimeSheetOpen = true
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .semibold))

                Text("Ajouter")
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
            }
            .foregroundColor(.white.opacity(0.9))
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(10)
            .background(Color.white.opacity(0.12))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
