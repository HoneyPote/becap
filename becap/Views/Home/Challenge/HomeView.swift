//
//  HomeView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

// TODO: Faire un bouton réutilisable pour les challenges et join et create
struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()

    @State private var showJoinView = false
    @State private var showNewChallengeView = false
    @State private var showCreationToast = false
    @State private var selectedPremiumChallenge: PremiumChallenge?
    @State private var infoPremiumChallenge: PremiumChallenge?
    @State private var showPaymentSheet = false
    @State private var showUnlockToast = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.petrolToSky.ignoresSafeArea()

                VStack(alignment: .center) {
                    Text("⛿ BE CAP ⛿")
                        .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                        .textCase(.uppercase)
                        .foregroundColor(.white)
                        .padding(.top, 42)
                        .padding(.bottom, 12)
                        .padding(.horizontal, 24)

                    ScrollView {
                        VStack(alignment: .leading, spacing: .zero) {
                            premiumChallengesSection

                            joinCreateChallengeSection

                            challengeListSection
                        }
                        .padding(.top, 0)
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
        }
    }

    private var challengeCreatedToast: some View {
        // TODO: Améliorer je sais pas trop comment
        ToastView(message: "Défi créé avec succès 🎉", type: .success)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        showCreationToast = false
                    }
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
