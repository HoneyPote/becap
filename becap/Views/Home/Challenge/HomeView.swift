//
//  HomeView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//


import SwiftUI

struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()

    @State private var showJoinView = false
    @State private var showNewChallengeView = false
    @State private var showCreationToast = false

    // Premium payment / info
    @State private var selectedPremiumChallenge: PremiumChallenge?
    @State private var infoPremiumChallenge: PremiumChallenge?
    @State private var showPaymentSheet = false
    @State private var showUnlockToast = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.petrolToSky.ignoresSafeArea()

                VStack(alignment: .center) {
                    // Header
                    Text("⛿ BE CAP ⛿")
                        .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                        .textCase(.uppercase)
                        .foregroundColor(.white)
                        .padding(.top, 42)
                        .padding(.bottom, 12)
                        .padding(.horizontal, 24)

                    ScrollView {
                        VStack(alignment: .leading, spacing: .zero) {


                            joinCreateChallengeSection

                            challengeListSection

                            premiumChallengesSection
                        }
                        .padding(.horizontal)
                    }
                }

                if let error = viewModel.deleteChallengeError {
                    deleteChallengeErrorView(error: error)
                }
            }
            .alert("Delete this challenge?", isPresented: $viewModel.showDeleteAlert) {
                deleteChallengeConfirmationAlert
            }
            .navigationBarHidden(true)
        }
        .refreshable { viewModel.refreshChallenges() }
        .sheet(isPresented: $showJoinView) {
            JoinChallengeView()
        }
        .sheet(isPresented: $showNewChallengeView) {
            NewChallengeView(challengeCreated: $showCreationToast)
        }
        .overlay(alignment: .top) {
            if showCreationToast {
                challengeCreatedToast
                    .padding(.bottom, 40)
            }
            if showUnlockToast {
                premiumChallengeUnlockedToast
                    .padding(.top, 32)
            }
        }
        .overlay {
            if let infoPremiumChallenge {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    PremiumChallengeInfoBubble(
                        challenge: infoPremiumChallenge,
                        onClose: { withAnimation(.spring()) { self.infoPremiumChallenge = nil } }
                    )
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $showPaymentSheet) {
            if let challenge = selectedPremiumChallenge {
                PremiumPaymentOptionsView(
                    challenge: challenge,
                    onPayment: { method in
                        Task { await handlePaymentSuccess(for: challenge, method: method) }
                    },
                    onCancel: { dismissPaymentSheet() }
                )
            }
        }
    }

    // MARK: - Premium section

    private var premiumChallengesSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "lock.rectangle.on.rectangle")
                    .font(.title2)
                    .foregroundColor(.white)
                Text("Challenges Premium")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundColor(.white)
                    .textCase(.uppercase)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 4)

            VStack(spacing: 14) {
                ForEach(viewModel.premiumChallenges, id: \.id) { premium in
                    PremiumChallengeCell(
                        challenge: premium,
                        onUnlockTapped: { presentPaymentSheet(for: premium) },
                        onInfoTapped: { presentInfoBubble(for: premium) }
                    )
                }
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Join / Create

    private var joinCreateChallengeSection: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 18) {
            JoinButtonCell {
                showJoinView = true
            }
            NewChallengeCell {
                showNewChallengeView = true
            }
        }
    }

    // MARK: - Challenge list

    private var challengeListSection: some View {
        Group {
            HStack(spacing: 10) {
                Image("list_white")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
                Text("LISTE DES DEFIS")
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .textCase(.uppercase)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 34)
            .padding(.bottom, 14)
            .padding(.horizontal, 24)
            .multilineTextAlignment(.center)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 18) {
                ForEach(viewModel.challenges) { challenge in
                    NavigationLink(destination: CalendarDetailView(challenge: challenge)) {
                        DefiCell(challenge: challenge, onDelete: { viewModel.confirmDelete(challenge) })
                    }
                }
            }
            .padding(.bottom, 30)
        }
    }

    // MARK: - Toasts / Alerts

    private var challengeCreatedToast: some View {
        ToastView(message: "Défi créé avec succès 🎉", type: .success)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showCreationToast = false }
                }
            }
    }

    private var premiumChallengeUnlockedToast: some View {
        ToastView(message: "Challenge premium débloqué ✨", type: .success)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    withAnimation { showUnlockToast = false }
                }
            }
    }

    private var deleteChallengeConfirmationAlert: some View {
        Group {
            Button("Delete", role: .destructive) {
                viewModel.performDelete()
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelDelete()
            }
        }
    }

    private func deleteChallengeErrorView(error: String) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(error)
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 22)
                    .background(Color.red.opacity(0.92))
                    .cornerRadius(28)
                    .shadow(radius: 12)

                Button(action: {
                    withAnimation { viewModel.deleteChallengeError = nil }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                .padding(.leading, 4)
                Spacer()
            }
            .padding(.bottom, 38)
        }
        .onAppear { viewModel.onAppearDeleteChallengeError() }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .zIndex(10)
    }
}

// MARK: - Premium helpers
extension HomeView {
    private func presentPaymentSheet(for challenge: PremiumChallenge) {
        selectedPremiumChallenge = challenge
        showPaymentSheet = true
    }

    private func presentInfoBubble(for challenge: PremiumChallenge) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82, blendDuration: 0.15)) {
            infoPremiumChallenge = challenge
        }
    }

    private func handlePaymentSuccess(for challenge: PremiumChallenge, method _: PremiumPaymentOptionsView.PaymentMethod) async {
        // Simule un petit délai de traitement
        try? await Task.sleep(nanoseconds: 350_000_000)

        await MainActor.run {
            viewModel.unlockPremiumChallenge(challenge)
            showUnlockToast = true
            dismissPaymentSheet()
        }
    }

    private func dismissPaymentSheet() {
        withAnimation { showPaymentSheet = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            selectedPremiumChallenge = nil
        }
    }
}

//
// MARK: - Fallback minimal components (remplace-les par tes versions si tu en as)
//

private struct PremiumChallengeCell: View {
    let challenge: PremiumChallenge
    let onUnlockTapped: () -> Void
    let onInfoTapped: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Vignette simple (texte/vidéo)
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.blue.opacity(0.12))
                Text(thumbnailText)
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(challenge.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.75))

                HStack(spacing: 8) {
                    if challenge.isUnlocked {
                        Label("Déverrouillé", systemImage: "checkmark.seal.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.green)
                    } else {
                        Text(priceString)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.top, 4)
            }

            Spacer()

            if challenge.isUnlocked == false {
                Button(action: onUnlockTapped) {
                    Text("Débloquer")
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                }
            } else {
                Button(action: onInfoTapped) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(alignment: .topTrailing) {
            if !challenge.isUnlocked {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .padding(6)
                    .background(.thinMaterial, in: Circle())
                    .offset(x: -8, y: -8)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onInfoTapped() }
    }

    private var priceString: String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = challenge.currencyCode
        return nf.string(from: challenge.price as NSDecimalNumber) ?? "\(challenge.price) \(challenge.currencyCode)"
    }

    private var thumbnailText: String {
        switch challenge.media {
        case .text:  "TEXTE"
        case .video: "VIDÉO"
        }
    }
}

private struct PremiumChallengeInfoBubble: View {
    let challenge: PremiumChallenge
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(challenge.title)
                    .font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(challenge.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            switch challenge.media {
            case .text(let body):
                Text(body)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            case .video:
                Text("Contenu vidéo (aperçu désactivé ici)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: 520)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.25), lineWidth: 0.7)
        )
        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 12)
    }


}

// PremiumChallengeMapper.swift
import Foundation

// PremiumChallengeMapper.swift
import Foundation

enum PremiumBlueprint {
    /// Transforme un PremiumChallenge en un vrai Challenge Firestore
    static func makeChallenge(from premium: PremiumChallenge, currentUserId: String) -> Challenge {
        Challenge(
            id: nil,
            title: premium.title,
            duration: suggestedDuration(for: premium),
            startDate: Date(),
            creatorUID: currentUserId,
            participantUids: [currentUserId],
            notificationsConfig: nil,
            code: nil
        )
    }

    private static func suggestedDuration(for premium: PremiumChallenge) -> Int {
        // Heuristique basique: déduis la durée depuis le titre
        let lower = premium.title.lowercased()
        if lower.contains("30") { return 30 }
        if lower.contains("14") { return 14 }
        if lower.contains("7")  { return 7 }
        if lower.contains("100") { return 100 }
        return 21 // défaut si on ne trouve rien
    }
}
