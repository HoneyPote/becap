//
//  HomeView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

// TODO: Faire un bouton réutilisable pour les challenges et join et create
struct HomeView: View {
    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter
    @StateObject var viewModel = HomeViewModel()

    @State private var showJoinView = false
    @State private var showNewChallengeView = false
    @State private var showCreationToast = false
    @State private var deepLinkedChallenge: Challenge?
    @State private var navigateToDeepLinkedChallenge = false
    @State private var deepLinkJoinCode: String?
    @State private var hasPresentedJoinForDeepLink = false
    @State private var isResolvingDeepLink = false
    @State private var hasLoadedChallengesForPendingDeepLink = false
    @State private var deepLinkedPhotoId: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Image(homeBackgroundImageName)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                Color.black.opacity(0.25)
                    .ignoresSafeArea()

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
                if viewModel.showReportSuccessToast {
                    reportSuccessToast
                }
            }
            .alert("Delete this challenge?", isPresented: $viewModel.showDeleteAlert) {
                deleteChallengeConfirmationAlert
            }
            .navigationBarHidden(true)
            .background(deepLinkNavigationLink)
        }
        .refreshable { viewModel.refreshChallenges() }
        .sheet(isPresented: $showJoinView) {
            JoinChallengeView(prefilledCode: deepLinkJoinCode)
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
                    viewModel.submitReport(reason: reason, details: details)
                },
                onCancel: {
                    viewModel.cancelReport()
                }
            )
        }
        .overlay(alignment: .top) {
            if showCreationToast {
                challengeCreatedToast
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            hasPresentedJoinForDeepLink = false
            if let challengeId = deepLinkRouter.pendingCalendarChallengeId {
                beginResolvingDeepLink(for: challengeId)
            }
        }
        .onChange(of: deepLinkRouter.pendingCalendarChallengeId) { challengeId in
            guard let challengeId else {
                hasPresentedJoinForDeepLink = false
                isResolvingDeepLink = false
                hasLoadedChallengesForPendingDeepLink = false
                if !navigateToDeepLinkedChallenge {
                    deepLinkedPhotoId = nil
                }
                return
            }

            hasPresentedJoinForDeepLink = false
            beginResolvingDeepLink(for: challengeId)
        }
        .onChange(of: deepLinkRouter.pendingPhotoLink) { link in
            guard let link else { return }

            if let challenge = deepLinkedChallenge,
               let challengeId = challenge.id,
               challengeId == link.challengeId {
                deepLinkedPhotoId = link.photoId
            }

            if isResolvingDeepLink,
               hasLoadedChallengesForPendingDeepLink,
               let pendingId = deepLinkRouter.pendingCalendarChallengeId,
               pendingId == link.challengeId {
                attemptNavigationToChallenge(withId: link.challengeId, allowJoinFallback: true)
            }
        }
        .onChange(of: viewModel.challenges) { _ in
            guard isResolvingDeepLink,
                  let challengeId = deepLinkRouter.pendingCalendarChallengeId else { return }

            hasLoadedChallengesForPendingDeepLink = true
            attemptNavigationToChallenge(withId: challengeId, allowJoinFallback: true)
        }
        .onChange(of: showJoinView) { isPresented in
            if !isPresented {
                isResolvingDeepLink = false
            }
        }
    }

    private var joinCreateChallengeSection: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 18) {
            JoinButtonCell {
                deepLinkJoinCode = nil
                hasPresentedJoinForDeepLink = false
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
                        DefiCell(challenge: challenge,
                                 onDelete: { viewModel.confirmDelete(challenge) },
                                 onReport: { viewModel.presentReport(for: challenge) })
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

    private var reportSuccessToast: some View {
        VStack {
            Spacer()
            ToastView(message: "Signalement envoyé. Merci !", type: .success)
                .padding(.bottom, 40)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation {
                            viewModel.showReportSuccessToast = false
                        }
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
            CalendarDetailView(challenge: challenge, initialPhotoId: deepLinkedPhotoId)
                .id(calendarDetailIdentity(for: challenge, photoId: deepLinkedPhotoId))
                .onDisappear {
                    deepLinkedPhotoId = nil
                }
        } else {
            EmptyView()
        }
    }

    private func calendarDetailIdentity(for challenge: Challenge, photoId: String?) -> String {
        let base = challenge.id ?? "challenge-detail"
        if let photoId, !photoId.isEmpty {
            return "\(base)|photo:\(photoId)"
        }
        return "\(base)|calendar"
    }

    private func beginResolvingDeepLink(for challengeId: String) {
        isResolvingDeepLink = true
        hasLoadedChallengesForPendingDeepLink = viewModel.challenges.contains(where: { $0.id == challengeId })
        attemptNavigationToChallenge(withId: challengeId, allowJoinFallback: hasLoadedChallengesForPendingDeepLink)

        if !hasLoadedChallengesForPendingDeepLink {
            viewModel.refreshChallenges()
        }
    }

    private func attemptNavigationToChallenge(withId challengeId: String, allowJoinFallback: Bool) {
        if let challenge = viewModel.challenges.first(where: { $0.id == challengeId }) {
            deepLinkedChallenge = challenge
            if let link = deepLinkRouter.pendingPhotoLink,
               link.challengeId == challengeId {
                deepLinkedPhotoId = link.photoId
            } else {
                deepLinkedPhotoId = nil
            }
            navigateToDeepLinkedChallenge = true
            hasPresentedJoinForDeepLink = false
            deepLinkJoinCode = nil

            isResolvingDeepLink = false

            deepLinkRouter.clearChallengeNavigation()
            deepLinkRouter.clearJoin()
            deepLinkRouter.clearPhotoNavigation()
        } else if allowJoinFallback,
                  let code = deepLinkRouter.pendingJoinCode,
                  !hasPresentedJoinForDeepLink {
            deepLinkJoinCode = code
            showJoinView = true
            hasPresentedJoinForDeepLink = true
            deepLinkRouter.clearJoin()
        }
    }
}

private extension HomeView {
    var homeBackgroundImageName: String {
        viewModel.challenges.contains(where: { $0.isLastDayToday }) ? "sunset" : "epicPic"
    }
}
