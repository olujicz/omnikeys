import OmniKeysCore
import SwiftUI

/// The live sheet in the panel: the scaled header, a search field, and the scaled cards in a scroll view.
/// AppKit-backed views (the field, the scroll view) stay unscaled; only SwiftUI content is scaled.
struct SheetPanel: View {
    typealias Metrics = CheatSheet.Metrics

    /// Height of the search field and the gap below it, in panel points (not scaled).
    static let searchBarHeight = 40.0
    private static let fieldHeight = 28.0

    let model: SheetModel
    /// Panel width in points.
    let width: Double
    let layout: SheetLayout.Result
    @State private var query: String
    /// Only this flag is state, not the scroll offset: a change re-runs `body`, which filters and measures the
    /// cards, so it must not change on every scroll frame.
    @State private var hasMoreBelow = false
    @Environment(\.omniKeysConfig) private var config

    init(model: SheetModel, width: Double, layout: SheetLayout.Result, query: String) {
        self.model = model
        self.width = width
        self.layout = layout
        _query = State(initialValue: query)
    }

    private var scale: Double {
        layout.fit.scale
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Scaled(scale: scale, width: width) {
                SheetHeader(hyperGlyphs: model.hyperGlyphs, showsSearchHint: true)
                    .padding([.horizontal, .top], Metrics.padding)
                    .padding(.bottom, Metrics.headerSpacing)
            }
            ShortcutSearchField(query: $query)
                .frame(maxWidth: 320, minHeight: Self.fieldHeight, maxHeight: Self.fieldHeight)
                .padding(.horizontal, Metrics.padding * scale)
                .padding(.bottom, Self.searchBarHeight - Self.fieldHeight)
            ScrollViewReader { proxy in
                ScrollView {
                    Scaled(scale: scale, width: width) { results }
                        .id(Self.contentID)
                        .onGeometryChange(for: Bool.self) { geometry in
                            let viewport = geometry.bounds(of: .named(Self.scrollSpace))?.height ?? 0
                            return viewport > 0 && geometry.frame(in: .named(Self.scrollSpace)).maxY - viewport > 1
                        } action: {
                            hasMoreBelow = $0
                        }
                }
                .scrollBounceBehavior(.basedOnSize)
                .coordinateSpace(.named(Self.scrollSpace))
                .mask { scrollMask }
                .overlay(alignment: .bottom) {
                    if hasMoreBelow {
                        moreButton { proxy.scrollTo(Self.contentID, anchor: .bottom) }
                    }
                }
                .animation(.easeOut(duration: 0.15), value: hasMoreBelow)
                .onChange(of: query) { proxy.scrollTo(Self.contentID, anchor: .top) }
            }
        }
        .frame(width: width, alignment: .topLeading)
        .background(config.backgroundColor)
        .environment(\.colorScheme, config.colorScheme ?? CheatSheet.systemColorScheme)
    }

    // MARK: Results

    @ViewBuilder
    private var results: some View {
        let filtered = model.filtered(matching: query)
        let columns = columns(for: filtered)
        Group {
            if columns.isEmpty {
                Label("No matching shortcuts or workspaces", systemImage: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 72)
            } else {
                SheetColumns(model: filtered, columns: columns)
            }
        }
        .padding(.horizontal, Metrics.padding)
        .padding(.bottom, Metrics.padding)
    }

    /// The measured layout for the full sheet; while searching, the matching cards reflowed over the
    /// columns the full sheet shows, balanced by their measured heights. Unused columns stay empty so
    /// cards keep their width.
    private func columns(for filtered: SheetModel) -> [[SheetCard]] {
        guard filtered != model else { return layout.columns }
        return SheetMeasurer(model: filtered, config: config)
            .flow(layoutWidth: width / scale, columns: layout.columns.count)
    }

    // MARK: Scrolling

    private static let contentID = "cards"
    private nonisolated static let scrollSpace = "sheet-scroll"

    /// Fades the bottom edge while more content is hidden below it.
    private var scrollMask: some View {
        VStack(spacing: 0) {
            Rectangle()
            LinearGradient(colors: [.black, .black.opacity(hasMoreBelow ? 0 : 1)], startPoint: .top, endPoint: .bottom)
                .frame(height: 48)
        }
    }

    private func moreButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label("More", systemImage: "chevron.down")
                .font(.system(size: 12 * scale, weight: .semibold))
                .padding(.horizontal, 10 * scale)
                .padding(.vertical, 4 * scale)
                .background(.regularMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .help("Scroll to the end (↓, Page Down or ⌘↓)")
        .accessibilityLabel("More shortcuts below. Scroll to the end.")
        .padding(.bottom, 10)
        .transition(.opacity)
    }
}

/// Lays `content` out at `width / scale` and scales it to fill `width`, taking up its scaled height.
private struct Scaled<Content: View>: View {
    let scale: Double
    let width: Double
    @ViewBuilder let content: Content
    @State private var height = 0.0

    var body: some View {
        content
            .frame(width: width / scale, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: Double.self) { $0.size.height } action: { height = $0 }
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: width, height: height * scale, alignment: .topLeading)
    }
}
