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
        }
        .refreshable { viewModel.refreshChallenges() }
        .sheet(isPresented: $showJoinView) {
            JoinChallengeView()
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
