//
//  ChallengeCameraContainerView.swift
//  becap
//
//  Created by Victor Derveaux on 28/01/2026.
//

import Foundation
import SwiftUI

struct ChallengeCameraContainerView: View {
    let challenge: Challenge

    @State private var capturedMedia: ChallengeRawMedia?
    @State private var showNewPostView = false

    var body: some View {
        ZStack {
            CustomCameraView { media in
                capturedMedia = media

                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    showNewPostView = true
                }
            }
            .offset(y: showNewPostView ? -UIScreen.main.bounds.height : 0)
            .zIndex(0)
            .navigationBarBackButtonHidden()

            if showNewPostView, let capturedMedia {
                NewPostView(challenge: challenge, rawMedia: capturedMedia, onCameraButtonClick: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        showNewPostView = false
                    }
                })
                .offset(y: showNewPostView ? 0 : UIScreen.main.bounds.height)
                .zIndex(1)
            }
        }
    }
}
