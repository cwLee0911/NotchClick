import Foundation
import SwiftUI

final class UserPreferences: ObservableObject {
    static let shared = UserPreferences()
    private init() {
        normalizeLanguage()
        normalizeDefaultTab()
    }

    func normalizeLanguage() {
        let normalized = AppLanguage.normalizedCode(language)
        if language != normalized {
            language = normalized
        }
    }

    func normalizeDefaultTab() {
        let normalized = PanelTab.normalizedRawValue(defaultTab)
        if defaultTab != normalized {
            defaultTab = normalized
        }
    }

    @AppStorage("nd_launch_at_login")    var launchAtLogin   = false
    @AppStorage("nd_hover_delay")        var hoverDelay      = 0.18  // seconds
    @AppStorage("nd_dismiss_delay")      var dismissDelay    = 0.4
    @AppStorage("nd_default_tab")        var defaultTab      = "Launcher"
    @AppStorage("nd_music_provider")     var musicProvider   = ""
    @AppStorage("nd_language")           var language        = AppLanguage.defaultCode
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case korean = "ko"
    case chinese = "zh-Hans"
    case japanese = "ja"

    var id: String { rawValue }

    var nativeTitle: String {
        switch self {
        case .english: return "English"
        case .korean: return "한국어"
        case .chinese: return "中文"
        case .japanese: return "日本語"
        }
    }

    static var defaultCode: String {
        normalizedCode(Locale.preferredLanguages.first, fallback: english.rawValue)
    }

    static func normalizedCode(_ code: String?) -> String {
        normalizedCode(code, fallback: defaultCode)
    }

    private static func normalizedCode(_ code: String?, fallback: String) -> String {
        let trimmed = (code ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallback }

        let folded = trimmed
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()

        if folded.hasPrefix("ko") || folded == "kr" || folded.contains("korean") ||
            trimmed.contains("한국") || trimmed.contains("韓国") || trimmed.contains("韩") {
            return korean.rawValue
        }

        if folded.hasPrefix("ja") || folded.contains("japanese") ||
            trimmed.contains("日本") || trimmed.contains("일본") || trimmed.contains("日语") {
            return japanese.rawValue
        }

        if folded.hasPrefix("zh") || folded.contains("chinese") ||
            trimmed.contains("中文") || trimmed.contains("中国") || trimmed.contains("중국") {
            return chinese.rawValue
        }

        if folded.hasPrefix("en") || folded.contains("english") ||
            trimmed.contains("영어") || trimmed.contains("英語") || trimmed.contains("英语") {
            return english.rawValue
        }

        return fallback
    }

    static func current(_ code: String) -> AppLanguage {
        AppLanguage(rawValue: normalizedCode(code)) ?? .english
    }
}

enum L10n {
    enum Key: String {
        case launcher, music, weather, system, center
        case language, bluetooth, choose, choosePlayer, actions
        case on, off, unavailable
        case connected, paired, connect, disconnect, current, join
        case displayLanguage, languageDescription
        case english, korean, chinese, japanese
        case addApp, chooseApp, searchInstalledApps, noAppsFound, noMatches
        case addAppHelp, launcherFullHelp
        case retry, fetchingWeather, now
        case cpu, memory, storage, charging, battery, lowPower
        case setMusicApp, chooseMusicApp, openCenter
        case selected, chooseAction, openMusic, openSpotify
        case appleMusicSubtitle, spotifySubtitle
        case appNotRunning, nothingPlaying, permissionNeeded
        case appNotRunningMessage, nothingPlayingMessage
        case bluetoothOn, bluetoothOff, pairedDevices
        case pairedDevicesSubtitle, bluetoothSettingsHint
        case noPairedDevices, turnBluetoothOn, bluetoothSettings
        case general, appearance, about, behavior, launchAtLogin, defaultTab
        case notch, notchDescription, appearanceComingSoon, aboutDescription
        case launchAtLoginUpdateFailed, launchAtLoginNeedsApproval, launchAtLoginUnavailable, launchAtLoginStatusUnknown
        case version
        case clearSky, partlyCloudy, foggy, drizzle, freezingDrizzle, rain
        case freezingRain, snow, snowGrains, rainShowers, snowShowers
        case thunderstorm, unknown
    }

    static func tr(_ key: Key, _ languageCode: String) -> String {
        let language = AppLanguage.current(languageCode)
        return table[language]?[key] ?? table[.english]?[key] ?? key.rawValue
    }

    private static let table: [AppLanguage: [Key: String]] = [
        .english: [
            .launcher: "Launcher", .music: "Music", .weather: "Weather", .system: "System", .center: "Center",
            .language: "Language", .bluetooth: "Bluetooth", .choose: "Choose", .choosePlayer: "Choose Player", .actions: "Actions",
            .on: "On", .off: "Off", .unavailable: "Unavailable",
            .connected: "Connected", .paired: "Paired", .connect: "CONNECT", .disconnect: "DISCONNECT", .current: "CURRENT", .join: "JOIN",
            .displayLanguage: "Display Language", .languageDescription: "Choose the display language for NotchClick.",
            .english: "English", .korean: "Korean", .chinese: "Chinese", .japanese: "Japanese",
            .addApp: "Add App", .chooseApp: "Choose an app", .searchInstalledApps: "Search installed apps...", .noAppsFound: "No apps found", .noMatches: "No matches",
            .addAppHelp: "Add App", .launcherFullHelp: "Launcher is full",
            .retry: "Retry", .fetchingWeather: "Fetching weather...", .now: "Now",
            .cpu: "CPU", .memory: "Memory", .storage: "Storage", .charging: "Charging", .battery: "Battery", .lowPower: "Low Power",
            .setMusicApp: "Choose a music app",
            .chooseMusicApp: "Choose Apple Music or Spotify above, then this screen will switch to that player automatically.",
            .openCenter: "Open Center", .selected: "SELECTED", .chooseAction: "CHOOSE", .openMusic: "Open Music", .openSpotify: "Open Spotify",
            .appleMusicSubtitle: "Built into macOS", .spotifySubtitle: "Control the Spotify app",
            .appNotRunning: "isn't running", .nothingPlaying: "Nothing playing", .permissionNeeded: "Permission needed",
            .appNotRunningMessage: "Launch the app to show the current song and playback controls.",
            .nothingPlayingMessage: "Start a song and it will appear here.",
            .bluetoothOn: "Bluetooth is On", .bluetoothOff: "Bluetooth is Off", .pairedDevices: "Paired Devices",
            .pairedDevicesSubtitle: "Paired devices and recent accessories", .bluetoothSettingsHint: "Use Bluetooth Settings to turn Bluetooth on on this Mac.",
            .noPairedDevices: "No paired devices found.", .turnBluetoothOn: "Turn Bluetooth on to see your devices.", .bluetoothSettings: "Bluetooth Settings...",
            .general: "General", .appearance: "Appearance", .about: "About", .behavior: "Behavior", .launchAtLogin: "Launch at login", .defaultTab: "Default tab",
            .notch: "Notch", .notchDescription: "Open NotchClick by clicking the top-center notch target.",
            .appearanceComingSoon: "Visual customization options will appear here as the notch styling expands.",
            .aboutDescription: "A beautiful notch panel for macOS.\nApp launcher, Apple Music, Spotify, weather, and more.",
            .launchAtLoginUpdateFailed: "Couldn't update launch at login right now.",
            .launchAtLoginNeedsApproval: "Approve NotchClick in Login Items to finish enabling launch at login.",
            .launchAtLoginUnavailable: "Launch at login isn't available in this build.",
            .launchAtLoginStatusUnknown: "Couldn't determine the current launch at login status.",
            .version: "Version",
            .clearSky: "Clear Sky", .partlyCloudy: "Partly Cloudy", .foggy: "Foggy", .drizzle: "Drizzle",
            .freezingDrizzle: "Freezing Drizzle", .rain: "Rain", .freezingRain: "Freezing Rain",
            .snow: "Snow", .snowGrains: "Snow Grains", .rainShowers: "Rain Showers",
            .snowShowers: "Snow Showers", .thunderstorm: "Thunderstorm", .unknown: "Unknown"
        ],
        .korean: [
            .launcher: "런처", .music: "음악", .weather: "날씨", .system: "시스템", .center: "센터",
            .language: "언어", .bluetooth: "블루투스", .choose: "선택", .choosePlayer: "플레이어 선택", .actions: "동작",
            .on: "켜짐", .off: "꺼짐", .unavailable: "사용 불가",
            .connected: "연결됨", .paired: "페어링됨", .connect: "연결", .disconnect: "연결 해제", .current: "현재", .join: "연결",
            .displayLanguage: "표시 언어", .languageDescription: "NotchClick에 표시할 언어를 선택하세요.",
            .english: "영어", .korean: "한국어", .chinese: "중국어", .japanese: "일본어",
            .addApp: "앱 추가", .chooseApp: "앱 선택", .searchInstalledApps: "설치된 앱 검색...", .noAppsFound: "앱을 찾을 수 없음", .noMatches: "일치 항목 없음",
            .addAppHelp: "앱 추가", .launcherFullHelp: "런처가 가득 찼습니다",
            .retry: "다시 시도", .fetchingWeather: "날씨를 가져오는 중...", .now: "지금",
            .cpu: "CPU", .memory: "메모리", .storage: "저장공간", .charging: "충전 중", .battery: "배터리", .lowPower: "저전력",
            .setMusicApp: "음악 앱을 선택하세요",
            .chooseMusicApp: "위에서 Apple Music 또는 Spotify를 선택하면 이 화면이 자동으로 해당 플레이어로 바뀝니다.",
            .openCenter: "센터 열기", .selected: "선택됨", .chooseAction: "선택", .openMusic: "음악 열기", .openSpotify: "Spotify 열기",
            .appleMusicSubtitle: "macOS 기본 앱", .spotifySubtitle: "Spotify 앱 제어",
            .appNotRunning: "실행 중이 아님", .nothingPlaying: "재생 중인 음악 없음", .permissionNeeded: "권한 필요",
            .appNotRunningMessage: "앱을 실행하면 현재 곡과 재생 컨트롤이 표시됩니다.",
            .nothingPlayingMessage: "노래를 재생하면 여기에 표시됩니다.",
            .bluetoothOn: "블루투스 켜짐", .bluetoothOff: "블루투스 꺼짐", .pairedDevices: "페어링된 기기",
            .pairedDevicesSubtitle: "페어링된 기기와 최근 액세서리", .bluetoothSettingsHint: "이 Mac에서 블루투스를 켜려면 블루투스 설정을 사용하세요.",
            .noPairedDevices: "페어링된 기기가 없습니다.", .turnBluetoothOn: "기기를 보려면 블루투스를 켜세요.", .bluetoothSettings: "블루투스 설정...",
            .general: "일반", .appearance: "외관", .about: "정보", .behavior: "동작", .launchAtLogin: "로그인 시 실행", .defaultTab: "기본 탭",
            .notch: "노치", .notchDescription: "화면 상단 중앙의 노치 영역을 클릭해 NotchClick을 엽니다.",
            .appearanceComingSoon: "노치 스타일이 확장되면 시각적 커스터마이징 옵션이 여기에 표시됩니다.",
            .aboutDescription: "macOS를 위한 아름다운 노치 패널.\n앱 런처, Apple Music, Spotify, 날씨 등을 제공합니다.",
            .launchAtLoginUpdateFailed: "지금은 로그인 시 실행 설정을 변경할 수 없습니다.",
            .launchAtLoginNeedsApproval: "로그인 시 실행을 완료하려면 로그인 항목에서 NotchClick을 승인하세요.",
            .launchAtLoginUnavailable: "이 빌드에서는 로그인 시 실행을 사용할 수 없습니다.",
            .launchAtLoginStatusUnknown: "현재 로그인 시 실행 상태를 확인할 수 없습니다.",
            .version: "버전",
            .clearSky: "맑음", .partlyCloudy: "구름 조금", .foggy: "안개", .drizzle: "이슬비",
            .freezingDrizzle: "어는 이슬비", .rain: "비", .freezingRain: "어는 비",
            .snow: "눈", .snowGrains: "싸락눈", .rainShowers: "소나기",
            .snowShowers: "눈 소나기", .thunderstorm: "뇌우", .unknown: "알 수 없음"
        ],
        .chinese: [
            .launcher: "启动器", .music: "音乐", .weather: "天气", .system: "系统", .center: "中心",
            .language: "语言", .bluetooth: "蓝牙", .choose: "选择", .choosePlayer: "选择播放器", .actions: "操作",
            .on: "开启", .off: "关闭", .unavailable: "不可用",
            .connected: "已连接", .paired: "已配对", .connect: "连接", .disconnect: "断开", .current: "当前", .join: "加入",
            .displayLanguage: "显示语言", .languageDescription: "选择 NotchClick 的显示语言。",
            .english: "英语", .korean: "韩语", .chinese: "中文", .japanese: "日语",
            .addApp: "添加应用", .chooseApp: "选择应用", .searchInstalledApps: "搜索已安装的应用...", .noAppsFound: "未找到应用", .noMatches: "没有匹配项",
            .addAppHelp: "添加应用", .launcherFullHelp: "启动器已满",
            .retry: "重试", .fetchingWeather: "正在获取天气...", .now: "现在",
            .cpu: "CPU", .memory: "内存", .storage: "存储", .charging: "充电中", .battery: "电池", .lowPower: "低电量",
            .setMusicApp: "选择音乐应用",
            .chooseMusicApp: "在上方选择 Apple Music 或 Spotify 后，此页面会自动切换到对应播放器。",
            .openCenter: "打开中心", .selected: "已选择", .chooseAction: "选择", .openMusic: "打开音乐", .openSpotify: "打开 Spotify",
            .appleMusicSubtitle: "macOS 内置", .spotifySubtitle: "控制 Spotify 应用",
            .appNotRunning: "未运行", .nothingPlaying: "没有播放内容", .permissionNeeded: "需要权限",
            .appNotRunningMessage: "启动应用后会显示当前歌曲和播放控制。",
            .nothingPlayingMessage: "开始播放歌曲后会显示在这里。",
            .bluetoothOn: "蓝牙已开启", .bluetoothOff: "蓝牙已关闭", .pairedDevices: "已配对设备",
            .pairedDevicesSubtitle: "已配对设备和最近的配件", .bluetoothSettingsHint: "请在蓝牙设置中开启此 Mac 的蓝牙。",
            .noPairedDevices: "未找到已配对设备。", .turnBluetoothOn: "开启蓝牙以查看设备。", .bluetoothSettings: "蓝牙设置...",
            .general: "通用", .appearance: "外观", .about: "关于", .behavior: "行为", .launchAtLogin: "登录时启动", .defaultTab: "默认标签",
            .notch: "刘海", .notchDescription: "点击屏幕顶部中央的刘海区域打开 NotchClick。",
            .appearanceComingSoon: "随着刘海样式扩展，视觉自定义选项会显示在这里。",
            .aboutDescription: "适用于 macOS 的精美刘海面板。\n包含应用启动器、Apple Music、Spotify、天气等功能。",
            .launchAtLoginUpdateFailed: "现在无法更新登录时启动设置。",
            .launchAtLoginNeedsApproval: "请在登录项中批准 NotchClick 以完成登录时启动。",
            .launchAtLoginUnavailable: "此构建不支持登录时启动。",
            .launchAtLoginStatusUnknown: "无法确定当前登录时启动状态。",
            .version: "版本",
            .clearSky: "晴朗", .partlyCloudy: "局部多云", .foggy: "有雾", .drizzle: "毛毛雨",
            .freezingDrizzle: "冻毛毛雨", .rain: "下雨", .freezingRain: "冻雨",
            .snow: "下雪", .snowGrains: "雪粒", .rainShowers: "阵雨",
            .snowShowers: "阵雪", .thunderstorm: "雷暴", .unknown: "未知"
        ],
        .japanese: [
            .launcher: "ランチャー", .music: "音楽", .weather: "天気", .system: "システム", .center: "センター",
            .language: "言語", .bluetooth: "Bluetooth", .choose: "選択", .choosePlayer: "プレイヤーを選択", .actions: "操作",
            .on: "オン", .off: "オフ", .unavailable: "利用不可",
            .connected: "接続済み", .paired: "ペアリング済み", .connect: "接続", .disconnect: "切断", .current: "現在", .join: "接続",
            .displayLanguage: "表示言語", .languageDescription: "NotchClick の表示言語を選択します。",
            .english: "英語", .korean: "韓国語", .chinese: "中国語", .japanese: "日本語",
            .addApp: "アプリを追加", .chooseApp: "アプリを選択", .searchInstalledApps: "インストール済みアプリを検索...", .noAppsFound: "アプリが見つかりません", .noMatches: "一致なし",
            .addAppHelp: "アプリを追加", .launcherFullHelp: "ランチャーがいっぱいです",
            .retry: "再試行", .fetchingWeather: "天気を取得中...", .now: "現在",
            .cpu: "CPU", .memory: "メモリ", .storage: "ストレージ", .charging: "充電中", .battery: "バッテリー", .lowPower: "低電力",
            .setMusicApp: "音楽アプリを選択",
            .chooseMusicApp: "上で Apple Music または Spotify を選ぶと、この画面が自動で切り替わります。",
            .openCenter: "センターを開く", .selected: "選択済み", .chooseAction: "選択", .openMusic: "ミュージックを開く", .openSpotify: "Spotify を開く",
            .appleMusicSubtitle: "macOS 内蔵", .spotifySubtitle: "Spotify アプリを操作",
            .appNotRunning: "起動していません", .nothingPlaying: "再生中の曲はありません", .permissionNeeded: "権限が必要",
            .appNotRunningMessage: "アプリを起動すると、現在の曲と再生コントロールが表示されます。",
            .nothingPlayingMessage: "曲を再生するとここに表示されます。",
            .bluetoothOn: "Bluetooth オン", .bluetoothOff: "Bluetooth オフ", .pairedDevices: "ペアリング済みデバイス",
            .pairedDevicesSubtitle: "ペアリング済みデバイスと最近のアクセサリ", .bluetoothSettingsHint: "この Mac で Bluetooth をオンにするには Bluetooth 設定を使用してください。",
            .noPairedDevices: "ペアリング済みデバイスがありません。", .turnBluetoothOn: "デバイスを表示するには Bluetooth をオンにしてください。", .bluetoothSettings: "Bluetooth 設定...",
            .general: "一般", .appearance: "外観", .about: "情報", .behavior: "動作", .launchAtLogin: "ログイン時に起動", .defaultTab: "デフォルトタブ",
            .notch: "ノッチ", .notchDescription: "画面上部中央のノッチ領域をクリックして NotchClick を開きます。",
            .appearanceComingSoon: "ノッチのスタイルが拡張されると、カスタマイズ項目がここに表示されます。",
            .aboutDescription: "macOS のための美しいノッチパネル。\nアプリランチャー、Apple Music、Spotify、天気などに対応。",
            .launchAtLoginUpdateFailed: "ログイン時の起動設定を今は更新できません。",
            .launchAtLoginNeedsApproval: "ログイン時の起動を完了するには、ログイン項目で NotchClick を承認してください。",
            .launchAtLoginUnavailable: "このビルドではログイン時の起動を利用できません。",
            .launchAtLoginStatusUnknown: "現在のログイン時起動の状態を確認できません。",
            .version: "バージョン",
            .clearSky: "晴れ", .partlyCloudy: "一部曇り", .foggy: "霧", .drizzle: "霧雨",
            .freezingDrizzle: "着氷性霧雨", .rain: "雨", .freezingRain: "着氷性雨",
            .snow: "雪", .snowGrains: "雪粒", .rainShowers: "にわか雨",
            .snowShowers: "にわか雪", .thunderstorm: "雷雨", .unknown: "不明"
        ]
    ]

    static func musicAutomationMessage(appName: String, _ languageCode: String) -> String {
        switch AppLanguage.current(languageCode) {
        case .english:
            return "Allow NotchClick to control \(appName) in System Settings > Privacy & Security > Automation."
        case .korean:
            return "시스템 설정 > 개인정보 보호 및 보안 > 자동화에서 NotchClick이 \(appName)을 제어하도록 허용하세요."
        case .chinese:
            return "请在系统设置 > 隐私与安全性 > 自动化中允许 NotchClick 控制 \(appName)。"
        case .japanese:
            return "システム設定 > プライバシーとセキュリティ > オートメーションで NotchClick に \(appName) の制御を許可してください。"
        }
    }

    static func openAppAndRetryMessage(appName: String, _ languageCode: String) -> String {
        switch AppLanguage.current(languageCode) {
        case .english: return "Open \(appName) and try again."
        case .korean: return "\(appName)을 열고 다시 시도하세요."
        case .chinese: return "请打开 \(appName) 后重试。"
        case .japanese: return "\(appName) を開いてもう一度お試しください。"
        }
    }

    static func musicCommunicationMessage(appName: String, detail: String?, _ languageCode: String) -> String {
        switch AppLanguage.current(languageCode) {
        case .english:
            return detail.map { "Couldn't communicate with \(appName): \($0)" }
                ?? "Couldn't communicate with \(appName) right now."
        case .korean:
            return detail.map { "\(appName)과 통신할 수 없습니다: \($0)" }
                ?? "지금은 \(appName)과 통신할 수 없습니다."
        case .chinese:
            return detail.map { "无法与 \(appName) 通信：\($0)" }
                ?? "现在无法与 \(appName) 通信。"
        case .japanese:
            return detail.map { "\(appName) と通信できません: \($0)" }
                ?? "現在 \(appName) と通信できません。"
        }
    }

    static func locationAccessMessage(_ languageCode: String) -> String {
        switch AppLanguage.current(languageCode) {
        case .english: return "Allow Location access in System Settings to show local weather."
        case .korean: return "현재 위치 날씨를 표시하려면 시스템 설정에서 위치 접근을 허용하세요."
        case .chinese: return "请在系统设置中允许位置访问以显示本地天气。"
        case .japanese: return "現在地の天気を表示するには、システム設定で位置情報へのアクセスを許可してください。"
        }
    }

    static func locationUnavailableMessage(_ languageCode: String) -> String {
        switch AppLanguage.current(languageCode) {
        case .english: return "Location access isn't available on this Mac."
        case .korean: return "이 Mac에서는 위치 접근을 사용할 수 없습니다."
        case .chinese: return "此 Mac 无法使用位置访问。"
        case .japanese: return "この Mac では位置情報へのアクセスを利用できません。"
        }
    }

    static func locationUnknownMessage(_ languageCode: String) -> String {
        switch AppLanguage.current(languageCode) {
        case .english: return "Your location couldn't be determined right now. Try again in a moment."
        case .korean: return "지금은 위치를 확인할 수 없습니다. 잠시 후 다시 시도하세요."
        case .chinese: return "现在无法确定你的位置，请稍后重试。"
        case .japanese: return "現在位置を特定できません。少し待ってからもう一度お試しください。"
        }
    }

    static func locationFetchFailedMessage(_ languageCode: String) -> String {
        switch AppLanguage.current(languageCode) {
        case .english: return "Couldn't fetch your current location."
        case .korean: return "현재 위치를 가져올 수 없습니다."
        case .chinese: return "无法获取当前位置。"
        case .japanese: return "現在位置を取得できませんでした。"
        }
    }

    static func weatherParseFailedMessage(_ languageCode: String) -> String {
        switch AppLanguage.current(languageCode) {
        case .english: return "Weather data couldn't be parsed."
        case .korean: return "날씨 데이터를 해석할 수 없습니다."
        case .chinese: return "无法解析天气数据。"
        case .japanese: return "天気データを解析できませんでした。"
        }
    }


    static func weatherFetchFailedMessage(_ languageCode: String) -> String {
        switch AppLanguage.current(languageCode) {
        case .english: return "Couldn't fetch weather right now. Try again in a moment."
        case .korean: return "지금은 날씨를 가져올 수 없습니다. 잠시 후 다시 시도하세요."
        case .chinese: return "现在无法获取天气，请稍后重试。"
        case .japanese: return "現在天気を取得できません。少し待ってからもう一度お試しください。"
        }
    }

    static func lowPowerApprovalMessage(_ languageCode: String) -> String {
        switch AppLanguage.current(languageCode) {
        case .english: return "Approve NotchClick in System Settings > Login Items once, then Low Power Mode can toggle without prompts."
        case .korean: return "시스템 설정 > 로그인 항목에서 NotchClick을 한 번 승인하면 저전력 모드를 묻지 않고 전환할 수 있습니다."
        case .chinese: return "在系统设置 > 登录项中批准一次 NotchClick 后，即可无需提示切换低电量模式。"
        case .japanese: return "システム設定 > ログイン項目で NotchClick を一度承認すると、低電力モードを確認なしで切り替えられます。"
        }
    }

    static func lowPowerSetupNeededMessage(_ languageCode: String) -> String {
        switch AppLanguage.current(languageCode) {
        case .english: return "One-time admin setup is still needed. After that, Low Power Mode won't ask again on this Mac."
        case .korean: return "관리자 설정이 한 번 더 필요합니다. 이후에는 이 Mac에서 다시 묻지 않습니다."
        case .chinese: return "仍需要一次管理员设置。之后此 Mac 上不会再次询问。"
        case .japanese: return "一度だけ管理者設定が必要です。その後、この Mac では再確認なしで使えます。"
        }
    }

    static func lowPowerCancelledMessage(_ languageCode: String) -> String {
        switch AppLanguage.current(languageCode) {
        case .english: return "Cancelled. Admin password is needed once to enable one-tap Low Power Mode."
        case .korean: return "취소되었습니다. 원터치 저전력 모드를 사용하려면 관리자 암호가 한 번 필요합니다."
        case .chinese: return "已取消。启用一键低电量模式需要输入一次管理员密码。"
        case .japanese: return "キャンセルされました。ワンタップ低電力モードには一度だけ管理者パスワードが必要です。"
        }
    }

    static func lowPowerApplyFailedMessage(_ languageCode: String) -> String {
        switch AppLanguage.current(languageCode) {
        case .english: return "macOS didn't apply the requested Low Power Mode change."
        case .korean: return "macOS가 요청한 저전력 모드 변경을 적용하지 않았습니다."
        case .chinese: return "macOS 未应用请求的低电量模式更改。"
        case .japanese: return "macOS が要求された低電力モードの変更を適用しませんでした。"
        }
    }

    static func lowPowerFailureMessage(shouldEnable: Bool, reason: LowPowerFailureReason, _ languageCode: String) -> String {
        let action = localizedLowPowerAction(shouldEnable: shouldEnable, languageCode)
        switch (AppLanguage.current(languageCode), reason) {
        case (.english, .setup):
            return "One-time admin setup is needed before NotchClick can \(action) Low Power Mode without repeated prompts."
        case (.english, .admin):
            return "Couldn't \(action) Low Power Mode because this macOS setup requires admin privileges."
        case (.english, .permission):
            return "Couldn't \(action) Low Power Mode because macOS denied the pmset command."
        case (.english, .generic):
            return "Couldn't \(action) Low Power Mode right now."
        case (.korean, .setup):
            return "NotchClick이 저전력 모드를 반복 확인 없이 \(action)하려면 관리자 설정이 한 번 필요합니다."
        case (.korean, .admin):
            return "이 macOS 설정에는 관리자 권한이 필요해서 저전력 모드를 \(action)할 수 없습니다."
        case (.korean, .permission):
            return "macOS가 pmset 명령을 거부해서 저전력 모드를 \(action)할 수 없습니다."
        case (.korean, .generic):
            return "지금은 저전력 모드를 \(action)할 수 없습니다."
        case (.chinese, .setup):
            return "NotchClick 需要一次管理员设置，之后才能无需反复提示地\(action)低电量模式。"
        case (.chinese, .admin):
            return "此 macOS 设置需要管理员权限，因此无法\(action)低电量模式。"
        case (.chinese, .permission):
            return "macOS 拒绝了 pmset 命令，因此无法\(action)低电量模式。"
        case (.chinese, .generic):
            return "现在无法\(action)低电量模式。"
        case (.japanese, .setup):
            return "NotchClick が確認なしで低電力モードを\(action)するには、一度だけ管理者設定が必要です。"
        case (.japanese, .admin):
            return "この macOS 設定では管理者権限が必要なため、低電力モードを\(action)できません。"
        case (.japanese, .permission):
            return "macOS が pmset コマンドを拒否したため、低電力モードを\(action)できません。"
        case (.japanese, .generic):
            return "現在、低電力モードを\(action)できません。"
        }
    }

    static func lowPowerHelp(requiresSetup: Bool, isLowPowerMode: Bool, _ languageCode: String) -> String {
        if requiresSetup {
            switch AppLanguage.current(languageCode) {
            case .english: return "Click to complete one-time setup for passwordless Low Power Mode toggling."
            case .korean: return "클릭해서 암호 없이 저전력 모드를 전환하기 위한 1회 설정을 완료하세요."
            case .chinese: return "点击完成一次性设置，以便无需密码切换低电量模式。"
            case .japanese: return "クリックして、パスワードなしで低電力モードを切り替えるための初回設定を完了します。"
            }
        }

        switch (AppLanguage.current(languageCode), isLowPowerMode) {
        case (.english, true): return "Click to disable Low Power Mode"
        case (.english, false): return "Click to enable Low Power Mode"
        case (.korean, true): return "클릭해서 저전력 모드를 끄기"
        case (.korean, false): return "클릭해서 저전력 모드를 켜기"
        case (.chinese, true): return "点击关闭低电量模式"
        case (.chinese, false): return "点击开启低电量模式"
        case (.japanese, true): return "クリックして低電力モードをオフ"
        case (.japanese, false): return "クリックして低電力モードをオン"
        }
    }

    private static func localizedLowPowerAction(shouldEnable: Bool, _ languageCode: String) -> String {
        switch (AppLanguage.current(languageCode), shouldEnable) {
        case (.english, true): return "enable"
        case (.english, false): return "disable"
        case (.korean, true): return "켤 수"
        case (.korean, false): return "끌 수"
        case (.chinese, true): return "开启"
        case (.chinese, false): return "关闭"
        case (.japanese, true): return "オンに"
        case (.japanese, false): return "オフに"
        }
    }
}

enum LowPowerFailureReason {
    case setup
    case admin
    case permission
    case generic
}

extension MusicProvider {
    func localizedSubtitle(_ languageCode: String) -> String {
        switch self {
        case .appleMusic: return L10n.tr(.appleMusicSubtitle, languageCode)
        case .spotify: return L10n.tr(.spotifySubtitle, languageCode)
        }
    }

    func localizedOpenActionTitle(_ languageCode: String) -> String {
        switch self {
        case .appleMusic: return L10n.tr(.openMusic, languageCode)
        case .spotify: return L10n.tr(.openSpotify, languageCode)
        }
    }
}

extension PanelTab {
    static func fromStored(_ value: String) -> PanelTab {
        PanelTab(rawValue: normalizedRawValue(value)) ?? .launcher
    }

    static func normalizedRawValue(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let folded = trimmed
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()

        if folded == "launcher" || folded == "launch" ||
            trimmed.contains("런처") || trimmed.contains("启动器") || trimmed.contains("啟動器") || trimmed.contains("ランチャ") {
            return launcher.rawValue
        }

        if folded == "music" || folded.contains("music") ||
            trimmed.contains("음악") || trimmed.contains("音乐") || trimmed.contains("音楽") {
            return music.rawValue
        }

        if folded == "weather" || folded.contains("weather") ||
            trimmed.contains("날씨") || trimmed.contains("天气") || trimmed.contains("天気") {
            return weather.rawValue
        }

        if folded == "center" || folded == "controls" || folded == "control" || folded == "system" ||
            trimmed.contains("센터") || trimmed.contains("中心") || trimmed.contains("センター") ||
            trimmed.contains("시스템") || trimmed.contains("系统") || trimmed.contains("システム") {
            return center.rawValue
        }

        return launcher.rawValue
    }

    func localizedTitle(_ languageCode: String) -> String {
        switch self {
        case .launcher: return L10n.tr(.launcher, languageCode)
        case .music: return L10n.tr(.music, languageCode)
        case .weather: return L10n.tr(.weather, languageCode)
        case .center: return L10n.tr(.center, languageCode)
        }
    }
}

extension Int {
    func localizedWeatherDescription(_ languageCode: String) -> String {
        let key: L10n.Key
        switch self {
        case 0: key = .clearSky
        case 1, 2, 3: key = .partlyCloudy
        case 45, 48: key = .foggy
        case 51, 53, 55: key = .drizzle
        case 56, 57: key = .freezingDrizzle
        case 61, 63, 65: key = .rain
        case 66, 67: key = .freezingRain
        case 71, 73, 75: key = .snow
        case 77: key = .snowGrains
        case 80, 81, 82: key = .rainShowers
        case 85, 86: key = .snowShowers
        case 95, 96, 99: key = .thunderstorm
        default: key = .unknown
        }
        return L10n.tr(key, languageCode)
    }
}
