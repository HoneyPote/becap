//
//  ChallengePaywallView.swift
//  becap
//
//  Created by OpenAI Assistant on 2025-xx-xx.
//

import SwiftUI
import PassKit

struct ChallengePaywallView: View {
    let challenge: Challenge
    @Binding var isProcessing: Bool
    let errorMessage: String?
    let onApplePay: () -> Void
    let onCard: () -> Void
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                header

                ChallengeInfoBubble(challenge: challenge)

                VStack(spacing: 12) {
                    if PKPaymentAuthorizationController.canMakePayments() {
                        ApplePayButton(action: onApplePay)
                            .frame(height: 50)
                            .opacity(isProcessing ? 0.6 : 1)
                            .overlay(alignment: .center) {
                                if isProcessing {
                                    ProgressView().tint(.white)
                                }
                            }
                            .disabled(isProcessing)
                    }

                    Button(action: onCard) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                            Text("Payer par carte")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.12))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isProcessing)
                    .opacity(isProcessing ? 0.6 : 1)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }

                Spacer()
            }
            .padding()
            .background(
                LinearGradient(colors: [Color.black, Color.gray.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer", action: onClose)
                        .foregroundColor(.white)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundColor(.white)
            Text(challenge.title)
                .font(.title2.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text("\(challenge.formattedPrice) · Apple Pay ou carte")
                .foregroundColor(.white.opacity(0.8))
                .font(.subheadline)
        }
        .padding(.bottom, 8)
    }
}

private struct ApplePayButton: UIViewRepresentable {
    var action: () -> Void

    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.didTapButton), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    final class Coordinator {
        let action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func didTapButton() {
            action()
        }
    }
}
