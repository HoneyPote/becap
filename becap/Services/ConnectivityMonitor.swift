import Foundation
import Network
import SwiftUI

/// Publishes connectivity changes so the UI can explain failed network actions.
final class ConnectivityMonitor: ObservableObject {
    static let shared = ConnectivityMonitor()

    @Published private(set) var isConnected = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.becap.connectivity")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

struct ConnectivityBanner: View {
    var body: some View {
        Label("Hors connexion — certaines actions sont indisponibles", systemImage: "wifi.slash")
            .font(BecapTypography.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, BecapMetrics.spacingM)
            .frame(minHeight: BecapMetrics.minimumTapTarget)
            .background(BecapColors.coral, in: Capsule())
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            .accessibilityAddTraits(.isStaticText)
    }
}
