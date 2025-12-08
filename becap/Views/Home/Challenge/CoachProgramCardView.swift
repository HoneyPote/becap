import SwiftUI

struct CoachProgramCardView: View {
    let challenge: Challenge
    let isLocked: Bool

    private var heroImageURL: URL? { URL(string: challenge.heroImageUrl ?? "") }
    private var coachAvatarURL: URL? { URL(string: challenge.coachAvatarUrl ?? "") }

    private var statusBadgeText: String {
        challenge.status == .active ? "IN PROGRESS" : "JOINED"
    }

    var body: some View {
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
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [Color.black.opacity(0.45), Color.black.opacity(0.2)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .cornerRadius(22)
            .shadow(radius: 10, y: 6)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 12) {
                    AsyncImage(url: coachAvatarURL) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(Color.white.opacity(0.6))
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Circle()
                                .fill(Color.white.opacity(0.6))
                        @unknown default:
                            Circle()
                                .fill(Color.white.opacity(0.6))
                        }
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 2))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(challenge.coachName ?? "Coach program")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(challenge.shortTagline ?? "Programme personnalisé")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(challenge.title)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 10) {
                        label(icon: "clock", text: "\(challenge.duration) days")
                        if let difficulty = challenge.difficulty {
                            label(icon: "flame.fill", text: difficulty)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)

            VStack {
                HStack {
                    Spacer()
                    if isLocked {
                        HStack(spacing: 6) {
                            Text(challenge.formattedPrice)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                            Image(systemName: "lock.fill")
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Capsule())
                    } else {
                        Text(statusBadgeText)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.85))
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            }
            .padding(14)
        }
        .contentShape(RoundedRectangle(cornerRadius: 22))
    }

    private func label(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.caption.bold())
            Text(text)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.18))
        .clipShape(Capsule())
    }
}
