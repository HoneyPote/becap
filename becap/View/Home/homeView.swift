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

    var body: some View {
        NavigationView {
            VStack {
                Text("Liste des défis")
                    .font(.title)
                    .padding()

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                        ForEach(defiManager.defis) { defi in
                            NavigationLink(destination: CalendarDetailView(defi: defi)) {
                                Rectangle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(height: 100)
                                    .overlay(Text(defi.nom))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Accueil")
        }
    }
}
