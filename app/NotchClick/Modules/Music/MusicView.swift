import SwiftUI

struct MusicView: View {
    @EnvironmentObject var vm: MusicViewModel

    var body: some View {
        VStack(spacing: 7) {
            MusicProviderSwitch(
                selectedProvider: vm.selectedProvider,
                onSelect: vm.selectProvider
            )

            Group {
                if let provider = vm.selectedProvider {
                    providerContent(for: provider)
                } else {
                    MusicSelectionRequiredView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func providerContent(for provider: MusicProvider) -> some View {
        if let errorMessage = vm.errorMessage {
            MusicPermissionErrorView(
                provider: provider,
                message: errorMessage,
                open: vm.openSelectedApp
            )
        } else if !vm.isSelectedAppRunning {
            MusicAppNotRunningView(provider: provider, open: vm.openSelectedApp)
        } else if let track = vm.track {
            PlayerView(vm: vm, track: track)
        } else {
            NothingPlayingView(provider: provider, open: vm.openSelectedApp)
        }
    }
}

private struct MusicProviderSwitch: View {
    let selectedProvider: MusicProvider?
    let onSelect: (MusicProvider) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(MusicProvider.allCases) { provider in
                Button(action: { onSelect(provider) }) {
                    Text(provider.title)
                        .font(.system(size: 11.2, weight: .semibold))
                        .foregroundStyle(selectedProvider == provider ? .white : .white.opacity(0.48))
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                        .frame(maxWidth: .infinity, minHeight: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(segmentFill(for: provider))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(segmentStroke(for: provider), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 30)
    }

    private func segmentFill(for provider: MusicProvider) -> Color {
        if selectedProvider == provider {
            return provider.accentColor.opacity(0.2)
        }
        return Color.white.opacity(0.06)
    }

    private func segmentStroke(for provider: MusicProvider) -> Color {
        if selectedProvider == provider {
            return provider.accentColor.opacity(0.34)
        }
        return Color.white.opacity(0.05)
    }
}

struct MusicProviderBadge: View {
    let provider: MusicProvider

    var body: some View {
        Text(provider.title.uppercased())
            .font(.system(size: 7.5, weight: .bold))
            .foregroundStyle(provider.accentColor.opacity(0.95))
            .kerning(1.0)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(provider.accentColor.opacity(0.2), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(provider.accentColor.opacity(0.22), lineWidth: 1)
            )
    }
}

private struct MusicSelectionRequiredView: View {
    @AppStorage("nd_language") private var languageCode = AppLanguage.defaultCode

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note.list")
                .font(.system(size: 24))
                .foregroundStyle(.white.opacity(0.24))

            Text(L10n.tr(.setMusicApp, languageCode))
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))

            Text(L10n.tr(.chooseMusicApp, languageCode))
                .font(.system(size: 10.8))
                .foregroundStyle(.white.opacity(0.46))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MusicPanelSurface(accent: nil))
    }
}

private struct PlayerView: View {
    @ObservedObject var vm: MusicViewModel
    let track: MusicTrack

    var body: some View {
        ZStack(alignment: .bottom) {
            HStack(spacing: 12) {
                ArtworkView(image: vm.artworkImage)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)

                            Text(track.artist)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            Text(track.album)
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.42))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }

                        Spacer(minLength: 4)

                        if let provider = vm.selectedProvider {
                            MusicProviderBadge(provider: provider)
                        }
                    }

                    VStack(spacing: 3) {
                        ProgressBar(fraction: vm.progressFraction)

                        HStack {
                            Text(vm.formattedPosition)
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.4))

                            Spacer()

                            Text(vm.formattedDuration)
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                    .padding(.bottom, 46)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            HStack(spacing: 8) {
                ControlPillButton(icon: "backward.fill") { vm.prevTrack() }
                ControlPillButton(
                    icon: track.isPlaying ? "pause.fill" : "play.fill",
                    size: 16,
                    accent: vm.selectedProvider?.accentColor ?? .white
                ) { vm.playPause() }
                ControlPillButton(icon: "forward.fill") { vm.nextTrack() }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(height: 136)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MusicPanelSurface(accent: vm.selectedProvider?.accentColor))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct ArtworkView: View {
    let image: NSImage?

    var body: some View {
        Group {
            if let img = image {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .overlay {
                        Image(systemName: "music.note")
                            .foregroundStyle(.white.opacity(0.3))
                            .font(.system(size: 20))
                    }
            }
        }
        .frame(width: 82, height: 82)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.38), radius: 10, y: 6)
    }
}

private struct ProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.1))
                Capsule()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 3.5)
    }
}

private struct ControlPillButton: View {
    let icon: String
    var size: CGFloat = 12
    var accent: Color = .white
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(accent.opacity(isHovered ? 1 : 0.9))
                .frame(width: size > 14 ? 38 : 30, height: size > 14 ? 38 : 30)
                .background(
                    Circle()
                        .fill(Color.white.opacity(isHovered ? 0.12 : 0.06))
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(isHovered ? 0.12 : 0.06), lineWidth: 1)
                )
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.spring(response: 0.18), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

private struct MusicPanelSurface: View {
    let accent: Color?

    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.86),
                        Color.black.opacity(0.74)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                (accent ?? .white).opacity(0.08),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
    }
}

private struct MusicAppNotRunningView: View {
    let provider: MusicProvider
    let open: () -> Void
    @AppStorage("nd_language") private var languageCode = AppLanguage.defaultCode

    var body: some View {
        CompactMusicStatusView(
            provider: provider,
            symbolName: provider.symbolName,
            title: "\(provider.title) \(L10n.tr(.appNotRunning, languageCode))",
            message: L10n.tr(.appNotRunningMessage, languageCode),
            buttonTitle: provider.localizedOpenActionTitle(languageCode),
            action: open
        )
        .background(MusicPanelSurface(accent: provider.accentColor))
    }
}

private struct NothingPlayingView: View {
    let provider: MusicProvider
    let open: () -> Void
    @AppStorage("nd_language") private var languageCode = AppLanguage.defaultCode

    var body: some View {
        CompactMusicStatusView(
            provider: provider,
            symbolName: "music.note.slash",
            title: L10n.tr(.nothingPlaying, languageCode),
            message: L10n.tr(.nothingPlayingMessage, languageCode),
            buttonTitle: provider.localizedOpenActionTitle(languageCode),
            action: open
        )
        .background(MusicPanelSurface(accent: provider.accentColor))
    }
}

private struct MusicPermissionErrorView: View {
    let provider: MusicProvider
    let message: String
    let open: () -> Void
    @AppStorage("nd_language") private var languageCode = AppLanguage.defaultCode

    var body: some View {
        CompactMusicStatusView(
            provider: provider,
            symbolName: "exclamationmark.lock.fill",
            title: L10n.tr(.permissionNeeded, languageCode),
            message: message,
            buttonTitle: provider.localizedOpenActionTitle(languageCode),
            action: open
        )
        .background(MusicPanelSurface(accent: provider.accentColor))
    }
}

private struct CompactMusicStatusView: View {
    let provider: MusicProvider
    let symbolName: String
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(provider.accentColor.opacity(0.15))

                Image(systemName: symbolName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(provider.accentColor.opacity(0.9))
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    MusicProviderBadge(provider: provider)

                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.84))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Text(message)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button(buttonTitle, action: action)
                .buttonStyle(GhostButtonStyle())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11.5, weight: .medium))
            .foregroundStyle(.white.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Color.white.opacity(configuration.isPressed ? 0.22 : 0.12),
                in: RoundedRectangle(cornerRadius: 8)
            )
    }
}
