import SwiftUI

struct HapticPlainButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded {
                guard isEnabled else { return }
                Haptics.lightTap()
            })
    }
}

extension ButtonStyle where Self == HapticPlainButtonStyle {
    static var hapticPlain: HapticPlainButtonStyle { HapticPlainButtonStyle() }
}

private struct HapticTapModifier: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content.simultaneousGesture(TapGesture().onEnded {
            guard isEnabled else { return }
            Haptics.lightTap()
        })
    }
}

extension View {
    func hapticTap() -> some View {
        modifier(HapticTapModifier())
    }
}
