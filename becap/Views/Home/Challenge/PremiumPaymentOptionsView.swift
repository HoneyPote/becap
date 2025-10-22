import SwiftUI
import PassKit

// MARK: - SwiftUI wrapper for Apple Pay button
struct ApplePayButton: UIViewRepresentable {
    var type: PKPaymentButtonType = .buy
    var style: PKPaymentButtonStyle = .automatic
    var cornerRadius: CGFloat = 10
    var action: () -> Void

    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: type, paymentButtonStyle: style)
        button.addTarget(context.coordinator, action: #selector(Coordinator.tap), for: .touchUpInside)
        button.cornerRadius = cornerRadius
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {
        uiView.cornerRadius = cornerRadius
    }

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    final class Coordinator: NSObject {
        let action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func tap() { action() }
    }
}

// MARK: - Main view
struct PremiumPaymentOptionsView: View {
    enum PaymentMethod { case applePay, card }

    let challenge: PremiumChallenge
    let onPayment: (PaymentMethod) -> Void
    let onCancel: () -> Void

    @State private var isProcessing = false
    @State private var processingMethod: PaymentMethod?

    private var applePayAvailable: Bool {
        PKPaymentAuthorizationController.canMakePayments()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
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

                // Payment options
                VStack(spacing: 16) {
                    if applePayAvailable {
                        paymentButton(title: " Pay", method: .applePay) {
                            ApplePayButton(type: .buy, style: .automatic, cornerRadius: 12) {
                                startProcessing(.applePay)
                            }
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                        }
                    }

                    paymentButton(title: "Payer par carte", method: .card) {
                        HStack {
                            Image(systemName: "creditcard")
                            Text("Payer par carte").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
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

    // MARK: - Subviews

    private var priceCard: some View {
        VStack(spacing: 8) {
            Text(currencyString(amount: challenge.price, code: challenge.currencyCode))
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

    @ViewBuilder
    private func paymentButton<Content: View>(
        title: String,
        method: PaymentMethod,
        @ViewBuilder content: () -> Content
    ) -> some View {
        // On laisse le contenu gérer son look (incl. ApplePayButton)
        Button {
            startProcessing(method)
        } label: {
            content()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .disabled(isProcessing)
        .opacity(isProcessing && processingMethod != method ? 0.4 : 1)
    }

    // MARK: - Helpers

    private func startProcessing(_ method: PaymentMethod) {
        guard !isProcessing else { return }
        processingMethod = method
        withAnimation(.easeInOut(duration: 0.2)) { isProcessing = true }

        // Simule le temps de traitement puis remonte l’action
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onPayment(method)
            // Tu arrêteras l’indicateur depuis l’appelant quand le paiement est fini
            // ou fais-le ici si tu veux le masquer automatiquement:
            // withAnimation { isProcessing = false; processingMethod = nil }
        }
    }

    private func currencyString(amount: Decimal, code: String) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = code
        return nf.string(from: amount as NSDecimalNumber) ?? "\(amount) \(code)"
    }
}

// MARK: - Processing banner
private struct ProcessingPaymentView: View {
    let method: PremiumPaymentOptionsView.PaymentMethod

    var body: some View {
        HStack(spacing: 12) {
            ProgressView().progressViewStyle(.circular)
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
        case .applePay: "Traitement Apple Pay en cours…"
        case .card:     "Traitement du paiement par carte…"
        }
    }
}

// MARK: - Preview
struct PremiumPaymentOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumPaymentOptionsView(
            challenge: PremiumChallenge.sampleData[0],
            onPayment: { _ in },
            onCancel: {}
        )
    }
}
import SwiftUI

// MARK: - Store (état local pour la démo)
final class PremiumChallengesStore: ObservableObject {
    @Published var challenges: [PremiumChallenge] = PremiumChallenge.sampleData
}

// MARK: - Liste de challenges premium
struct PremiumChallengesView: View {
    @StateObject private var store = PremiumChallengesStore()

    @State private var selected: PremiumChallenge? = nil
    @State private var showPaySheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(store.challenges) { challenge in
                        PremiumChallengeCard(challenge: challenge)
                            .contentShape(Rectangle())               // assure le hit-test
                            .onTapGesture {
                                // Ouvre la feuille de paiement pour ce challenge
                                selected = challenge
                                showPaySheet = true
                            }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Challenges Premium")
        }
        .sheet(isPresented: $showPaySheet) {
            if let selected {
                PremiumPaymentOptionsView(
                    challenge: selected,
                    onPayment: { _ in
                        // Simule un paiement OK : on déverrouille puis on ferme
                        if let idx = store.challenges.firstIndex(of: selected) {
                            var c = store.challenges[idx]
                            c.isUnlocked = true
                            store.challenges[idx] = c
                        }
                        showPaySheet = false
                    },
                    onCancel: { showPaySheet = false }
                )
                .presentationDetents([.fraction(0.75), .large])
            }
        }
    }
}

// MARK: - Carte visuelle d’un challenge
struct PremiumChallengeCard: View {
    let challenge: PremiumChallenge

    var body: some View {
        HStack(spacing: 14) {
            // Vignette simple (texte/vidéo)
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.blue.opacity(0.12))
                Text(thumbnailText)
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.title)
                    .font(.headline)
                Text(challenge.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    if challenge.isUnlocked {
                        Label("Déverrouillé", systemImage: "checkmark.seal.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.green)
                    } else {
                        Text(priceString)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 4)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            // « lock » s’il n’est pas déverrouillé
            Group {
                if !challenge.isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .padding(6)
                        .background(.thinMaterial, in: Circle())
                        .offset(x: -8, y: -8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
        )
    }

    private var priceString: String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = challenge.currencyCode
        return nf.string(from: challenge.price as NSDecimalNumber) ?? "\(challenge.price) \(challenge.currencyCode)"
    }

    private var thumbnailText: String {
        switch challenge.media {
        case .text:  "TEXTE"
        case .video: "VIDÉO"
        }
    }
}
