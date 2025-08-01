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

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.petrolToSky.ignoresSafeArea()

                VStack(alignment: .leading) {
                    Text("Liste des défis")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .padding(.top, 42)
                        .padding(.bottom, 12)
                        .padding(.horizontal, 24)

                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                            JoinButtonCell {
                                showJoinView = true
                            }
                            ForEach(viewModel.challenges) { challenge in
                                DefiCell(
                                    challenge: challenge,
                                    onDelete: {
                                        viewModel.confirmDelete(challenge)
                                    }
                                )
                            }
                        }
                        .padding()
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
