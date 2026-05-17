import SwiftUI

// MARK: - Subview navigation chrome
//
// The app's NavigationStack back button is unreliable across platforms — it
// is outright absent on the macOS shell (a plain `HStack`, so an embedded
// `NavigationStack` has no toolbar surface to render a back button into).
//
// Every pushed subview therefore draws its own navigation bar: a guaranteed
// back button + title + an optional trailing slot for action buttons. The bar
// is rendered as a `safeAreaInset`, so it works identically on macOS, iPad and
// iPhone regardless of NavigationStack toolbar behaviour. On iOS the system
// navigation bar is hidden so there is never a double bar.
//
// Apply via `.subviewChrome(_:)` at the top of a pushed subview's body, in
// place of `.navigationTitle(_:)`. Do NOT apply it to top-level sidebar root
// views — those are not pushed and have no parent to return to.

public struct SubviewChrome<Trailing: View>: ViewModifier {
    private let title: Text
    private let trailing: Trailing
    @Environment(\.dismiss) private var dismiss

    public init(title: Text, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.trailing = trailing()
    }

    public func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .safeAreaInset(edge: .top, spacing: 0) { bar }
    }

    private var bar: some View {
        ZStack {
            title
                .scaledFont(.headline, weight: .semibold)
                .lineLimit(1)
                .padding(.horizontal, 96)
            HStack(spacing: 8) {
                Button { dismiss() } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.backward")
                            .scaledFont(.subheadline, weight: .semibold)
                        Text("action.back")
                            .scaledFont(.subheadline, weight: .medium)
                    }
                    .foregroundStyle(Color.accentColor)
                    .padding(.vertical, 4)
                    .padding(.trailing, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
                trailing
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.6)
        }
    }
}

public extension View {
    /// App-owned back-button + title bar for a pushed subview. Replaces
    /// `.navigationTitle(_:)`. See `SubviewChrome`.
    func subviewChrome(_ title: Text) -> some View {
        modifier(SubviewChrome(title: title) { EmptyView() })
    }

    /// App-owned back bar with trailing action buttons — pass the buttons that
    /// would otherwise live in a `.toolbar { }` primary-action slot.
    func subviewChrome<Trailing: View>(
        _ title: Text,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        modifier(SubviewChrome(title: title, trailing: trailing))
    }
}
