//
//  JoinChallengeCodeShareView.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import SwiftUI
import UIKit

struct JoinChallengeCodeShareView: View {
    let code: String

    var body: some View {
        HStack(spacing: 16) {
            Text(code)
                .font(.title)
                .bold()
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)

            Button(action: {
                UIPasteboard.general.string = code
            }) {
                Label("Copier", systemImage: "doc.on.doc")
            }
        }
    }
}
