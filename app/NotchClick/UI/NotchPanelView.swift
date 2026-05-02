import SwiftUI

struct NotchPanelView: View {
    @EnvironmentObject var state:   AppState
    @EnvironmentObject var manager: NotchWindowManager
    @ObservedObject private var quickSettingsVM = AppState.shared.quickSettingsVM

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

            // Center popup — rendered below the panel when any card is active
            if isExpanded, let popup = quickSettingsVM.activeCenterPopup {
                centerPopupContent(for: popup)
                    .frame(
                        width:  popup.popupWidth,
                        height: popup.popupHeight
                    )
                    .offset(
                        x: popupOffsetX(for: popup),
                        y: NotchDimensions.expandedHeight + NotchDimensions.centerPopupGap
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: -8))
                            .animation(.spring(response: 0.32, dampingFraction: 0.82)),
                        removal: .opacity.animation(.easeOut(duration: 0.15))
                    ))
                    .id(popup)   // fresh transition when switching cards
            }
        }
        .frame(
            width:  NotchDimensions.windowWidth,
            height: NotchDimensions.windowHeight,
            alignment: .top
        )
    }

    // MARK: Center popup dispatch

    @ViewBuilder
    private func centerPopupContent(for popup: CenterPopup) -> some View {
        switch popup {
        case .language:
            LanguagePopupView(vm: quickSettingsVM)
        case .bluetooth:
            BluetoothPopupView(vm: quickSettingsVM)
        case .music:
            MusicPopupView(
                vm: state.musicVM,
                onClose: { quickSettingsVM.closeCenterPopup() }
            )
        }
    }

    /// Horizontal offset (from window center) so the popup lands under its
    /// source card, clamped to stay inside the window bounds.
    private func popupOffsetX(for popup: CenterPopup) -> CGFloat {
        let windowW = NotchDimensions.windowWidth
        let panelW  = NotchDimensions.expandedWidth
        let popupW  = popup.popupWidth

        let innerLeft: CGFloat = (windowW - panelW) / 2 + 14
        let cardSpacing: CGFloat = 8
        let innerWidth = panelW - 28
        let cardCount = CGFloat(max(CenterPopup.allCases.count, 1))
        let totalSpacing = cardSpacing * CGFloat(max(CenterPopup.allCases.count - 1, 0))
        let cardWidth = (innerWidth - totalSpacing) / cardCount
        let cardCenterX =
            innerLeft + cardWidth / 2 +
            CGFloat(popup.cardIndex) * (cardWidth + cardSpacing)

        var popupX = cardCenterX - popupW / 2
        popupX = min(max(popupX, 8), windowW - popupW - 8)
        // Convert from window-local x to an offset relative to window center.
        return popupX + popupW / 2 - windowW / 2
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
                case .weather:   WeatherView()       .environmentObject(state.weatherVM)
                case .center:
                    ControlCenterView()
                        .environmentObject(state.quickSettingsVM)
                        .environmentObject(state.systemVM)
                        .environmentObject(state.musicVM)
                }
            }
            .padding(.horizontal, 6)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
