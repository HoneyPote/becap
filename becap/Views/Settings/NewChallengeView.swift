//
//  NewChallengeView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

struct NewChallengeView: View {
    @Environment(\.dismiss) var dismiss
    @FocusState private var focusedField: Field?

    @StateObject private var viewModel = NewChallengeViewModel()

    @Binding var challengeCreated: Bool

    @State private var showNameError = false
    @State private var editedNotifTime: Date = Date()
    @State private var editedNotifIndex: Int?
    @State private var isEditTimeSheetOpen: Bool = false

    private enum Field: Hashable {
        case name
    }

    var body: some View {
        ZStack {
            LinearGradient.petrolToSky.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    header
                        .padding(.horizontal)
                        .padding(.top, 36)

                    // Name
                    GlassCard {
                        nameSetting
                    }

                    // Category
                    GlassCard {
                        categorySetting
                    }

                    // Duration
                    GlassCard {
                        durationSetting
                    }

                    // Jokers
                    GlassCard {
                        jokerSetting
                    }

                    // Notifications
                    GlassCard {
                        notificationsSetting
                    }

                    // Creation button
                    GlassCard {
                        creationButton
                            .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .interactiveDismissDisabled()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(.ultraThinMaterial.opacity(0.35))
                        .clipShape(Circle())
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Défi libre")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundColor(.white)
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 3)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Créer un défi libre")
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 4)

            Spacer()
        }
    }

    private var nameSetting: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nom du défi")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 6) {
                TextField("Nom", text: $viewModel.name)
                    .padding(16)
                    .background(.ultraThinMaterial)
                    .cornerRadius(14)
                    .font(.system(.body, design: .rounded))
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(showNameError && viewModel.trimmedName.isEmpty ? Color.red.opacity(0.9) : Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
                    .focused($focusedField, equals: .name)
                    .onChange(of: viewModel.name) { newValue in
                        if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            showNameError = false
                        }
                    }
                    .submitLabel(.done)
                    .onSubmit {
                        showNameError = viewModel.trimmedName.isEmpty
                    }

                if showNameError && viewModel.trimmedName.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.red.opacity(0.85))
                        Text("Le nom du défi est obligatoire.")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundColor(.red.opacity(0.9))
                    }
                    .transition(.opacity)
                }
            }
        }
    }

    private var categorySetting: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Type de défi")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(.white)

            Menu {
                ForEach(ChallengeCategory.allCases, id: \.self) { category in
                    Button(category.displayName) {
                        viewModel.category = category
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.category.displayName)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
        }
    }

    private var durationSetting: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Durée du défi")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("\(viewModel.duration) jour\(viewModel.duration > 1 ? "s" : "")")
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("Personnalisez la durée")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                }

                Slider(value: Binding(
                    get: { Double(viewModel.duration) },
                    set: { viewModel.duration = Int($0) }
                ), in: 3...365, step: 1) {
                    Text("Durée")
                } minimumValueLabel: {
                    Text("3")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                } maximumValueLabel: {
                    Text("365")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                .tint(.white)

                Stepper(value: $viewModel.duration, in: 3...365, step: 1) {
                    Text("Ajuster jour par jour")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))
                }
            }
        }
    }

    private var jokerSetting: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Jokers disponibles")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(viewModel.jokersNumber)")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundColor(.white.opacity(0.85))
            }

            Stepper(value: $viewModel.jokersNumber,
                    in: 0...max(0, viewModel.duration)) {
                Text("Nombre de jokers pour le défi")
                    .foregroundColor(.white.opacity(0.9))
            }

            HStack(spacing: 8) {
                let iconCount = min(max(viewModel.jokersNumber, 1), 8)
                ForEach(0..<iconCount, id: \.self) { index in
                    let isActive = index < min(viewModel.jokersNumber, iconCount)
                    JokerIconView(size: 28, isDimmed: !isActive)
                        .opacity(viewModel.jokersNumber == 0 ? 0.25 : 1.0)
                }

                if viewModel.jokersNumber > iconCount {
                    Text("+\(viewModel.jokersNumber - iconCount)")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Text("Les jokers permettent de sauver un jour sans post. Les participants peuvent voter pour valider un joker sur une publication si la majorité l'estime nécessaire.")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.65))
        }
    }

    private var creationButton: some View {
        VStack {
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView("Création en cours…")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    Spacer()
                }
                .padding(.vertical, 16)
            } else {
                Button(action: {
                    if viewModel.trimmedName.isEmpty {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showNameError = true
                            focusedField = .name
                        }
                        return
                    }

                    viewModel.createChallenge() { success in
                        if success {
                            challengeCreated = true
                            dismiss()
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "flag.2.crossed")
                            .font(.system(size: 18, weight: .semibold))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Créer le défi")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                            Text("Lancez le défi et partagez-le avec le monde !")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [
                            Color(hex: "#4F46E5").opacity(0.95),
                            Color(hex: "#38BDF8").opacity(0.9)
                        ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 10)
                }
                .opacity(viewModel.isFormValid ? 1 : 0.65)
            }
        }
    }
}

// MARK: Notifications setting
extension NewChallengeView {
    private var notificationsSetting: some View {
        let notifSettingColumns = [GridItem(.flexible(), spacing: 12),
                                   GridItem(.flexible(), spacing: 12)]

        return VStack(spacing: 18) {
            Text("Notifications quotidiennes")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(.white)

            VStack(spacing: 12) {
                LazyVGrid(columns: notifSettingColumns, spacing: 12) {
                    ForEach(Array(viewModel.notificationTimes.enumerated()), id: \.element.id) { index, item in
                        notificationTimeCell(item.fullDate, index: index)
                    }

                    if viewModel.notificationTimes.count < 3 {
                        addNotificationCell
                    }
                }
            }
        }
        .sheet(isPresented: $isEditTimeSheetOpen, onDismiss: {
            if let editedNotifIndex {
                viewModel.updateNotificationTime(index: editedNotifIndex, newDate: editedNotifTime)
            }
        }) {
            VStack {
                DatePicker(
                    "Choisir une heure",
                    selection: Binding(
                        get: { editedNotifTime },
                        set: { newValue in
                            editedNotifTime = newValue
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

    private func notificationTimeCell(_ date: Date, index: Int) -> some View {
        HStack(spacing: 8) {
            Button {
                editedNotifTime = date
                editedNotifIndex = index
                isEditTimeSheetOpen = true
            } label: {
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
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    viewModel.removeNotificationTime(at: index)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red.opacity(0.9))
                    .font(.system(size: 16, weight: .semibold))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private var addNotificationCell: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                viewModel.addNotificationTime()
                editedNotifTime = Date()
                editedNotifIndex = viewModel.notificationTimes.count - 1
                isEditTimeSheetOpen = true
            }
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
