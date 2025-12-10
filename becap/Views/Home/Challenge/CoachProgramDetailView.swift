import SwiftUI

struct CoachProgramDetailView: View {
    let challenge: Challenge
    let isLocked: Bool

    @EnvironmentObject private var viewModel: HomeViewModel
    @State private var navigateToCalendar = false

    private var heroImageURL: URL? { URL(string: challenge.heroImageUrl ?? "") }
    private var coachAvatarURL: URL? { URL(string: challenge.coachAvatarUrl ?? "") }

    private var displayLocked: Bool {
        viewModel.isLocked(challenge) || isLocked
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroHeader
                section(title: "What you will get", text: challenge.longDescription ?? challenge.infoText ?? "A complete guided experience to help you reach your goals.")
                section(title: "How it works", text: "Follow the daily sessions crafted by your coach. Track your progress, share updates with the community, and stay accountable with reminders.")
            }
            .padding(.horizontal)
            .padding(.bottom, 110)
        }
        .navigationTitle(challenge.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            callToAction
                .padding()
                .background(.ultraThinMaterial)
        }
        .background(
            NavigationLink(destination: CalendarDetailView(challenge: challenge), isActive: $navigateToCalendar) {
                EmptyView()
            }
            .hidden()
        )
        .background(Color.black.ignoresSafeArea())
    }

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: heroImageURL) { phase in
                switch phase {
                case .empty:
                    Color.gray.opacity(0.2)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Color.gray.opacity(0.3)
                @unknown default:
                    Color.gray.opacity(0.2)
                }
            }
            .frame(height: 260)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [Color.black.opacity(0.6), Color.black.opacity(0.25)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    AsyncImage(url: coachAvatarURL) { phase in
                        switch phase {
                        case .empty:
                            Circle().fill(Color.white.opacity(0.7))
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Circle().fill(Color.white.opacity(0.7))
                        @unknown default:
                            Circle().fill(Color.white.opacity(0.7))
                        }
                    }
                    .frame(width: 54, height: 54)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 2))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(challenge.coachName ?? "Coach program")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(challenge.shortTagline ?? "Tailored guidance to reach your goal")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(challenge.title)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 10) {
                        pill(icon: "clock", text: "\(challenge.duration) days")
                        if let difficulty = challenge.difficulty { pill(icon: "flame.fill", text: difficulty) }
                    }
                }
            }
            .padding(18)
        }
        .cornerRadius(20)
        .shadow(radius: 10, y: 6)
    }

    private var callToAction: some View {
        Button(action: primaryAction) {
            Text(displayLocked ? "Join the program – \(challenge.formattedPrice)" : "Go to Today’s session")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(displayLocked ? Color.blue : Color.green)
                .cornerRadius(16)
        }
    }

    private func section(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3.bold())
                .foregroundColor(.white)
            Text(text)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
        }
    }

    private func pill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption.bold())
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.2))
        .foregroundColor(.white)
        .clipShape(Capsule())
    }

    private func primaryAction() {
        if displayLocked {
            viewModel.presentPaywall(for: challenge)
        } else {
            navigateToCalendar = true
        }
    }
}
