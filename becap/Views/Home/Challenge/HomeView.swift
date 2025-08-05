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
                        VStack(alignment: .leading, spacing: 0) {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 18) {
                                JoinButtonCell {
                                    showJoinView = true
                                }
                                NewChallengeCell {
                                    showNewChallengeView = true
                                }
                            }
                            .padding(.horizontal)
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
                                    DefiCell(
                                        challenge: challenge,
                                        onDelete: {
                                            viewModel.confirmDelete(challenge)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 0)
                        
                    }

                }

                if let error = viewModel.deleteChallengeError {
                    deleteChallengeErrorView(error: error)
                }
            }
            .navigationBarHidden(true)
            .alert("Delete this challenge?", isPresented: $viewModel.showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    viewModel.performDelete()
                }
                Button("Cancel", role: .cancel) {
                    viewModel.cancelDelete()
                }
            }
        }
                .refreshable {
            viewModel.refreshChallenges()
        }
        .sheet(isPresented: $showJoinView) {
            JoinChallengeView()
        }
        .sheet(isPresented: $showNewChallengeView) {
            NewChallengeView(challengeCreated:  $showCreationToast)
        }
        .overlay(alignment: .top) {
            if showCreationToast {
                ToastView(
                    message: "Défi créé avec succès 🎉",
                    type: .success
                )
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                showCreationToast = false
                            }
                        }
                    }
                    .padding(.bottom, 40)
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
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .zIndex(10)
        .onAppear {
            viewModel.onAppearDeleteChallengeError()
        }
    }
}
