import SwiftUI

struct ControlCenterView: View {
    @EnvironmentObject var vm: QuickSettingsViewModel
    @EnvironmentObject var systemVM: SystemMonitor
    @AppStorage("nd_language") private var languageCode = AppLanguage.defaultCode

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                LanguageCenterMenuCard(
                    title: L10n.tr(.language, languageCode),
                    selection: $languageCode,
                    isActive: vm.isLanguagePopupVisible,
                    action: vm.toggleLanguagePopup
                )

                CompactSystemMetricCard(
                    title: L10n.tr(.cpu, languageCode),
                    value: String(format: "%.0f%%", systemVM.stats.cpuUsage),
                    fraction: systemVM.stats.cpuUsage / 100,
                    icon: "cpu",
                    color: cpuColor(systemVM.stats.cpuUsage)
                )

                CompactSystemMetricCard(
                    title: L10n.tr(.memory, languageCode),
                    value: String(format: "%.1fGB", systemVM.stats.memUsedGB),
                    fraction: systemVM.stats.memUsagePercent / 100,
                    icon: "memorychip",
                    color: .purple
                )

                CompactSystemMetricCard(
                    title: L10n.tr(.storage, languageCode),
                    value: String(format: "%.0fGB", storageFreeGB),
                    fraction: systemVM.stats.storagePercent / 100,
                    icon: "internaldrive",
                    color: .teal
                )

                if systemVM.stats.hasBattery {
                    CompactBatteryMetricCard(
                        stats: systemVM.stats,
                        isBusy: systemVM.isTogglingLowPowerMode,
                        requiresSetup: !systemVM.hasPersistentLowPowerModeAccess,
                        languageCode: languageCode
                    ) {
                        systemVM.toggleLowPowerMode()
                    }
                }
            }
            .frame(height: 78)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var storageFreeGB: Double {
        max(0, systemVM.stats.storageTotalGB - systemVM.stats.storageUsedGB)
    }

    private func cpuColor(_ value: Double) -> Color {
        switch value {
        case ..<40: return .green
        case ..<75: return .yellow
        default:    return .red
        }
    }
}

private struct LanguageCenterMenuCard: View {
    let title: String
    @Binding var selection: String
    let isActive: Bool
    let action: () -> Void

    @State private var isHovered = false

    private var status: String {
        AppLanguage.current(selection).nativeTitle
    }

    var body: some View {
        Button(action: action) {
            languageCard
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var languageCard: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 2.4)
                    .frame(width: 28, height: 28)

                Circle()
                    .trim(from: 0, to: 0.9)
                    .stroke(
                        Color.mint.opacity(0.88),
                        style: StrokeStyle(lineWidth: 2.4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 28, height: 28)

                Image(systemName: "globe")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.mint)
            }

            HStack(spacing: 5) {
                Text(status)
                    .font(.system(size: 10.2, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)

                Image(systemName: "chevron.down")
                    .font(.system(size: 6.8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Text(title)
                .font(.system(size: 7.1, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(isActive ? 0.18 : (isHovered ? 0.1 : 0.05)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isActive ? Color.white.opacity(0.35) : Color.mint.opacity(0.22), lineWidth: isActive ? 1.2 : 1)
        )
    }
}

private struct CompactSystemMetricCard: View {
    let title: String
    let value: String
    let fraction: Double
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            MetricRing(
                fraction: fraction,
                icon: icon,
                color: color
            )

            VStack(spacing: 1) {
                Text(value)
                    .font(.system(size: 10.2, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)

                Text(title.uppercased())
                    .font(.system(size: 7.1, weight: .medium))
                    .foregroundStyle(.white.opacity(0.42))
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.045))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.16), lineWidth: 1)
        )
    }
}

private struct CompactBatteryMetricCard: View {
    let stats: SystemStats
    let isBusy: Bool
    let requiresSetup: Bool
    let languageCode: String
    let onToggleLPM: () -> Void

    @State private var isHovered = false

    private var color: Color {
        if stats.isLowPowerMode { return .orange }
        if stats.isCharging     { return .green  }
        switch stats.batteryLevel {
        case ..<20: return .red
        case ..<50: return .yellow
        default:    return .green
        }
    }

    private var iconName: String {
        if stats.isLowPowerMode { return "bolt.slash.fill" }
        if stats.isCharging     { return "battery.100.bolt" }
        return "battery.75"
    }

    private var title: String {
        if stats.isLowPowerMode { return L10n.tr(.lowPower, languageCode) }
        if stats.isCharging     { return L10n.tr(.charging, languageCode) }
        return L10n.tr(.battery, languageCode)
    }

    var body: some View {
        Button(action: onToggleLPM) {
            VStack(spacing: 5) {
                MetricRing(
                    fraction: Double(stats.batteryLevel) / 100,
                    icon: iconName,
                    color: color
                )

                VStack(spacing: 1) {
                    Text("\(stats.batteryLevel)%")
                        .font(.system(size: 10.2, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)

                    Text(title.uppercased())
                        .font(.system(size: 7.1, weight: .medium))
                        .foregroundStyle(.white.opacity(0.42))
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(isHovered ? 0.08 : 0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(color.opacity(stats.isLowPowerMode ? 0.32 : 0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .opacity(isBusy ? 0.72 : 1)
        .onHover { isHovered = $0 }
        .help(helpText)
    }

    private var helpText: String {
        L10n.lowPowerHelp(
            requiresSetup: requiresSetup,
            isLowPowerMode: stats.isLowPowerMode,
            languageCode
        )
    }
}

private struct MetricRing: View {
    let fraction: Double
    let icon: String
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 2.2)
                .frame(width: 28, height: 28)

            Circle()
                .trim(from: 0, to: min(max(fraction, 0), 1))
                .stroke(
                    color.opacity(0.86),
                    style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 28, height: 28)

            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Popup chrome

private struct PopupHeader: View {
    let title: String
    let subtitle: String?
    let onRefresh: (() -> Void)?
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            if let onRefresh {
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.62))
                        .padding(6)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(6)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }
}

private struct PopupContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.13, green: 0.08, blue: 0.20),
                            Color(red: 0.045, green: 0.035, blue: 0.07)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(red: 0.72, green: 0.55, blue: 1.0).opacity(0.20), lineWidth: 1)
        )
    }
}

private struct PopupMessageRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.orange.opacity(0.92))

            Text(text)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.orange.opacity(0.22), lineWidth: 1)
        )
    }
}

// MARK: - Language popup

struct LanguagePopupView: View {
    @ObservedObject var vm: QuickSettingsViewModel
    @AppStorage("nd_language") private var languageCode = AppLanguage.defaultCode

    var body: some View {
        PopupContainer {
            PopupHeader(
                title: L10n.tr(.language, languageCode),
                subtitle: nil,
                onRefresh: nil,
                onClose: { vm.closeCenterPopup() }
            )

            Divider().background(Color.white.opacity(0.08))

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 6),
                    GridItem(.flexible(), spacing: 6)
                ],
                spacing: 6
            ) {
                ForEach(AppLanguage.allCases) { language in
                    LanguageOptionButton(
                        language: language,
                        isSelected: languageCode == language.rawValue
                    ) {
                        languageCode = language.rawValue
                        vm.closeCenterPopup()
                    }
                }
            }
            .padding(10)
        }
    }
}

private struct LanguageOptionButton: View {
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(isSelected ? .mint : .white.opacity(0.28))

                Text(language.nativeTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(isSelected ? 0.96 : 0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 30)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.14 : (isHovered ? 0.09 : 0.05)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(isSelected ? Color.mint.opacity(0.32) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Bluetooth popup

struct BluetoothPopupView: View {
    @ObservedObject var vm: QuickSettingsViewModel
    @AppStorage("nd_language") private var languageCode = AppLanguage.defaultCode

    var body: some View {
        PopupContainer {
            PopupHeader(
                title: L10n.tr(.bluetooth, languageCode),
                subtitle: vm.bluetoothStatusText,
                onRefresh: vm.loadBluetoothDetails,
                onClose:   { vm.closeCenterPopup() }
            )

            Divider().background(Color.white.opacity(0.08))

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    if let message = vm.bluetoothErrorMessage {
                        PopupMessageRow(text: message)
                    }

                    DetailSectionLabel(text: L10n.tr(.pairedDevices, languageCode))

                    if vm.isLoadingBluetoothDetails {
                        LoadingRow(text: "Loading paired devices…")
                    } else if vm.bluetoothDevices.isEmpty {
                        EmptyStateRow(text: vm.isBluetoothOn ? L10n.tr(.noPairedDevices, languageCode) : L10n.tr(.turnBluetoothOn, languageCode))
                    } else {
                        ForEach(vm.bluetoothDevices) { device in
                            BluetoothDeviceRow(
                                device: device,
                                isLoading: vm.bluetoothActionDeviceID == device.id,
                                action: { vm.toggleBluetoothDevice(device) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }

            Divider().background(Color.white.opacity(0.08))

            PopupFooterButton(title: L10n.tr(.bluetoothSettings, languageCode)) {
                vm.closeCenterPopup()
                vm.openBluetoothSettings()
            }
        }
    }
}

// MARK: - Shared popup footer

private struct PopupFooterButton: View {
    let title: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.78))
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color.white.opacity(isHovered ? 0.06 : 0))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

private struct DetailSectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.white.opacity(0.38))
            .kerning(1.1)
            .padding(.top, 2)
    }
}

private struct BluetoothDeviceRow: View {
    let device: BluetoothDeviceItem
    let isLoading: Bool
    let action: () -> Void

    @State private var isHovered = false
    @AppStorage("nd_language") private var languageCode = AppLanguage.defaultCode

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill((device.isConnected ? Color.blue : Color.white).opacity(0.16))
                        .frame(width: 34, height: 34)

                    Image(systemName: device.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(device.isConnected ? .blue : .white.opacity(0.68))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(device.isConnected ? L10n.tr(.connected, languageCode) : L10n.tr(.paired, languageCode))
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    RowActionPill(
                        title: device.isConnected ? L10n.tr(.disconnect, languageCode) : L10n.tr(.connect, languageCode),
                        tint: device.isConnected ? .blue : .white,
                        isFilled: device.isConnected
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(isHovered ? 0.08 : 0.05))
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .onHover { isHovered = $0 }
    }
}

private struct RowActionPill: View {
    let title: String
    let tint: Color
    let isFilled: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 8.5, weight: .bold))
            .foregroundStyle(isFilled ? .white : tint.opacity(0.95))
            .kerning(0.5)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isFilled ? tint.opacity(0.82) : tint.opacity(0.12))
            )
    }
}

private struct LoadingRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)

            Text(text)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }
}

private struct EmptyStateRow: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10.5, weight: .medium))
            .foregroundStyle(.white.opacity(0.5))
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            )
    }
}
