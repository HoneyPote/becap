//
//  CreateBecapChallengeView.swift
//  becap
//
//  Created by Victor Derveaux on 06/02/2026.
//

import SwiftUI

private struct ChallengeShareSheetPayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

struct CreateBecapChallengeView: View {
    @Environment(\.dismiss) var dismiss

    @StateObject private var viewModel: CreateBecapChallengeViewModel

    @State private var shareSheetPayload: ChallengeShareSheetPayload?
    @State private var shouldDismissAfterShare: Bool = false
    @State private var editedNotifTime: Date = Date()
    @State private var editedNotifIndex: Int?
    @State private var isEditTimeSheetOpen: Bool = false

    init(type: BecapChallengeType) {
        _viewModel = StateObject(wrappedValue: CreateBecapChallengeViewModel(type: type))
    }

    var body: some View {
        ZStack {
            LinearGradient.petrolToSky.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    header
                        .padding(.horizontal)
                        .padding(.top, 36)

                    // Challenge preview
                    GlassCard {
                        challengePreviewSection
                    }

                    // Duration
                    GlassCard {
                        durationSetting
                    }

                    // Notifications
                    GlassCard {
                        notificationsSetting
                    }

                    GlassCard {
                        configurationSection
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
        .navigationBarBackButtonHidden()
        .sheet(item: $shareSheetPayload, onDismiss: {
            if shouldDismissAfterShare {
                dismiss()
            }
        }) { payload in
            ShareSheet(activityItems: payload.items)
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

            Text("Becap \(viewModel.challengeName)")
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 4)

            Spacer()
        }
    }

    private var challengePreviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Comment ça va se passer ?")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(.white)

            Text(challengeDescription)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            Image(exampleImageName)
                .resizable()
                .scaledToFill()
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )

            Text(exampleCaption)
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundColor(.white.opacity(0.75))
        }
    }

    private var challengeDescription: String {
        switch viewModel.type {
        case .plank:
            return "Chaque jour, tu publies une preuve de ton gainage. L'objectif est de tenir la routine sans interruption pendant toute la durée du défi."
        case .reading:
            return "Chaque jour, tu partages une preuve de ta lecture (pages lues, extrait, photo). Le but est d'avancer régulièrement et de garder le rythme."
        case .food:
            return "Chaque jour, tu publies un repas équilibré. Tu peux configurer le nombre d'écarts autorisés pour rester motivé tout au long du défi."
        case .drawing:
            return "Chaque jour, tu partages un dessin basé sur le mot du jour. L'objectif est de créer une routine créative simple et régulière."
        }
    }

    private var exampleImageName: String {
        switch viewModel.type {
        case .plank: return "plank-template"
        case .reading: return "reading-template"
        case .food: return "food-Template"
        case .drawing: return "draw-template"
        }
    }

    private var exampleCaption: String {
        switch viewModel.type {
        case .plank: return "Exemple : photo ou capture de séance de gainage."
        case .reading: return "Exemple : photo du livre et des pages lues."
        case .food: return "Exemple : photo d'un repas healthy du jour."
        case .drawing: return "Exemple : dessin du jour inspiré par le mot révélé."
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

    @ViewBuilder
    private var configurationSection: some View {
        switch viewModel.becapConfiguration {
        case .plank(let config):
            PlankConfigurationView(config: config,
                                   onChange: { viewModel.becapConfiguration = .plank($0) })

        case .reading(let config):
            ReadingConfigurationView(config: config,
                                     onChange: { viewModel.becapConfiguration = .reading($0) })

        case .food(let config):
            FoodConfigurationView(config: config,
                                  onChange: { viewModel.becapConfiguration = .food($0) })

        case .drawing(let config):
            DrawingConfigurationView(config: config,
                                     onChange: { viewModel.becapConfiguration = .drawing($0) })
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
                    viewModel.createBecapChallenge { createdChallenge in
                        guard let createdChallenge else { return }

                        guard let items = ChallengeShareBuilder.makeShareItems(for: createdChallenge) else {
                            dismiss()
                            return
                        }

                        shouldDismissAfterShare = true
                        shareSheetPayload = ChallengeShareSheetPayload(items: items)
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "flag.2.crossed")
                            .font(.system(size: 18, weight: .semibold))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Créer le défi")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                            Text("Lancez le défi : le partage s’ouvrira automatiquement.")
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
            }
        }
    }
}

// MARK: Notifications setting
extension CreateBecapChallengeView {
    private var notificationsSetting: some View {
        let notifSettingColumns = [GridItem(.flexible(), spacing: 12),
                                   GridItem(.flexible(), spacing: 12)]

        return VStack(spacing: 18) {
            Text("Notifications quotidiennes")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 12) {
                notificationExplanation

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


    private var notificationExplanation: some View {
        VStack(alignment: .leading, spacing: 12) {
            notificationExplanationRow(title: "Pour tout le monde",
                                       message: "Les heures ajoutées à la création deviennent les rappels par défaut du défi. Elles seront visibles et proposées à tous les participants.",
                                       icon: "person.3.fill")

            Divider()
                .overlay(Color.white.opacity(0.18))

            notificationExplanationRow(title: "Pour moi",
                                       message: "Après la création, chacun peut aller dans l’onglet Notifications pour copier ces heures, les modifier ou ajouter ses propres rappels sans impacter le groupe.",
                                       icon: "person.fill")
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private func notificationExplanationRow(title: String, message: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.9))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundColor(.white)

                Text(message)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }
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

struct PlankConfigurationView: View {
    let config: PlankConfig
    let onChange: (PlankConfig) -> Void

    @State private var seconds: Int

    init(config: PlankConfig, onChange: @escaping (PlankConfig) -> Void) {
        self.config = config
        self.onChange = onChange
        _seconds = State(initialValue: config.secondsPerDay)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Durée du gainage par jour")
                .font(.headline)

            Stepper(value: $seconds, in: 10...600, step: 10) {
                Text("\(seconds) secondes")
            }
            .onChange(of: seconds) { seconds in
                onChange(PlankConfig(secondsPerDay: seconds))
            }
        }
    }
}


struct ReadingConfigurationView: View {
    let config: ReadingConfig
    let onChange: (ReadingConfig) -> Void

    @State private var pages: Int

    init(config: ReadingConfig, onChange: @escaping (ReadingConfig) -> Void) {
        self.config = config
        self.onChange = onChange
        _pages = State(initialValue: config.pagesPerDay)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pages à lire par jour")
                .font(.headline)

            Stepper(value: $pages, in: 1...200) {
                Text("\(pages) pages")
            }
            .onChange(of: pages) { pages in
                onChange(ReadingConfig(pagesPerDay: pages))
            }
        }
    }
}

struct FoodConfigurationView: View {
    let config: FoodConfig
    let onChange: (FoodConfig) -> Void

    @State private var meals: Int

    init(config: FoodConfig, onChange: @escaping (FoodConfig) -> Void) {
        self.config = config
        self.onChange = onChange
        _meals = State(initialValue: config.cheatMealsAllowed)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Repas à respecter par jour")
                .font(.headline)

            Stepper(value: $meals, in: 1...6) {
                Text("\(meals) repas")
            }
            .onChange(of: meals) { meals in
                onChange(FoodConfig(cheatMealsAllowed: meals))
            }
        }
    }
}

struct DrawingConfigurationView: View {
    let config: DrawingConfig
    let onChange: (DrawingConfig) -> Void

    @State private var drawingsPerDay: Int

    init(config: DrawingConfig, onChange: @escaping (DrawingConfig) -> Void) {
        self.config = config
        self.onChange = onChange
        _drawingsPerDay = State(initialValue: config.drawingsPerDay)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Dessins à publier par jour")
                .font(.headline)

            Stepper(value: $drawingsPerDay, in: 1...5) {
                Text("\(drawingsPerDay) dessin\(drawingsPerDay > 1 ? "s" : "")")
            }
            .onChange(of: drawingsPerDay) { drawingsPerDay in
                onChange(DrawingConfig(drawingsPerDay: drawingsPerDay))
            }
        }
    }
}
