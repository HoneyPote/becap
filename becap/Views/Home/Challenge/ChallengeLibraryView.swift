import SwiftUI

struct ChallengeLibraryView: View {
    @ObservedObject private var challengeManager = ChallengeManager.shared

    private var allChallenges: [Challenge] {
        let beCapBases = challengeManager.becapChallenges.map(\.base)
        return (challengeManager.challenges + beCapBases)
            .unique(by: \.id)
            .sorted {
                if $0.status != $1.status { return $0.status == .active }
                return $0.startDate > $1.startDate
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BecapBrandBackground()

                ScrollView {
                    LazyVStack(spacing: BecapMetrics.spacingM) {
                        if allChallenges.isEmpty {
                            ContentUnavailableView(
                                "Aucun défi",
                                systemImage: "flag.checkered",
                                description: Text("Tes défis actifs et terminés apparaîtront ici.")
                            )
                            .foregroundStyle(BecapColors.textPrimary)
                            .padding(.top, 80)
                        } else {
                            ForEach(allChallenges) { challenge in
                                NavigationLink {
                                    CalendarDetailView(challenge: challenge)
                                } label: {
                                    DefiCell(challenge: challenge, onReport: {})
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Ouvre le calendrier de ce défi")
                            }
                        }
                    }
                    .padding(BecapMetrics.spacingM)
                }
            }
            .navigationTitle("Mes défis")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .refreshable {
            try? await challengeManager.fetchAndFilterChallenges()
        }
    }
}
