//
//  HomeView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

enum HomeSheet: Identifiable {
    case share
    case newChallenge
    case report(Challenge)
    case paywall
    case challengePaywall(Challenge)

    var id: String {
        switch self {
        case .share:
            return "share"
        case .newChallenge:
            return "new"
        case .paywall:
            return "paywall"
        case .challengePaywall(let challenge):
            return "challenge-paywall-\(challenge.id)"
        case .report(let challenge):
            return "report-\(challenge.id)"
        }
    }
}

// TODO: Faire un bouton réutilisable pour les challenges de partage et création
struct HomeView: View {
    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter
    @EnvironmentObject private var store: StoreManager
    @StateObject var viewModel = HomeViewModel()

    @State private var showCreationToast = false
    @State private var sheet: HomeSheet?
    @State private var isProcessingPayment = false
    @State private var paymentErrorMessage: String?
    @State private var deepLinkedChallenge: Challenge?
    @State private var navigateToDeepLinkedChallenge = false
    @State private var isResolvingDeepLink = false
    @State private var hasLoadedChallengesForPendingDeepLink = false
    @State private var deepLinkedPostId: String?
    @State private var deepLinkJoinError: String?

    var body: some View {
        NavigationStack {
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
                        shareCreateChallengeSection
                        premiumChallengesSection
                        challengeListSection
                    }
                    .padding(.horizontal)
                }
            }
            .overlay {
                if let error = viewModel.deleteChallengeError {
                    deleteChallengeErrorView(error: error)
                }
            }
            .overlay(alignment: .top) {
                if viewModel.showReportSuccessToast {
                    reportSuccessToast
                }
            }
            .background(
                Image(homeBackgroundImageName)
                    .resizable()
                    .scaledToFill()
                    .offset(x: -60)
                    .overlay(Color.black.opacity(0.15))
                    .ignoresSafeArea()
            )
            .withTabBarInset()
            .navigationBarHidden(true)
            .background(deepLinkNavigationLink) // lien de deep link caché
        }
        .refreshable { viewModel.refreshChallenges() }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .share:
                ShareChallengeView()
            case .newChallenge:
                NewChallengeView(challengeCreated: $showCreationToast)
            case .paywall:
                PaywallView()
            case .challengePaywall(let challenge):
                ChallengePaywallView(
                    challenge: challenge,
                    isProcessing: $isProcessingPayment,
                    errorMessage: paymentErrorMessage,
                    onApplePay: { startPayment(for: challenge, method: .applePay) },
                    onCard: { startPayment(for: challenge, method: .card) },
                    onClose: closePaymentSheet
                )
            case .report(let challenge):
                ReportContentView(
                    challenge: challenge,
                    isSubmitting: $viewModel.isSubmittingReport,
                    errorMessage: $viewModel.reportErrorMessage,
                    onSubmit: { reason, details in
                        viewModel.submitReport(reason: reason, details: details) },
                    onCancel: { viewModel.cancelReport() }
                )
                .onDisappear { viewModel.cancelReport() }
            }
        }
        .overlay(alignment: .top) {
            if showCreationToast {
                challengeCreatedToast
                    .padding(.bottom, 40)
            }
        }
        .onChange(of: viewModel.challengeToReport) { challenge in
            guard let challenge else { return }
            sheet = .report(challenge)
        }
        .onAppear {
            if let challengeId = deepLinkRouter.pendingCalendarChallengeId {
                beginResolvingDeepLink(for: challengeId)
            }
        }
        .onChange(of: deepLinkRouter.pendingCalendarChallengeId) { challengeId in
            guard let challengeId else {
                isResolvingDeepLink = false
                hasLoadedChallengesForPendingDeepLink = false
                if !navigateToDeepLinkedChallenge { deepLinkedPostId = nil }
                return
            }
            beginResolvingDeepLink(for: challengeId)
        }
        .onChange(of: deepLinkRouter.pendingPostLink) { link in
            guard let link else { return }

            if let challenge = deepLinkedChallenge, challenge.id == link.challengeId {
                deepLinkedPostId = link.postId
            }

            if isResolvingDeepLink,
               hasLoadedChallengesForPendingDeepLink,
               let pendingId = deepLinkRouter.pendingCalendarChallengeId,
               pendingId == link.challengeId {
                attemptNavigationToChallenge(withId: link.challengeId)
            }
        }
        .onChange(of: viewModel.challenges) { _ in
            guard isResolvingDeepLink,
                  let challengeId = deepLinkRouter.pendingCalendarChallengeId else { return }
            hasLoadedChallengesForPendingDeepLink = true
            attemptNavigationToChallenge(withId: challengeId)
        }
        .alert("Impossible de rejoindre le défi", isPresented: Binding(
            get: { deepLinkJoinError != nil },
            set: { if !$0 { deepLinkJoinError = nil } }
        )) {
            Button("OK", role: .cancel) { deepLinkJoinError = nil }
        } message: {
            Text(deepLinkJoinError ?? "Une erreur inattendue est survenue. Veuillez réessayer plus tard.")
        }
        .alert("Delete this challenge?", isPresented: $viewModel.showDeleteAlert) {
            deleteChallengeConfirmationAlert
        }
    }

    private var shareCreateChallengeSection: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 18) {
            ShareButtonCell {
                sheet = .share
            }

            NewChallengeCell {
                sheet = .newChallenge
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
                Text("LISTE DES DÉFIS")
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
                ForEach(viewModel.standardChallenges) { challenge in
                    let locked = viewModel.isLocked(challenge, hasPremium: store.hasPremiumAccess)
                    if locked {
                        LockedChallengeCell(challenge: challenge) {
                            sheet = .paywall
                        }
                    } else {
                        NavigationLink(destination: CalendarDetailView(challenge: challenge)) {
                            DefiCell(challenge: challenge,
                                     onDelete: { viewModel.confirmDelete(challenge) },
                                     onReport: { viewModel.presentReport(for: challenge) })
                        }
                    }
                }
            }
        }
    }

    private var challengeCreatedToast: some View {
        ToastView(message: "Défi créé avec succès 🎉", type: .success)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showCreationToast = false }
                }
            }
    }

    private var deleteChallengeConfirmationAlert: some View {
        Group {
            Button("Delete", role: .destructive) { viewModel.performDelete() }
            Button("Cancel", role: .cancel) { viewModel.cancelDelete() }
        }
    }

    private var premiumChallengesSection: some View {
        Group {
            if !viewModel.premiumChallenges.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .imageScale(.large)
                        Text("CHALLENGE PRENIUM")
                            .font(.system(.title2, design: .rounded).weight(.heavy))
                            .textCase(.uppercase)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 26)
                    .padding(.horizontal, 6)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 170))], spacing: 18) {
                        ForEach(viewModel.premiumChallenges) { challenge in
                        let locked = viewModel.isLocked(challenge, hasPremium: store.hasPremiumAccess)
                        if locked {
                            LockedChallengeCell(challenge: challenge) {
                                paymentErrorMessage = nil
                                sheet = .challengePaywall(challenge)
                            }
                        } else {
                                NavigationLink(destination: CalendarDetailView(challenge: challenge)) {
                                    DefiCell(challenge: challenge,
                                             onDelete: { viewModel.confirmDelete(challenge) },
                                             onReport: { viewModel.presentReport(for: challenge) })
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }

    private func startPayment(for challenge: Challenge, method: PaymentMethod) {
        guard viewModel.isLocked(challenge, hasPremium: store.hasPremiumAccess) else {
            paymentErrorMessage = "Ce challenge est déjà débloqué."
            return
        }

        paymentErrorMessage = nil
        isProcessingPayment = true

        PaymentCoordinator.shared.startPayment(for: challenge, method: method) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    Task { await handleSuccessfulPayment(for: challenge) }
                case .failure(let error):
                    paymentErrorMessage = error.localizedDescription
                    isProcessingPayment = false
                }
            }
        }
    }

    private func handleSuccessfulPayment(for challenge: Challenge) async {
        do {
            try await viewModel.unlockChallenge(challenge)

            await MainActor.run {
                isProcessingPayment = false
                paymentErrorMessage = nil
                closePaymentSheet()
            }
        } catch {
            await MainActor.run {
                paymentErrorMessage = error.localizedDescription
                isProcessingPayment = false
            }
        }
    }

    private func closePaymentSheet() {
        sheet = nil
        paymentErrorMessage = nil
        isProcessingPayment = false
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
            .padding(.bottom, 88)
        }
        .onAppear { viewModel.onAppearDeleteChallengeError() }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .zIndex(10)
    }

    private var reportSuccessToast: some View {
        VStack {
            Spacer()
            ToastView(message: "Signalement envoyé. Merci !", type: .success)
                .padding(.bottom, 40)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { viewModel.showReportSuccessToast = false }
                    }
                }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .zIndex(11)
    }
}

extension HomeView {
    @ViewBuilder
    private var deepLinkNavigationLink: some View {
        NavigationLink(destination: deepLinkNavigationDestination,
                       isActive: $navigateToDeepLinkedChallenge) {
            EmptyView()
        }
        .hidden()
    }

    @ViewBuilder
    private var deepLinkNavigationDestination: some View {
        if let challenge = deepLinkedChallenge {
            CalendarDetailView(challenge: challenge, initialPostId: deepLinkedPostId)
                .id(calendarDetailIdentity(for: challenge, postId: deepLinkedPostId))
                .onDisappear { deepLinkedPostId = nil }
        } else {
            EmptyView()
        }
    }

    private func calendarDetailIdentity(for challenge: Challenge, postId: String?) -> String {
        let base = challenge.id
        if let postId, !postId.isEmpty {
            return "\(base)|photo:\(postId)"
        }
        return "\(base)|calendar"
    }

    private func beginResolvingDeepLink(for challengeId: String) {
        isResolvingDeepLink = true
        hasLoadedChallengesForPendingDeepLink = viewModel.challenges.contains(where: { $0.id == challengeId })
        attemptNavigationToChallenge(withId: challengeId)

        Task { [challengeId] in
            do {
                try await viewModel.ensureMembershipIfNeeded(for: challengeId)
            } catch {
                await MainActor.run {
                    deepLinkJoinError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    isResolvingDeepLink = false
                    deepLinkRouter.clearChallengeNavigation()
                    deepLinkRouter.clearPostNavigation()
                }
            }
        }

        if !hasLoadedChallengesForPendingDeepLink {
            viewModel.refreshChallenges()
        }
    }

    private func attemptNavigationToChallenge(withId challengeId: String) {
        if let challenge = viewModel.challenges.first(where: { $0.id == challengeId }) {
            deepLinkedChallenge = challenge
            if let link = deepLinkRouter.pendingPostLink,
               link.challengeId == challengeId {
                deepLinkedPostId = link.postId
            } else {
                deepLinkedPostId = nil
            }
            navigateToDeepLinkedChallenge = true
            isResolvingDeepLink = false

            deepLinkRouter.clearChallengeNavigation()
            deepLinkRouter.clearPostNavigation()
        }
    }
}

private extension HomeView {
    var homeBackgroundImageName: String {
        viewModel.challenges.contains(where: { $0.isLastDayToday }) ? "sunset" : "epicPic"
    }
}
