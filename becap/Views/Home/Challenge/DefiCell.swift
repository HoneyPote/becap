import SwiftUI

struct DefiCell: View {
    let challenge: Challenge
    let onReport: () -> Void

    private let corner: CGFloat = 18

    private var participantsCount: Int { challenge.participantUids.count }

    private var challengeTypeImageName: String {
        switch challenge.category {
        case .sport: return "sportDefiCell"
        case .drawing: return "drawDefiCell"
        case .food: return "foodDefiCell"
        case .reading: return "BookDefiCell"
        case .running: return "iphone_wallpaper_duo_run"
        case .other, .none: return "foodDefiCell"
        }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)

        ZStack(alignment: .bottomLeading) {
            // ✅ Background image + gradient
            Image(challengeTypeImageName)
                .resizable()
                .scaledToFill()
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.05), .black.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // ✅ Content
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(challenge.title)
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
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
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundColor(.white.opacity(0.95))

                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.black.opacity(0.22), in: Capsule())
            }
            .padding(10)
        }
        .frame(height: 170)
        .clipShape(shape) 
        .overlay(
            shape.stroke(.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.24), radius: 8, x: 0, y: 5)
        .contentShape(shape) // ✅ hitbox arrondie
        .contextMenu {
            Button { onReport() } label: {
                Label("Signaler", systemImage: "exclamationmark.bubble")
            }
        }
        .padding(4)
        .buttonStyle(.plain)
    }

    private var statusBadge: some View {
        Text(challenge.status.rawValue)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                challenge.status == .active
                ? Color(red: 0.25, green: 0.77, blue: 0.48)
                : Color(red: 0.61, green: 0.65, blue: 0.75)
            )
            .clipShape(Capsule())
    }
}
