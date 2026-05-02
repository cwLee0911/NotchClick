import Foundation
import CoreLocation

// MARK: - Models

struct WeatherData {
    var temperature: Double      // Celsius
    var weatherCode: Int
    var windSpeed:   Double      // km/h
    var humidity:    Int         // %
    var cityName:    String
    var timeZone:    TimeZone
    var hourlyForecast: [HourlyForecast]
    var symbolName: String?
    var conditionDescription: String?
    var attributionName: String?
    var attributionURL: URL?
}

struct HourlyForecast: Identifiable {
    var time: Date
    var temperature: Double
    var weatherCode: Int
    var isCurrentHour: Bool
    var symbolName: String?
    var conditionDescription: String?

    var id: Date { time }
}

// WMO Weather Interpretation Codes
extension Int {
    var weatherDescription: String {
        switch self {
        case 0:         return "Clear Sky"
        case 1, 2, 3:   return "Partly Cloudy"
        case 45, 48:    return "Foggy"
        case 51, 53, 55: return "Drizzle"
        case 56, 57:    return "Freezing Drizzle"
        case 61, 63, 65: return "Rain"
        case 66, 67:    return "Freezing Rain"
        case 71, 73, 75: return "Snow"
        case 77:        return "Snow Grains"
        case 80, 81, 82: return "Rain Showers"
        case 85, 86:    return "Snow Showers"
        case 95, 96, 99: return "Thunderstorm"
        default:         return "Unknown"
        }
    }

    var weatherIcon: String {
        switch self {
        case 0:          return "sun.max.fill"
        case 1, 2:       return "cloud.sun.fill"
        case 3:          return "cloud.fill"
        case 45, 48:     return "cloud.fog.fill"
        case 51...55:    return "cloud.drizzle.fill"
        case 56, 57:     return "cloud.sleet.fill"
        case 61...65:    return "cloud.rain.fill"
        case 66, 67:     return "cloud.sleet.fill"
        case 71...75:    return "cloud.snow.fill"
        case 77:         return "snowflake"
        case 80...82:    return "cloud.heavyrain.fill"
        case 85, 86:     return "snowflake.circle.fill"
        case 95, 96, 99: return "cloud.bolt.fill"
        default:         return "questionmark.circle"
        }
    }
}

// MARK: - Service

final class WeatherService {
    static let shared = WeatherService()
    private init() {}

    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherData {
        return try await fetchOpenMeteoWeather(latitude: latitude, longitude: longitude)
    }

    private func mergedCurrentForecast(
        current: HourlyForecast,
        hourly: [HourlyForecast],
        calendar: Calendar
    ) -> [HourlyForecast] {
        let upcoming = hourly.filter { forecast in
            forecast.time > current.time &&
            !calendar.isDate(forecast.time, equalTo: current.time, toGranularity: .hour)
        }

        return Array(([current] + upcoming).prefix(10))
    }

    private func fetchOpenMeteoWeather(latitude: Double, longitude: Double) async throws -> WeatherData {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(
                name: "current",
                value: "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m"
            ),
            URLQueryItem(name: "hourly", value: "temperature_2m,weather_code"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "temperature_unit", value: "celsius"),
            URLQueryItem(name: "wind_speed_unit", value: "kmh"),
            URLQueryItem(name: "forecast_days", value: "2")
        ]

        guard let url = components?.url else { throw URLError(.badURL) }

        let request = URLRequest(url: url, timeoutInterval: 6)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw URLError(.badServerResponse)
        }

        let json = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        let timeZone = TimeZone(identifier: json.timezone) ?? .current
        let formatter = Self.dateFormatter(for: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        guard let currentDate = formatter.date(from: json.current.time) else {
            throw WeatherServiceError.invalidResponse
        }

        let hourlyTimes = try json.hourly.time.map { rawTime in
            guard let date = formatter.date(from: rawTime) else {
                throw WeatherServiceError.invalidResponse
            }
            return date
        }

        let availableCount = min(
            hourlyTimes.count,
            json.hourly.temperature_2m.count,
            json.hourly.weather_code.count
        )

        let rawHourly = (0..<availableCount).map { index in
            let time = hourlyTimes[index]
            return HourlyForecast(
                time: time,
                temperature: json.hourly.temperature_2m[index],
                weatherCode: json.hourly.weather_code[index],
                isCurrentHour: calendar.isDate(time, equalTo: currentDate, toGranularity: .hour),
                symbolName: nil,
                conditionDescription: nil
            )
        }

        let currentForecast = HourlyForecast(
            time: currentDate,
            temperature: json.current.temperature_2m,
            weatherCode: json.current.weather_code,
            isCurrentHour: true,
            symbolName: nil,
            conditionDescription: nil
        )

        return WeatherData(
            temperature: currentForecast.temperature,
            weatherCode: currentForecast.weatherCode,
            windSpeed: json.current.wind_speed_10m,
            humidity: json.current.relative_humidity_2m,
            cityName: "",
            timeZone: timeZone,
            hourlyForecast: mergedCurrentForecast(current: currentForecast, hourly: rawHourly, calendar: calendar),
            symbolName: nil,
            conditionDescription: nil,
            attributionName: nil,
            attributionURL: nil
        )
    }

    private static func dateFormatter(for timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter
    }
}

// MARK: - Codable Response

private struct OpenMeteoResponse: Codable {
    struct Current: Codable {
        var time: String
        var temperature_2m: Double
        var relative_humidity_2m: Int
        var weather_code: Int
        var wind_speed_10m: Double
    }
    struct Hourly: Codable {
        var time: [String]
        var temperature_2m: [Double]
        var weather_code: [Int]
    }
    var timezone: String
    var current: Current
    var hourly: Hourly
}

private enum WeatherServiceError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return L10n.weatherParseFailedMessage(UserPreferences.shared.language)
        }
    }
}
