//
//  homeView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

//
//  ChallengeView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

struct ChallengeView: View {
    @ObservedObject var challengeManager: ChallengeManager
    @StateObject private var vm = HomeViewModel()

    var body: some View {
        NavigationView {
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
                            ForEach(challengeManager.challenges) { challenge in
                                DefiCell(
                                    challenge: challenge,
                                    photos: challengeManager.photos[challenge.id ?? ""] ?? [],
                                    onDelete: {
                                        vm.confirmDelete(challenge)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }

                // TOAST personnalisé en bas de l’écran
                if let error = vm.lastError {
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
                                withAnimation { vm.lastError = nil }
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
                        // Disparition auto du toast après 2s
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { vm.lastError = nil }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Delete this challenge?", isPresented: $vm.showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    vm.performDelete(manager: challengeManager)
                }
                Button("Cancel", role: .cancel) {
                    vm.cancelDelete()
                }
            }
            .onAppear {
                challengeManager.loadAllPhotos()
            }
        }
        .navigationViewStyle(.stack)
    }
}
