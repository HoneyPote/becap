//
//  HomeView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

// TODO: Faire un bouton réutilisable pour les challenges de partage et création
struct HomeView: View {
    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter
    @StateObject var viewModel = HomeViewModel()

    @State private var showShareChallengeView = false
    @State private var showNewChallengeView = false
    @State private var showCreationToast = false
    @State private var deepLinkedChallenge: Challenge?
    @State private var navigateToDeepLinkedChallenge = false
    @State private var isResolvingDeepLink = false
    @State private var hasLoadedChallengesForPendingDeepLink = false
    @State private var deepLinkedPostId: String?
    @State private var deepLinkJoinError: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: .zero) {
                HStack {
                    Spacer()

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.white)
                            .padding(10)
                    }
                }
                .padding(.horizontal, 24)

                Text("⛿ BE CAP ⛿")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .textCase(.uppercase)
                    .foregroundColor(.white)
                    .padding(.bottom, 12)
                    .padding(.horizontal, 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: .zero) {
                        shareCreateChallengeSection
                        becapChallengeListSection
                        challengeListSection
                    }
                    .padding(.horizontal)
                }
            }
            .overlay {
                if let error = viewModel.quitChallengeError {
                    quitChallengeErrorView(error: error)
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
            .navigationBarHidden(true)
            .background(deepLinkNavigationLink) // hidden deep link
        }
        .refreshable { viewModel.refreshChallenges() }
        .sheet(isPresented: $showShareChallengeView) {
            ShareChallengeView()
        }
        .sheet(isPresented: $showNewChallengeView) {
            NewChallengeView(challengeCreated: $showCreationToast)
        }
        .sheet(item: $viewModel.challengeToReport) { challenge in
            ReportContentView(
                challenge: challenge,
                isSubmitting: $viewModel.isSubmittingReport,
                errorMessage: $viewModel.reportErrorMessage,
                onSubmit: { reason, details in
                    viewModel.submitReport(reason: reason, details: details) },
                onCancel: { viewModel.cancelReport() }
            )
        }
        .overlay(alignment: .top) {
            if showCreationToast {
                challengeCreatedToast
                    .padding(.bottom, 40)
            }
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
        .alert("Quitter ce défi ?", isPresented: $viewModel.showQuitAlert) {
            quitChallengeConfirmationAlert
        }
    }

    private var shareCreateChallengeSection: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 18) {
            ShareButtonCell {
                showShareChallengeView = true
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

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 22) {
                ForEach(viewModel.challenges) { challenge in
                    NavigationLink(destination: {
                        CalendarDetailView(challenge: challenge)
                            .onDisappear { viewModel.refreshChallenges() }
                    }) {
                        DefiCell(challenge: challenge,
                                 onReport: { viewModel.presentReport(for: challenge) })
                    }
                }
            }
        }
    }

    private var becapChallengeListSection: some View {
        Group {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.title2)
                Text("DÉFIS BECAP")
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
            .padding(.bottom, 14)
            .foregroundColor(.white)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 18) {
                ForEach(viewModel.createBecapChallenges) { becapChallenge in
                    NavigationLink {
                        CreateBecapChallengeView(type: becapChallenge.type)
                    } label: {
                        DefiCell(challenge: becapChallenge.base, onReport: {})
                    }
                }
                ForEach(viewModel.becapChallenges) { becapChallenge in
                    NavigationLink {
                        CalendarDetailView(challenge: becapChallenge)
                            .onDisappear { viewModel.refreshChallenges() }
                    } label: {
                        DefiCell(challenge: becapChallenge.base, onReport: {})
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

    private var quitChallengeConfirmationAlert: some View {
        Group {
            Button("Quitter", role: .destructive) { viewModel.quitChallenge() }
            Button("Annuler", role: .cancel) { viewModel.cancelQuit() }
        }
    }

    private func quitChallengeErrorView(error: String) -> some View {
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
                    withAnimation { viewModel.quitChallengeError = nil }
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
        .onAppear { viewModel.onAppearQuitChallengeError() }
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
                .onDisappear {
                    deepLinkedPostId = nil
                    viewModel.refreshChallenges()
                }
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
        viewModel.challenges.contains(where: { $0.isLastDayToday }) ? "sunset" : "homeWallPaper"
    }
}
