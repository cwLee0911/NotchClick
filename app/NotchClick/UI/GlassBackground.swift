import SwiftUI

// MARK: - Glass Panel Background

struct GlassBackground: View {
    var cornerRadius: CGFloat = 20

    var body: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)

            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.10, blue: 0.25).opacity(0.52),
                    Color(red: 0.025, green: 0.02, blue: 0.04).opacity(0.66)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle border highlight
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.80, green: 0.66, blue: 1.0).opacity(0.28),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - View Modifier

extension View {
    func glassPanel(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(GlassBackground(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.5), radius: 20, y: 8)
    }
}

// MARK: - Notch Connector

struct NotchConnector: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.12))
            .frame(width: 100, height: 6)
    }
}

// MARK: - Section Header

struct SectionLabel: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.white.opacity(0.4))
            .kerning(1.2)
    }
}
