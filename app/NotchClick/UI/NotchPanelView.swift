import SwiftUI

struct NotchPanelView: View {
    @EnvironmentObject var state:   AppState
    @EnvironmentObject var manager: NotchWindowManager

    private var isExpanded: Bool { manager.isExpanded }

    private var currentWidth: CGFloat {
        isExpanded ? NotchDimensions.expandedWidth  : NotchDimensions.notchWidth
    }
    private var currentHeight: CGFloat {
        isExpanded ? NotchDimensions.expandedHeight : NotchDimensions.notchHeight
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Main morphing notch/panel container — anchored to the top of the window
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    // The shape itself
                    RoundedRectangle(cornerRadius: isExpanded ? 22 : 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.10, green: 0.07, blue: 0.16),
                                    Color(red: 0.015, green: 0.012, blue: 0.025)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: isExpanded ? 22 : 18, style: .continuous)
                                .stroke(Color(red: 0.72, green: 0.55, blue: 1.0).opacity(isExpanded ? 0.18 : 0.0), lineWidth: 1)
                        )

                    // Content revealed only while expanded
                    if isExpanded {
                        panelContent
                            .padding(.top, NotchDimensions.notchHeight + NotchDimensions.expandedContentTopInset)
                            .padding(.horizontal, 14)
                            .padding(.bottom, 10)
                            .frame(
                                width: NotchDimensions.expandedWidth,
                                height: NotchDimensions.expandedHeight,
                                alignment: .top
                            )
                            .transition(.asymmetric(
                                insertion: .opacity.animation(.easeIn(duration: 0.18).delay(0.12)),
                                removal:   .opacity.animation(.easeOut(duration: 0.1))
                            ))
                    }
                }
                .frame(width: currentWidth, height: currentHeight)

                Spacer(minLength: 0)
            }
        }
        .frame(
            width:  NotchDimensions.windowWidth,
            height: NotchDimensions.windowHeight,
            alignment: .top
        )
    }

    // MARK: Panel Content

    @ViewBuilder
    private var panelContent: some View {
        VStack(spacing: 0) {
            TabBarView()
                .environmentObject(state)

            Divider()
                .background(Color.white.opacity(0.08))

            Group {
                switch state.selectedTab {
                case .launcher:  LauncherView()      .environmentObject(state.launcherVM)
                case .music:     MusicView()         .environmentObject(state.musicVM)
                }
            }
            .padding(.horizontal, 6)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
