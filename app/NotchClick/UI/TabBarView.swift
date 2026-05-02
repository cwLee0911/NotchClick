import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var state: AppState
    @Namespace private var tabHighlight
    @AppStorage("nd_language") private var languageCode = AppLanguage.defaultCode

    var body: some View {
        HStack(spacing: 4) {
            ForEach(PanelTab.allCases) { tab in
                TabButton(
                    tab: tab,
                    title: tab.localizedTitle(languageCode),
                    isSelected: state.selectedTab == tab,
                    highlightNamespace: tabHighlight
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        state.selectedTab = tab
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.12, blue: 0.28).opacity(0.72),
                            Color(red: 0.06, green: 0.05, blue: 0.09).opacity(0.86)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(red: 0.72, green: 0.55, blue: 1.0).opacity(0.16), lineWidth: 1)
        )
        .padding(.horizontal, 6)
    }
}

private struct TabButton: View {
    let tab: PanelTab
    let title: String
    let isSelected: Bool
    let highlightNamespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: tab.icon)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .frame(width: 16, height: 14)

                Text(title)
                    .font(.system(size: 10.5, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.45))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.78, green: 0.65, blue: 1.0).opacity(0.34),
                                    Color(red: 0.35, green: 0.24, blue: 0.55).opacity(0.32)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .matchedGeometryEffect(id: "tabHighlight", in: highlightNamespace)
                } else {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.001))
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}
