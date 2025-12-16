//
//  PaymentButton.swift
//  becap
//
//  Created to wrap the native Apple Pay button while using SwiftUI.
//

import SwiftUI
import PassKit

struct PaymentButton: View {
    var action: () -> Void

    var body: some View {
        PaymentButtonRepresentable(action: action)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct PaymentButtonRepresentable: UIViewRepresentable {
    var action: () -> Void

    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .checkout, paymentButtonStyle: .automatic)
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
