//
//  homeView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

// ChallengeApp/Views/HomeView.swift

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var defiManager: DefiManager
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
                            ForEach(defiManager.defis) { defi in
                                DefiCell(defi: defi, photos: defiManager.photos) {
                                    vm.confirmDelete(defi)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Delete this challenge?", isPresented: $vm.showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    vm.performDelete(defiManager: defiManager)
                }
                Button("Cancel", role: .cancel) {
                    vm.cancelDelete()
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
