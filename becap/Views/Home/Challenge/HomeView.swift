//
//  HomeView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI
import UIKit

// TODO: Faire un bouton réutilisable pour les challenges de partage et création
struct HomeView: View {
    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter
    @StateObject var viewModel = HomeViewModel()

    @State private var showShareChallengeView = false
    @State private var showNewChallengeView = false
    @State private var showCreationToast = false
    @State private var showRestartHint = true
    @State private var deepLinkedChallenge: (any ChallengeRepresentable)?
    @State private var navigateToDeepLinkedChallenge = false
    @State private var isResolvingDeepLink = false
    @State private var hasLoadedChallengesForPendingDeepLink = false
    @State private var deepLinkedPostId: String?
    @State private var deepLinkJoinError: String?
    @State private var showDeepLinkJoinCelebration = false
    @State private var joinedChallengeTitle: String?

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
                        finishedChallengeListSection
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

                if viewModel.showRestartSuccessToast {
                    restartSuccessToast
                }
            }
            .overlay {
                if showDeepLinkJoinCelebration {
                    challengeJoinedCelebration
                        .transition(.scale(scale: 0.86).combined(with: .opacity))
                        .zIndex(20)
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
        .alert("Relance impossible", isPresented: Binding(
            get: { viewModel.restartBecapErrorMessage != nil },
            set: { if !$0 { viewModel.restartBecapErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.restartBecapErrorMessage = nil }
        } message: {
            Text(viewModel.restartBecapErrorMessage ?? "Une erreur inattendue est survenue. Veuillez réessayer plus tard.")
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
                Text("DÉFIS LIBRES")
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .textCase(.uppercase)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 34)
            .padding(.bottom, 14)
            .padding(.horizontal, 24)
            .multilineTextAlignment(.center)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.challenges.filter { $0.status == .active }) { challenge in
                        NavigationLink(destination: {
                            CalendarDetailView(challenge: challenge)
                                .onDisappear { viewModel.refreshChallenges() }
                        }) {
                            DefiCell(challenge: challenge,
                                     onReport: { viewModel.presentReport(for: challenge) })
                            .frame(width: 190)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private var becapChallengeListSection: some View {
        Group {
            HStack(spacing: 10) {
                Image("list_white")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
                Text("DÉFIS BECAP")
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
            .padding(.bottom, 14)
            .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.becapChallenges.filter { $0.base.status == .active }) { becapChallenge in
                        NavigationLink {
                            CalendarDetailView(challenge: becapChallenge)
                                .onDisappear { viewModel.refreshChallenges() }
                        } label: {
                            DefiCell(challenge: becapChallenge.base,
                                     onReport: {},
                                     onRestart: viewModel.canRestart(becapChallenge) ? {
                                        viewModel.restartBecapChallenge(becapChallenge)
                                     } : nil,
                                     isRestarting: viewModel.isRestarting(becapChallenge))
                            .frame(width: 190)
                        }
                    }

                    ForEach(viewModel.becapTemplates.filter { template in
                        !viewModel.becapChallenges.contains(where: {
                            $0.type == template.type && $0.base.status == .active
                        })
                    }) { template in
                        NavigationLink {
                            CreateBecapChallengeView(type: template.type)
                                .onDisappear { viewModel.refreshChallenges() }
                        } label: {
                            BecapTemplateCell(template: template)
                                .frame(width: 190)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }

        }
    }

    @ViewBuilder
    private var finishedChallengeListSection: some View {
        let finishedChallenges = viewModel.challenges.filter { $0.status == .finished }
        let finishedBecapChallenges = viewModel.becapChallenges.filter { $0.base.status == .finished }

        if !finishedChallenges.isEmpty || !finishedBecapChallenges.isEmpty {
            HStack(spacing: 10) {
                Image("list_white")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
                Text("DÉFIS TERMINÉS")
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 34)
            .padding(.bottom, 14)
            .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(finishedChallenges) { challenge in
                        NavigationLink {
                            CalendarDetailView(challenge: challenge)
                                .onDisappear { viewModel.refreshChallenges() }
                        } label: {
                            DefiCell(challenge: challenge,
                                     onReport: { viewModel.presentReport(for: challenge) })
                            .frame(width: 190)
                        }
                    }

                    ForEach(finishedBecapChallenges) { becapChallenge in
                        NavigationLink {
                            CalendarDetailView(challenge: becapChallenge)
                                .onDisappear { viewModel.refreshChallenges() }
                        } label: {
                            DefiCell(challenge: becapChallenge.base,
                                     onReport: {},
                                     onRestart: viewModel.canRestart(becapChallenge) ? {
                                         viewModel.restartBecapChallenge(becapChallenge)
                                     } : nil,
                                     isRestarting: viewModel.isRestarting(becapChallenge))
                            .frame(width: 190)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }

            if !finishedBecapChallenges.isEmpty, showRestartHint {
                Text("Tu peux relancer un défi Becap terminé avec Restart ✅")
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 8)
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            withAnimation { showRestartHint = false }
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

    private var challengeJoinedCelebration: some View {
        ZStack {
            Color.black.opacity(0.32)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    ForEach(0..<10, id: \.self) { index in
                        Circle()
                            .fill(index.isMultiple(of: 2) ? Color.yellow.opacity(0.78) : Color.white.opacity(0.82))
                            .frame(width: index.isMultiple(of: 2) ? 10 : 7, height: index.isMultiple(of: 2) ? 10 : 7)
                            .offset(y: -56)
                            .rotationEffect(.degrees(Double(index) * 36))
                    }

                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.yellow, .orange, .pink],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
                }
                .frame(width: 140, height: 110)

                VStack(spacing: 8) {
                    Text("Félicitations !")
                        .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                        .foregroundColor(.white)

                    Text("Tu as rejoint le défi" + formattedJoinedChallengeTitle)
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.86))
                }
            }
            .padding(.vertical, 34)
            .padding(.horizontal, 28)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.28), radius: 22, x: 0, y: 14)
            .padding(.horizontal, 26)
        }
    }

    private var formattedJoinedChallengeTitle: String {
        guard let joinedChallengeTitle, !joinedChallengeTitle.isEmpty else {
            return " !"
        }

        return " « \(joinedChallengeTitle) » !"
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

    private var restartSuccessToast: some View {
        VStack {
            Spacer()
            ToastView(message: "Défi Becap relancé 🎉", type: .success)
                .padding(.bottom, 40)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { viewModel.showRestartSuccessToast = false }
                    }
                }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .zIndex(12)
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

    private func calendarDetailIdentity(for challenge: any ChallengeRepresentable, postId: String?) -> String {
        let base = challenge.id
        if let postId, !postId.isEmpty {
            return "\(base)|photo:\(postId)"
        }
        return "\(base)|calendar"
    }

    private func beginResolvingDeepLink(for challengeId: String) {
        isResolvingDeepLink = true
        hasLoadedChallengesForPendingDeepLink = challengeForDeepLink(withId: challengeId) != nil
        attemptNavigationToChallenge(withId: challengeId)

        Task { [challengeId] in
            do {
                let didJoinChallenge = try await viewModel.ensureMembershipIfNeeded(for: challengeId)

                if didJoinChallenge {
                    await MainActor.run {
                        let title = viewModel.challenges.first(where: { $0.id == challengeId })?.title
                        presentChallengeJoinedCelebration(challengeTitle: title)
                    }
                }
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

    private func presentChallengeJoinedCelebration(challengeTitle: String?) {
        joinedChallengeTitle = challengeTitle

        withAnimation(.spring(response: 0.45, dampingFraction: 0.68)) {
            showDeepLinkJoinCelebration = true
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                showDeepLinkJoinCelebration = false
            }
        }
    }

    private func attemptNavigationToChallenge(withId challengeId: String) {
        let challenge = challengeForDeepLink(withId: challengeId)

        if let challenge {
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

    private func challengeForDeepLink(withId challengeId: String) -> (any ChallengeRepresentable)? {
        if let challenge = viewModel.challenges.first(where: { $0.id == challengeId }) {
            return challenge
        }

        return viewModel.becapChallenges.first(where: { $0.id == challengeId })
    }
}

private extension HomeView {
    var homeBackgroundImageName: String {
        viewModel.challenges.contains(where: { $0.isLastDayToday }) ? "sunset" : "homeWallPaper"
    }
}
