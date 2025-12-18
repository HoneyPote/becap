//
//  CoachProgramDetailView.swift
//  becap
//
//  Created by OpenAI Assistant on 2025-xx-xx.
//
//  Architecture plan (coach programs)
//  ---------------------------------
//  - Challenge carries coach-program metadata (creator, hero image, day plan) and enrollments still gate access via the
//    shared ChallengeEnrollment model.
//  - Home renders coach programs with a dedicated hero card; tapping opens this detail view with tabs for Overview / Today / Community.
//  - The detail view listens to the enrollment document + creator updates via ChallengeManager/Firestore, derives lock state from
//    enrollment.paymentStatus, and surfaces the existing paywall through a callback when locked.
//  - “Today” reads the enrollment date + challenge.dayPlan to show the current instruction and routes check-ins to the existing calendar/post flow.

import SwiftUI
import FirebaseFirestore

enum CoachProgramTab: String, CaseIterable, Identifiable {
    case overview
    case today
    case community

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .today: return "Aujourd’hui"
        case .community: return "Communauté"
        }
    }
}

final class CoachProgramDetailViewModel: ObservableObject {
    @Published var enrollment: ChallengeEnrollment?
    @Published var creatorUpdates: [CreatorUpdate] = []
    @Published var enrollmentCount: Int = 0

    private var enrollmentListener: ListenerRegistration?
    private var updatesListener: ListenerRegistration?

    private let challengeManager: ChallengeManager
    private let challenge: Challenge

    init(challenge: Challenge, challengeManager: ChallengeManager = .shared) {
        self.challengeManager = challengeManager
        self.challenge = challenge
    }

    deinit {
        enrollmentListener?.remove()
        updatesListener?.remove()
    }

    func startListening() {
        guard let userId = challengeManager.currentUser?.id, !challenge.id.isEmpty else { return }

        enrollmentListener = challengeManager.listenEnrollment(for: challenge.id, userId: userId) { [weak self] enrollment in
            DispatchQueue.main.async {
                self?.enrollment = enrollment
            }
        }

        updatesListener = challengeManager.listenCreatorUpdates(for: challenge.id) { [weak self] updates in
            DispatchQueue.main.async {
                self?.creatorUpdates = updates
            }
        }

        Task { [weak self] in
            guard let self else { return }
            let count = (try? await challengeManager.enrollmentCount(for: challenge.id)) ?? 0
            await MainActor.run {
                self.enrollmentCount = count
            }
        }
    }

    func stopListening() {
        enrollmentListener?.remove()
        updatesListener?.remove()
        enrollmentListener = nil
        updatesListener = nil
    }

    func isLocked(for userId: String?) -> Bool {
        challenge.isLocked(for: userId, enrollment: enrollment)
    }
}

struct CoachProgramDetailView: View {
    let challenge: Challenge
    let onUnlock: () -> Void

    @StateObject private var viewModel: CoachProgramDetailViewModel
    @State private var selectedTab: CoachProgramTab = .overview
    @State private var goToCalendar = false

    private var currentUserId: String? { ChallengeManager.shared.currentUser?.id }

    init(challenge: Challenge, onUnlock: @escaping () -> Void) {
        self.challenge = challenge
        self.onUnlock = onUnlock
        _viewModel = StateObject(wrappedValue: CoachProgramDetailViewModel(challenge: challenge))
    }

    private var isLocked: Bool { viewModel.isLocked(for: currentUserId) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                tabPicker
                tabContent
                NavigationLink(destination: CalendarDetailView(challenge: challenge), isActive: $goToCalendar) {
                    EmptyView()
                }
                .frame(width: 0, height: 0)
                .hidden()
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .principal) { EmptyView() } }
        .onAppear { viewModel.startListening() }
        .onDisappear { viewModel.stopListening() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: challenge.heroImageUrl ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure(_), .empty:
                        LinearGradient(colors: [.purple.opacity(0.4), .blue.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    @unknown default:
                        Color.gray
                    }
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(
                    LinearGradient(colors: [Color.black.opacity(0.6), Color.black.opacity(0.15)], startPoint: .bottom, endPoint: .top)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))

                HStack(alignment: .center, spacing: 14) {
                    avatar(size: 64)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(challenge.title)
                            .font(.title3.weight(.bold))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        if let coachName = challenge.coachName {
                            Text(coachName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white.opacity(0.9))
                        }

                        HStack(spacing: 8) {
                            if let duration = challenge.durationDays {
                                pill(icon: "calendar", text: "\(duration) jours")
                            }
                            if let difficulty = challenge.difficultyLabel, !difficulty.isEmpty {
                                pill(icon: "bolt.fill", text: difficulty)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(16)
            }

            if let tagline = challenge.shortTagline {
                Text(tagline)
                    .font(.headline)
                    .foregroundColor(.white)
            }

            HStack(spacing: 12) {
                pill(icon: "person.3.fill", text: "\(viewModel.enrollmentCount) inscrits")
                if !isLocked {
                    pill(icon: "checkmark.seal.fill", text: "Accès débloqué")
                }
            }
        }
    }

    private var tabPicker: some View {
        Picker("Tab", selection: $selectedTab) {
            ForEach(CoachProgramTab.allCases) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:
            overviewSection
        case .today:
            todaySection
        case .community:
            communitySection
        }
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let description = challenge.longDescription {
                Text(description)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.leading)
            } else {
                Text("Programme conçu par le coach pour un accompagnement quotidien et des résultats mesurables.")
                    .foregroundColor(.white.opacity(0.9))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Comment ça marche")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Rejoins le programme, suis les consignes quotidiennes et partage ton check-in photo pour garder la motivation.")
                    .foregroundColor(.white.opacity(0.9))
            }

            primaryCTA
        }
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isLocked {
                Text("Rejoins le programme pour voir les consignes du jour.")
                    .foregroundColor(.white.opacity(0.85))
                primaryCTA
            } else if let plan = currentDayPlanItem {
                Text("Jour \(plan.dayIndex)")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(plan.title)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                Text(plan.description)
                    .foregroundColor(.white.opacity(0.9))
                Button(action: { goToCalendar = true }) {
                    Text("Poster mon check-in")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            } else {
                Text("Consigne du jour non définie. Continue ta progression !")
                    .foregroundColor(.white.opacity(0.9))
                Button(action: { goToCalendar = true }) {
                    Text("Ouvrir le calendrier")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
    }

    private var communitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Updates du coach")
                .font(.headline)
                .foregroundColor(.white)

            if viewModel.creatorUpdates.isEmpty {
                Text("Aucune mise à jour publiée pour le moment.")
                    .foregroundColor(.white.opacity(0.8))
            } else {
                ForEach(viewModel.creatorUpdates) { update in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(update.text)
                            .foregroundColor(.white)
                        Text(update.createdAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        if let urlString = update.mediaUrl, let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                default:
                                    Color.gray.opacity(0.2)
                                }
                            }
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Participants")
                    .font(.headline)
                    .foregroundColor(.white)
                Button(action: { goToCalendar = true }) {
                    Text("Voir les photos des participants")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
    }

    private var primaryCTA: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isLocked {
                Button(action: onUnlock) {
                    Text("Rejoindre le programme – \(challenge.formattedPrice)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            } else {
                Button(action: { goToCalendar = true }) {
                    Text("Accéder à la séance du jour")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
    }

    private var currentDayPlanItem: CoachDayPlanItem? {
        guard let enrollmentDate = viewModel.enrollment?.createdAt else { return nil }
        guard let plan = challenge.dayPlan else { return nil }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: enrollmentDate)
        let today = calendar.startOfDay(for: Date())
        let components = calendar.dateComponents([.day], from: start, to: today)
        let dayIndex = (components.day ?? 0) + 1

        return plan.first(where: { $0.dayIndex == dayIndex })
    }

    private func avatar(size: CGFloat) -> some View {
        AsyncImage(url: URL(string: challenge.coachAvatarUrl ?? "")) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure(_), .empty:
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white.opacity(0.8))
            @unknown default:
                Color.white.opacity(0.3)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))
    }

    private func pill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.14))
        .clipShape(Capsule())
    }
}
