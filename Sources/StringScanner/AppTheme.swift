import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

enum AppTheme {
    static let teal = Color(red: 0.10, green: 0.62, blue: 0.56)
    static let tealDeep = Color(red: 0.06, green: 0.45, blue: 0.42)

    static let brandFont = Font.system(.largeTitle, design: .serif).weight(.semibold)
    static let mono = Font.system(.body, design: .monospaced)
    static let monoCaption = Font.system(.caption, design: .monospaced)

    static var windowBackground: Color {
        #if canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(.systemBackground)
        #endif
    }

    static var sidebarBackground: Color {
        #if canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(.secondarySystemBackground)
        #endif
    }

    static var elevatedBackground: Color {
        #if canImport(AppKit)
        Color(nsColor: .textBackgroundColor)
        #else
        Color(.tertiarySystemBackground)
        #endif
    }

    static var primaryText: Color {
        #if canImport(AppKit)
        Color(nsColor: .labelColor)
        #else
        Color.primary
        #endif
    }

    static var secondaryText: Color {
        #if canImport(AppKit)
        Color(nsColor: .secondaryLabelColor)
        #else
        Color.secondary
        #endif
    }

    static var tertiaryText: Color {
        #if canImport(AppKit)
        Color(nsColor: .tertiaryLabelColor)
        #else
        Color.secondary.opacity(0.7)
        #endif
    }

    static var separator: Color {
        #if canImport(AppKit)
        Color(nsColor: .separatorColor)
        #else
        Color.gray.opacity(0.3)
        #endif
    }

    /// Soft surface for secondary controls / stats. Near-white in light mode so it
    /// does not compete with the primary teal CTA; slightly lifted in dark mode.
    static var panelFill: Color {
        Color(light: Color.black.opacity(0.03), dark: Color.white.opacity(0.06))
    }

    static var panelStroke: Color {
        Color(light: Color.black.opacity(0.08), dark: Color.white.opacity(0.10))
    }
}

private extension Color {
    init(light: Color, dark: Color) {
        #if canImport(AppKit)
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(isDark ? dark : light)
        })
        #else
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #endif
    }
}

struct MeshBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AppTheme.windowBackground
            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        AppTheme.teal.opacity(0.10),
                        AppTheme.windowBackground.opacity(0.2),
                        Color.blue.opacity(0.05)
                    ]
                    : [
                        AppTheme.teal.opacity(0.07),
                        AppTheme.windowBackground.opacity(0.35),
                        Color.orange.opacity(0.04)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            GeometryReader { proxy in
                Path { path in
                    let step: CGFloat = 28
                    var x: CGFloat = 0
                    while x < proxy.size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                        x += step
                    }
                    var y: CGFloat = 0
                    while y < proxy.size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                        y += step
                    }
                }
                .stroke(AppTheme.primaryText.opacity(colorScheme == .dark ? 0.05 : 0.035), lineWidth: 1)
            }
        }
        .ignoresSafeArea()
    }
}
