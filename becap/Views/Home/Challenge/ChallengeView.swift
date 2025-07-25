//
//  homeView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

//
import SwiftUI

struct ChallengeView: View {
    @ObservedObject var challengeManager: ChallengeManager
    @StateObject private var vm = HomeViewModel()
    @State private var showJoinView = false
    
    
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
                            JoinButtonCell {
                                showJoinView = true
                            }
                            ForEach(filteredChallenges) { challenge in
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
                
                print("[ChallengeView] onAppear")
                
                Task {
                    await challengeManager.fetchAndFilterChallenges()
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showJoinView) {
            JoinDefiView().environmentObject(challengeManager)
        }
    }
    
    private var filteredChallenges: [Challenge] {
        guard let userId = challengeManager.currentUser?.id else { return [] }
        return challengeManager.challenges.filter {
            $0.participantUids.contains(userId) || $0.creatorUID == userId
        }
    }
}
