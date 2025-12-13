//
//  PaywallView.swift
//  becap
//
//  Simple StoreKit 2 paywall for premium access.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var store: StoreManager
    @Environment(\.dismiss) private var dismiss

    @State private var isProcessing = false
    @State private var isLoadingProducts = false
    @State private var errorMessage: String?

    private var monthlyProduct: Product? {
        store.products.first(where: { $0.id == IAPProductIDs.premiumMonthly })
    }

    private var unlockProduct: Product? {
        store.products.first(where: { $0.id == IAPProductIDs.premiumUnlock })
    }

    var body: some View {
        VStack(spacing: 20) {
            header

            VStack(spacing: 14) {
                productButton(product: monthlyProduct, title: "S’abonner mensuellement") {
                    await purchase(monthlyProduct)
                }

                productButton(product: unlockProduct, title: "Débloquer à vie") {
                    await purchase(unlockProduct)
                }

                Button {
                    Task { await store.restorePurchases() }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Restaurer mes achats")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.gray.opacity(0.4))
            }
            .disabled(buttonsDisabled)

            if isProcessing {
                ProgressView("Traitement en cours…")
                    .padding(.top, 8)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            Button("Fermer") { dismiss() }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.16, blue: 0.26), Color(red: 0.06, green: 0.09, blue: 0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear {
            if store.isPremium {
                dismiss()
            }
        }
        .task {
            isLoadingProducts = true
            await store.loadProducts()
            await store.refreshEntitlements()
            isLoadingProducts = false
        }
        .onChange(of: store.isPremium) { hasPremium in
            if hasPremium {
                dismiss()
            }
        }
    }
}

private extension PaywallView {
    var header: some View {
        VStack(spacing: 8) {
            Text("Premium")
                .font(.system(.largeTitle, design: .rounded).bold())
                .foregroundColor(.white)
            Text("Accès à tous les défis premium, contenus exclusifs et soutien à l’équipe.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.86))
        }
        .padding(.vertical, 12)
    }

    @ViewBuilder
    func productButton(product: Product?, title: String, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    if let product {
                        Text(product.displayPrice)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Chargement…")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "lock.open.fill")
                    .foregroundColor(.yellow)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(red: 0.28, green: 0.52, blue: 0.96))
        .opacity(product == nil ? 0.7 : 1)
        .disabled(product == nil || buttonsDisabled)
    }

    func purchase(_ product: Product?) async {
        guard let product else {
            errorMessage = "Produits indisponibles. Réessayez plus tard."
            return
        }

        guard !isLoadingProducts else { return }

        isProcessing = true
        errorMessage = nil

        let outcome = await store.buy(product)

        switch outcome {
        case .success:
            errorMessage = nil
        case .cancelled:
            errorMessage = "Achat annulé. Vous pouvez réessayer à tout moment."
        case .pending:
            errorMessage = "Achat en attente de validation. Vérifiez votre compte App Store."
        case .failed(let error):
            errorMessage = "Échec de la transaction : \(error.localizedDescription)"
        }

        isProcessing = false
    }

    var buttonsDisabled: Bool {
        isProcessing || isLoadingProducts || store.products.isEmpty
    }
}

#Preview {
    PaywallView()
        .environmentObject(StoreManager())
}
