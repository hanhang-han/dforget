// V2.0 — Quiet Luxury 设计系统令牌
// 纯黑白极简，温度靠内容不靠视觉

import SwiftUI

// MARK: - QL Design Namespace

enum QLDesign {
    // MARK: - Colors

    enum Color {
        static let background = SwiftUI.Color.black
        static let surface = SwiftUI.Color(red: 0.11, green: 0.11, blue: 0.12) // #1C1C1E
        static let border = SwiftUI.Color.white.opacity(0.08)
        static let primaryText = SwiftUI.Color.white
        static let secondaryText = SwiftUI.Color(red: 0.56, green: 0.56, blue: 0.58) // #8E8E93
        static let labelText = SwiftUI.Color(red: 0.39, green: 0.39, blue: 0.40) // #636366
        static let surfaceSecondary = SwiftUI.Color(red: 0.16, green: 0.16, blue: 0.17) // slightly lighter surface
    }

    // MARK: - Fonts

    enum Font {
        static func heading(_ size: CGFloat = 22) -> SwiftUI.Font {
            .system(size: size, weight: .semibold, design: .default)
        }

        static func body(_ size: CGFloat = 15) -> SwiftUI.Font {
            .system(size: size, weight: .regular)
        }

        static func bodyMedium(_ size: CGFloat = 15) -> SwiftUI.Font {
            .system(size: size, weight: .medium)
        }

        static func label(_ size: CGFloat = 12) -> SwiftUI.Font {
            .system(size: size, weight: .medium)
        }

        static func mono(_ size: CGFloat = 12) -> SwiftUI.Font {
            .system(size: size, weight: .medium, design: .monospaced)
        }

        static func serif(_ size: CGFloat = 15) -> SwiftUI.Font {
            .system(size: size, weight: .regular, design: .serif)
        }
    }

    // MARK: - Spacing

    enum Spacing {
        static let pageMargin: CGFloat = 24
        static let baseUnit: CGFloat = 8
        static let cardPadding: CGFloat = 20
    }

    // MARK: - Shape

    enum Shape {
        static let cardRadius: CGFloat = 16
        static let buttonRadius: CGFloat = 12
        static let smallRadius: CGFloat = 8
    }
}

// MARK: - Card Modifier

struct QLCardModifier: ViewModifier {
    var showBorder: Bool = true

    func body(content: Content) -> some View {
        content
            .padding(QLDesign.Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: QLDesign.Shape.cardRadius, style: .continuous)
                    .fill(QLDesign.Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: QLDesign.Shape.cardRadius, style: .continuous)
                    .stroke(showBorder ? QLDesign.Color.border : SwiftUI.Color.clear, lineWidth: 0.5)
            )
    }
}

// MARK: - Button Modifier

struct QLButtonModifier: ViewModifier {
    var isPrimary: Bool = true

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: QLDesign.Shape.buttonRadius, style: .continuous)
                    .fill(isPrimary ? SwiftUI.Color.white : QLDesign.Color.surface)
            )
            .foregroundStyle(isPrimary ? SwiftUI.Color.black : SwiftUI.Color.white)
    }
}

// MARK: - View Extensions

extension View {
    func qlCard(showBorder: Bool = true) -> some View {
        modifier(QLCardModifier(showBorder: showBorder))
    }

    func qlButton(isPrimary: Bool = true) -> some View {
        modifier(QLButtonModifier(isPrimary: isPrimary))
    }
}
