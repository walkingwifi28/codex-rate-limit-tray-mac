import SwiftUI

struct UsageGraphView: View {
    let state: UsageState
    var size: CGFloat = 132

    var body: some View {
        Image(nsImage: RateLimitIconRenderer().renderIcon(
            state: state,
            size: size
        ))
        .resizable()
        .interpolation(.high)
        .frame(width: size, height: size)
        .accessibilityLabel("Codex rate limit graph")
    }
}
