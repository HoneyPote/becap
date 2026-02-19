import SwiftUI

struct DefiCell: View {
    let challenge: Challenge
    let onQuit: () -> Void
    let onReport: () -> Void

    private let corner: CGFloat = 22

    private var participantsCount: Int { challenge.participantUids.count }

    private var challengeTypeImageName: String {
        switch challenge.category {
        case .sport: return "sportDefiCell"
        case .dessin: return "drawDefiCell"
        case .nourriture: return "foodDefiCell"
        case .lecture: return "BookDefiCell"
        case .course: return "iphone_wallpaper_duo_run"
        case .autre, .none: return "foodDefiCell"
        }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)

        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.81, green: 0.88, blue: 0.98),
                    Color(red: 0.63, green: 0.76, blue: 0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(challengeTypeImageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 170, maxHeight: 90)
                .shadow(color: .black.opacity(0.24), radius: 8, x: 0, y: 4)
                .padding(.bottom, 32)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text(challenge.title)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Spacer(minLength: 8)

                    statusBadge
                }

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.95))

                    Text("\(participantsCount) participant\(participantsCount > 1 ? "s" : "")")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.95))

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color(red: 0.39, green: 0.53, blue: 0.75).opacity(0.52), in: Capsule())
            }
            .padding(12)
        }
        .frame(height: 235)
        .clipShape(shape)
        .overlay(shape.stroke(.white.opacity(0.32), lineWidth: 1.2))
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 6)
        .contentShape(shape)
        .contextMenu {
            Button(role: .destructive) { onQuit() } label: {
                Label("Quitter le défi", systemImage: "trash")
            }
            Button { onReport() } label: {
                Label("Signaler", systemImage: "exclamationmark.bubble")
            }
        }
        .padding(.horizontal, 2)
        .buttonStyle(.plain)
    }

    private var statusBadge: some View {
        Text(challenge.status.rawValue)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                challenge.status == .active
                ? Color(red: 0.39, green: 0.80, blue: 0.56)
                : Color(red: 0.61, green: 0.65, blue: 0.75)
            )
            .clipShape(Capsule())
    }
}
