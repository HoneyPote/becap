import SwiftUI

// MARK: - Model

struct Player: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let avatarSystemName: String
    let scoreLabel: String
    let level: Int
    let isOnline: Bool
}

// MARK: - Home Screen

struct HomeScreenModernView: View {
    enum Segment: String, CaseIterable {
        case dares = "Dares"
        case players = "Players"

        var icon: String {
            switch self {
            case .dares: return "flag.checkered.2.crossed"
            case .players: return "person.2.fill"
            }
        }
    }

    @State private var selectedSegment: Segment = .players

    private let daresCount = 8
    private let playersCount = 12

    // Adaptive layout: 2 columns on compact width, more when space allows (landscape / iPad)
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 160, maximum: 280), spacing: 14)]
    }

    private let players: [Player] = [
        .init(name: "Caspian Drake", avatarSystemName: "person.fill", scoreLabel: "219.5M", level: 36, isOnline: true),
        .init(name: "Ava Sterling", avatarSystemName: "person.fill", scoreLabel: "97.2M", level: 28, isOnline: true),
        .init(name: "Luna Wolfe", avatarSystemName: "person.fill", scoreLabel: "9.8M", level: 14, isOnline: false),
        .init(name: "Ethan Blaze", avatarSystemName: "person.fill", scoreLabel: "64.4M", level: 22, isOnline: true),
        .init(name: "Mila Frost", avatarSystemName: "person.fill", scoreLabel: "31.7M", level: 19, isOnline: true),
        .init(name: "Noah Quinn", avatarSystemName: "person.fill", scoreLabel: "15.1M", level: 12, isOnline: false)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomLeading) {
                AppColors.background
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    header
                    segmentControl
                    grid
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                floatingActionButton
                    .padding(.leading, 16)
                    .padding(.bottom, 20)
            }
            .overlay(alignment: .trailing) {
                rightActionBar
                    .padding(.trailing, 12)
                    .padding(.top, 70)
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Home")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Find your crew and start the next challenge")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            CircleIconButton(systemName: "bell.badge.fill", size: 44, action: {})
        }
    }

    private var segmentControl: some View {
        HStack(spacing: 10) {
            ForEach(Segment.allCases, id: \.self) { segment in
                let count = segment == .dares ? daresCount : playersCount
                Button {
                    withAnimation(.spring(duration: 0.28)) {
                        selectedSegment = segment
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: segment.icon)
                            .font(.system(size: 12, weight: .semibold))

                        Text(segment.rawValue)
                            .font(.system(size: 14, weight: .bold, design: .rounded))

                        BadgeView(text: "\(count)")
                    }
                    .foregroundStyle(selectedSegment == segment ? AppColors.segmentSelectedText : AppColors.segmentUnselectedText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedSegment == segment ? AppColors.segmentSelectedBg : AppColors.segmentUnselectedBg)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(AppColors.segmentContainer)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var grid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(players) { player in
                    NavigationLink {
                        PlayerDetailView(player: player)
                    } label: {
                        PlayerCardView(player: player)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 90)
        }
    }

    private var floatingActionButton: some View {
        Button {
            // Action: create a new post / dare
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background(AppColors.accent)
                .clipShape(Circle())
                .shadow(color: AppColors.accent.opacity(0.45), radius: 14, x: 0, y: 8)
        }
        .accessibilityLabel("Create a new post")
    }

    private var rightActionBar: some View {
        VStack(spacing: 12) {
            CircleIconButton(systemName: "timer", size: 48, action: {})
            CircleIconButton(systemName: "sparkles", size: 48, action: {})
            CircleIconButton(systemName: "person.crop.circle.badge.checkmark", size: 48, action: {})
            CircleIconButton(systemName: "bolt.horizontal.circle", size: 48, action: {})
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Card Component

struct PlayerCardView: View {
    let player: Player

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(AppColors.cardStroke, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    avatar

                    VStack(alignment: .leading, spacing: 2) {
                        Text(player.name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(1)

                        Text("Lvl \(player.level)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                HStack {
                    statusTag
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .padding(14)

            BadgeView(text: player.scoreLabel)
                .padding(10)
        }
        .frame(minHeight: 138)
    }

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(AppColors.avatarBackground)
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: player.avatarSystemName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(AppColors.avatarIcon)
                }

            Circle()
                .fill(player.isOnline ? Color.green : Color.gray)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(.white, lineWidth: 2))
        }
    }

    private var statusTag: some View {
        Text(player.isOnline ? "Online" : "Offline")
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(player.isOnline ? Color.green : Color.gray)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background((player.isOnline ? Color.green : Color.gray).opacity(0.15), in: Capsule())
    }
}

// MARK: - Detail

struct PlayerDetailView: View {
    let player: Player

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                PlayerCardView(player: player)
                    .padding(.horizontal, 16)

                Text("Player detail screen")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Here you can show stats, recent dares and social actions.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.top, 20)
        }
        .navigationTitle(player.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Reusable UI

struct BadgeView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(AppColors.badgeText)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(AppColors.badgeBackground)
            .clipShape(Capsule())
    }
}

struct CircleIconButton: View {
    let systemName: String
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.35, weight: .bold))
                .frame(width: size, height: size)
                .foregroundStyle(AppColors.textPrimary)
                .background(AppColors.iconButtonBackground)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Style Tokens

private enum AppColors {
    static let background = LinearGradient(
        colors: [Color(red: 0.06, green: 0.09, blue: 0.17), Color(red: 0.09, green: 0.13, blue: 0.22)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardBackground = Color.white.opacity(0.08)
    static let cardStroke = Color.white.opacity(0.10)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.70)

    static let segmentContainer = Color.white.opacity(0.06)
    static let segmentSelectedBg = Color.white
    static let segmentUnselectedBg = Color.white.opacity(0.08)
    static let segmentSelectedText = Color.black
    static let segmentUnselectedText = Color.white.opacity(0.85)

    static let badgeBackground = Color(red: 0.50, green: 0.83, blue: 1.0)
    static let badgeText = Color.black.opacity(0.78)

    static let iconButtonBackground = Color.white.opacity(0.14)
    static let accent = Color(red: 0.25, green: 0.72, blue: 1.0)

    static let avatarBackground = Color.white.opacity(0.14)
    static let avatarIcon = Color.white.opacity(0.95)
}

// MARK: - Preview

#Preview("Home Screen") {
    HomeScreenModernView()
}

/*
 STYLE RECOMMENDATIONS
 - Colors: keep one bright accent color (FAB + badges) and neutral dark background for depth.
 - Typography: use rounded-bold for names and section titles; medium for support text.
 - Card visual: 20+ corner radius + thin translucent stroke for modern "glass" depth.
 - Spacing: keep 12/14/16pt rhythm between elements for a premium look.
 - Interaction: keep tap targets >= 44x44 for all icon buttons and cards.

 QUICK GUIDE: add this screen in a Tab Bar + Navigation
 1) Put HomeScreenModernView() inside your Home tab in MainTabView.
 2) Wrap the tab container in NavigationStack if you want app-wide push navigation.
 3) For programmatic navigation, replace NavigationLink with navigationDestination + state.
 */
