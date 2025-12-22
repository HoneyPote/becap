//
//  SettingsView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI
import PhotosUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject private var challengeManager = ChallengeManager.shared

    @State private var showingLogoutAlert = false
    @State private var showingDeleteAccountDialog = false

    // Reporting flow state
    @State private var showReportSelector = false
    @State private var challengeToReport: Challenge?
    @State private var isSubmittingReport = false
    @State private var reportErrorMessage: String?
    @State private var showReportSuccessToast = false

    // NEW: avatar picker state
    @State private var avatarItem: PhotosPickerItem?
    @State private var isUploadingAvatar = false
    @State private var showingMedalsPopover = false
    @State private var scoringDescription: String = ""
    @State private var scoringResult: String?
    @State private var scoringError: String?
    @State private var isScoring: Bool = false

    private let reportManager: ReportManagerProtocol = ReportManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        HStack {
                            Spacer()
                            Text("Paramètres")
                                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            Spacer()
                        }

                        if let currentUser = viewModel.currentUser {
                            GlassCard { headerProfile(user: currentUser) }
                                .padding(.horizontal)
                        }

                        GlassCard { medalSection }
                            .padding(.horizontal)

                        GlassCard { navigationList }
                            .padding(.horizontal)

                        GlassCard { scoringTestSection }
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .overlay(alignment: .bottom) {
                    // --- TOASTS EN BAS ---
                    if showReportSuccessToast || viewModel.accountDeletionError != nil {
                        VStack(spacing: 16) {
                            if showReportSuccessToast {
                                ToastView(message: "Signalement envoyé. Merci !", type: .success)
                                    .onAppear { scheduleReportSuccessDismissal() }
                            }
                            if let deletionError = viewModel.accountDeletionError {
                                ToastView(message: deletionError, type: .error)
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                            withAnimation { viewModel.accountDeletionError = nil }
                                        }
                                    }
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
                .overlay {
                    // --- OVERLAY LOADING SUPPRESSION COMPTE ---
                    if viewModel.isDeletingAccount {
                        ZStack {
                            Color.black.opacity(0.35).ignoresSafeArea()
                            VStack(spacing: 16) {
                                ProgressView()
                                Text("Suppression du compte…")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding(28)
                            .background(Color.black.opacity(0.65))
                            .cornerRadius(16)
                        }
                        .transition(.opacity)
                    }
                }
                .withTabBarInset()
            }
            .background(
                Image("iphone_wallpaper_lake")
                    .resizable()
                    .scaledToFill()
                    .overlay(Color.black.opacity(0.25))
                    .offset(x: -23)
                    .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Paramètres")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundColor(.white)
                }
            }
            .navigationBarHidden(true)
            .confirmationDialog("Déconnexion", isPresented: $showingLogoutAlert, titleVisibility: .visible) {
                Button("Déconnexion", role: .destructive) { viewModel.signOut() }
                Button("Annuler", role: .cancel) {}
            }
            .confirmationDialog("Supprimer mon compte ?", isPresented: $showingDeleteAccountDialog, titleVisibility: .visible) {
                Button("Supprimer définitivement", role: .destructive) { viewModel.deleteAccount() }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Cette action supprimera votre compte, vos données de profil et votre historique de défis. Cette action est irréversible.")
            }
        }
        .task {
            try? await challengeManager.fetchAndFilterChallenges()
        }
        .sheet(isPresented: $showReportSelector) {
            ReportChallengeSelectorView(
                challenges: challengeManager.challenges,
                onSelect: { challenge in
                    challengeToReport = challenge
                    reportErrorMessage = nil
                }
            )
        }
        .sheet(item: $challengeToReport) { challenge in
            ReportContentView(
                challenge: challenge,
                isSubmitting: $isSubmittingReport,
                errorMessage: $reportErrorMessage,
                onSubmit: { reason, details in
                    submitReport(for: challenge, reason: reason, details: details)
                },
                onCancel: { cancelReport() }
            )
        }
    }

    // MARK: - Header (wrapper)

    private func headerProfile(user: User) -> some View {
        ProfileHeader(
            user: user,
            avatarItem: $avatarItem,
            isUploading: $isUploadingAvatar,
            onAvatarPicked: { item in
                Task { await handleAvatarSelection(item: item) }
            }
        )
    }

    // MARK: - Sections

    private var medalSection: some View {
        let medals = viewModel.currentUser?.medals ?? []
        let sorted = medals.sorted { $0.achievedDate > $1.achievedDate }

        return VStack(alignment: .leading, spacing: 12) {
            MedalTriggerRow(
                medalCount: medals.count,
                participantName: viewModel.currentUser?.name ?? "Vous",
                onTap: {
                    if !sorted.isEmpty { showingMedalsPopover = true }
                }
            )
            .popover(isPresented: $showingMedalsPopover, arrowEdge: .top) {
                MedalBubbleView(medals: sorted)
            }
        }
        .onChange(of: medals.count) { count in
            if count == 0 { showingMedalsPopover = false }
        }
    }

    private var navigationList: some View {
        VStack(spacing: 14) {
            Button { showReportSelector = true } label: {
                Label("Signaler un défi", systemImage: "exclamationmark.bubble")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            }

            NavigationLink(destination: LegalDocumentsView()) {
                Label("Mentions légales", systemImage: "doc.text")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            }

            Button(role: .destructive) { showingLogoutAlert = true } label: {
                Label("Déconnexion", systemImage: "arrow.backward.circle")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            }

            Button(role: .destructive) { showingDeleteAccountDialog = true } label: {
                Label("Supprimer mon compte", systemImage: "person.crop.circle.badge.xmark")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            }
        }
    }

    private var scoringTestSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Test scoring OpenAI")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundColor(.white)

            Text("Saisis une description pour tester l'appel au scoring.")
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(.white.opacity(0.72))

            TextField("Description du plat", text: $scoringDescription)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
                .font(.system(.body, design: .rounded))

            Button {
                runScoringTest()
            } label: {
                HStack(spacing: 10) {
                    if isScoring {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                    }

                    Text(isScoring ? "Test en cours..." : "Tester le scoring")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                )
                .foregroundColor(.white)
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(isScoring || scoringDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity((isScoring || scoringDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.7 : 1.0)

            if let scoringResult {
                Text("Résultat : \(scoringResult)")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
            }

            if let scoringError {
                Text("Erreur : \(scoringError)")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.red.opacity(0.85))
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Avatar flow

    @MainActor
    private func handleAvatarSelection(item: PhotosPickerItem) async {
        isUploadingAvatar = true
        defer { isUploadingAvatar = false }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                try await viewModel.updateAvatar(data: data)
            } else {
                print("⚠️ Impossible de charger l'image sélectionnée.")
            }
        } catch {
            print("❌ Upload avatar error: \(error)")
        }
    }

    private func submitReport(for challenge: Challenge, reason: ContentReportReason, details: String) {
        isSubmittingReport = true
        reportErrorMessage = nil

        Task {
            do {
                try await reportManager.submitChallengeReport(challenge: challenge, reason: reason, details: details)
                await MainActor.run {
                    self.isSubmittingReport = false
                    self.challengeToReport = nil
                    self.showReportSuccessToast = true
                }
            } catch {
                await MainActor.run {
                    self.isSubmittingReport = false
                    self.reportErrorMessage = "Impossible d’envoyer le signalement. Veuillez réessayer."
                }
            }
        }
    }

    private func cancelReport() {
        challengeToReport = nil
        isSubmittingReport = false
        reportErrorMessage = nil
    }

    private func scheduleReportSuccessDismissal() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showReportSuccessToast = false }
        }
    }

    private func runScoringTest() {
        let trimmed = scoringDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isScoring = true
        scoringResult = nil
        scoringError = nil

        Task {
            do {
                let result = try await ScoringService.shared.testCulinaryScore(description: trimmed)
                await MainActor.run {
                    if let score = result.score {
                        self.scoringResult = "score = \(score)"
                    } else {
                        self.scoringResult = "score indisponible"
                    }
                    self.isScoring = false
                }
            } catch {
                await MainActor.run {
                    self.scoringError = error.localizedDescription
                    self.isScoring = false
                }
            }
        }
    }
}

//
// MARK: - Subviews (small & compiler-friendly)
//

private struct ProfileHeader: View {
    let user: User
    @Binding var avatarItem: PhotosPickerItem?
    @Binding var isUploading: Bool
    let onAvatarPicked: (PhotosPickerItem) -> Void

    var body: some View {
        VStack(spacing: 12) {
            AvatarEditor(
                avatarUrl: user.photoURL,
                isUploading: isUploading,
                avatarItem: $avatarItem,
                onPicked: onAvatarPicked
            )
            .frame(width: 88, height: 88)

            Text(user.name)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(.white)

            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
    }
}

private struct AvatarEditor: View {
    let avatarUrl: String?
    let isUploading: Bool
    @Binding var avatarItem: PhotosPickerItem?
    let onPicked: (PhotosPickerItem) -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AvatarCircle(avatarUrl: avatarUrl)
                .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 0.7))

            PhotosPicker(selection: $avatarItem, matching: .images) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(.black.opacity(0.35))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 0.7))
                    .padding(4)
            }
            .disabled(isUploading)
        }
        .overlay {
            if isUploading { ProgressView().progressViewStyle(.circular) }
        }
        .onChange(of: avatarItem) { item in
            guard let item else { return }
            onPicked(item)
            avatarItem = nil
        }
    }
}

private struct AvatarCircle: View {
    let avatarUrl: String?

    var body: some View {
        Group {
            if let urlStr = avatarUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Color.white.opacity(0.08).overlay(PlaceholderIcon())
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Color.white.opacity(0.08).overlay(PlaceholderIcon())
                    @unknown default:
                        Color.white.opacity(0.08).overlay(PlaceholderIcon())
                    }
                }
            } else {
                Color.white.opacity(0.08).overlay(PlaceholderIcon())
            }
        }
        .clipShape(Circle())
    }

    private struct PlaceholderIcon: View {
        var body: some View {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.white.opacity(0.92))
                .padding(10)
        }
    }
}

private struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}
