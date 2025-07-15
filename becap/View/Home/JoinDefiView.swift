//
//  JoinDefiView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

// ChallengeApp/Views/JoinDefiView.swift

import SwiftUI

struct JoinDefiView: View {
    var body: some View {
        VStack(spacing: 32) {
            Text("Rejoindre un défi via lien ou QR")
                .font(.title3)
                .padding(.top)

            Text("Cette fonctionnalité sera disponible prochainement.\nPartagez un lien ou scannez un QR code pour rejoindre un défi créé par un ami.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)

            Spacer()
        }
        .padding()
        .navigationTitle("Rejoindre un défi")
    }
}
