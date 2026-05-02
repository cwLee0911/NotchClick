import SwiftUI

struct WeatherView: View {
    @EnvironmentObject var vm: WeatherViewModel
    @AppStorage("nd_language") private var languageCode = AppLanguage.defaultCode

    var body: some View {
        Group {
            if let weather = vm.weather {
                WeatherContent(weather: weather, languageCode: languageCode, isRefreshing: vm.isLoading)
            } else if vm.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "location.slash")
                        .font(.system(size: 22))
                        .foregroundStyle(.white.opacity(0.25))
                    Text(vm.errorMessage ?? L10n.tr(.fetchingWeather, languageCode))
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.4))
                    Button(L10n.tr(.retry, languageCode)) { vm.fetchWeather() }
                        .buttonStyle(GhostButtonStyle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            vm.fetchWeather()
        }
    }
}

// MARK: - Content

private struct WeatherContent: View {
    let weather: WeatherData
    let languageCode: String
    let isRefreshing: Bool
    private let forecastSpacing: CGFloat = 5

    var body: some View {
        GeometryReader { geo in
            let forecasts = Array(weather.hourlyForecast.prefix(8))
            let forecastCount = max(forecasts.count, 1)
            let tileWidth = max(
                34,
                floor((geo.size.width - CGFloat(forecastCount - 1) * forecastSpacing) / CGFloat(forecastCount))
            )

            VStack(alignment: .leading, spacing: 6) {
                summaryCard

                HStack(spacing: forecastSpacing) {
                    ForEach(forecasts) { forecast in
                        HourlyTile(forecast: forecast, timeZone: weather.timeZone)
                            .frame(width: tileWidth)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .overlay(alignment: .topTrailing) {
                if isRefreshing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.small)
                        .tint(.white.opacity(0.7))
                        .scaleEffect(0.58)
                        .padding(.top, 5)
                        .padding(.trailing, 6)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var summaryCard: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 34, height: 34)

                Image(systemName: weather.symbolName ?? weather.weatherCode.weatherIcon)
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.92))
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(String(format: "%.0f°", weather.temperature))
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.white)

                Text(weather.conditionDescription ?? weather.weatherCode.localizedWeatherDescription(languageCode))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 2) {
                Text(weather.cityName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                HStack(spacing: 5) {
                    MetricChip(icon: "wind", value: "\(Int(weather.windSpeed))")
                    MetricChip(icon: "humidity", value: "\(weather.humidity)%")
                }

                if let attributionURL = weather.attributionURL {
                    Link(destination: attributionURL) {
                        Text("Data: \(weather.attributionName ?? "Apple Weather")")
                            .font(.system(size: 8.2, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.58))
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.065),
                            Color.cyan.opacity(0.08),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Hourly Tile

private struct HourlyTile: View {
    let forecast: HourlyForecast
    let timeZone: TimeZone
    @AppStorage("nd_language") private var languageCode = AppLanguage.defaultCode

    private var timeLabel: String {
        if forecast.isCurrentHour { return L10n.tr(.now, languageCode) }
        return Self.timeFormatter(for: timeZone).string(from: forecast.time)
    }

    var body: some View {
        VStack(spacing: 3) {
            Text(timeLabel)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.white.opacity(0.56))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Image(systemName: forecast.symbolName ?? forecast.weatherCode.weatherIcon)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.88))
                .symbolRenderingMode(.hierarchical)

            Text(String(format: "%.0f°", forecast.temperature))
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(forecast.isCurrentHour ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    private static func timeFormatter(for timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        formatter.dateFormat = "ha"
        return formatter
    }
}

// MARK: - Metric Chip

private struct MetricChip: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 7.5))
                .foregroundStyle(.white.opacity(0.48))

            Text(value)
                .font(.system(size: 8.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.68))
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.06))
        )
    }
}
