//
//  PremiumPaymentOptionsView.swift
//  becap
//
//  Created by OpenAI on 2025-02-14.
//

import SwiftUI
import PassKit

struct PremiumPaymentOptionsView: View {
    enum PaymentMethod {
        case applePay
        case card
    }

    let challenge: PremiumChallenge
    let onPayment: (PaymentMethod) -> Void
    let onCancel: () -> Void

    @State private var isProcessing = false
    @State private var processingMethod: PaymentMethod?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Déverrouiller \(challenge.title)")
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)

                    Text(challenge.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 12)

                priceCard

                VStack(spacing: 16) {
                    paymentButton(title: " Pay", method: .applePay) {
                        PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .automatic)
                            .frame(height: 50)
                    }

                    paymentButton(title: "Payer par carte", method: .card) {
                        HStack {
                            Image(systemName: "creditcard")
                            Text("Payer par carte")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.accentColor)
                        .foregroundStyle(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }

                if isProcessing, let processingMethod {
                    ProcessingPaymentView(method: processingMethod)
                        .transition(.opacity)
                }

                Spacer()
            }
            .padding(24)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer", action: onCancel)
                }
            }
        }
        .interactiveDismissDisabled(isProcessing)
    }

    private var priceCard: some View {
        VStack(spacing: 8) {
            Text(String(format: "%.2f %@", NSDecimalNumber(decimal: challenge.price).doubleValue, challenge.currencyCode))
                .font(.largeTitle.weight(.bold))

            Text("Paiement sécurisé. Déblocage instantané du contenu premium.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func paymentButton<Content: View>(title: String, method: PaymentMethod, @ViewBuilder content: () -> Content) -> some View {
        Button {
            guard !isProcessing else { return }
            processingMethod = method
            withAnimation(.easeInOut(duration: 0.2)) { isProcessing = true }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                onPayment(method)
            }
        } label: {
            content()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .disabled(isProcessing)
        .opacity(isProcessing && processingMethod != method ? 0.4 : 1)
    }
}

private struct ProcessingPaymentView: View {
    let method: PremiumPaymentOptionsView.PaymentMethod

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)

            Text(message(for: method))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func message(for method: PremiumPaymentOptionsView.PaymentMethod) -> String {
        switch method {
        case .applePay:
            return "Traitement Apple Pay en cours…"
        case .card:
            return "Traitement du paiement par carte…"
        }
    }
}

struct PremiumPaymentOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumPaymentOptionsView(
            challenge: PremiumChallenge.sampleData[0],
            onPayment: { _ in },
            onCancel: {}
        )
    }
}
