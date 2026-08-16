//
//  ChallengeCameraContainerView.swift
//  becap
//
//  Created by Victor Derveaux on 28/01/2026.
//

import Foundation
import SwiftUI

struct ChallengeCameraContainerView: View {
    let challenge: any ChallengeRepresentable

    @State private var capturedMedia: ChallengeRawMedia?
    @State private var showNewPostView = false

    var body: some View {
        ZStack {
            if showNewPostView, let capturedMedia {
                NewPostView(challenge: challenge, rawMedia: capturedMedia, onCameraButtonClick: {
                    // Remove the post screen before recreating the camera. Keeping
                    // both screens alive leaves AVCaptureSession producing frames
                    // behind the upload and greatly increases peak memory usage.
                    self.capturedMedia = nil
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        showNewPostView = false
                    }
                })
                .transition(.move(edge: .bottom))
            } else {
                CustomCameraView(challenge: challenge) { media in
                    capturedMedia = media

                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        showNewPostView = true
                    }
                }
                .transition(.move(edge: .top))
                .navigationBarBackButtonHidden()
            }
        }
    }
}
