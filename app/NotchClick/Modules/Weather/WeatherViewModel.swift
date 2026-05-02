import SwiftUI
import CoreLocation
import Combine

class WeatherViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var weather: WeatherData?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var fetchTask: Task<Void, Never>?
    private var locationTimeoutWorkItem: DispatchWorkItem?
    private var fetchTimeoutWorkItem: DispatchWorkItem?
    private var lastSuccessfulFetch: Date?
    private let cacheDuration: TimeInterval = 2 * 60
    private let freshLocationCacheDuration: TimeInterval = 10 * 60
    private let fallbackLocationCacheDuration: TimeInterval = 12 * 60 * 60

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    deinit {
        fetchTask?.cancel()
        locationTimeoutWorkItem?.cancel()
        fetchTimeoutWorkItem?.cancel()
        locationManager.stopUpdatingLocation()
        geocoder.cancelGeocode()
    }

    func fetchWeather() {
        if let lastSuccessfulFetch,
           Date().timeIntervalSince(lastSuccessfulFetch) < cacheDuration,
           weather != nil {
            return
        }

        guard !isLoading else { return }

        errorMessage = nil

        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            requestCurrentLocation()
        case .notDetermined:
            isLoading = true
            startLocationTimeout()
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            isLoading = false
            errorMessage = L10n.locationAccessMessage(UserPreferences.shared.language)
        @unknown default:
            isLoading = false
            errorMessage = L10n.locationUnavailableMessage(UserPreferences.shared.language)
        }
    }

    // MARK: CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            requestCurrentLocation()
        case .denied, .restricted:
            locationTimeoutWorkItem?.cancel()
            locationManager.stopUpdatingLocation()
            isLoading = false
            errorMessage = L10n.locationAccessMessage(UserPreferences.shared.language)
        case .notDetermined:
            break
        @unknown default:
            locationTimeoutWorkItem?.cancel()
            locationManager.stopUpdatingLocation()
            isLoading = false
            errorMessage = L10n.locationUnavailableMessage(UserPreferences.shared.language)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationTimeoutWorkItem?.cancel()
        locationManager.stopUpdatingLocation()
        guard let loc = locations.last else {
            isLoading = false
            errorMessage = L10n.locationUnknownMessage(UserPreferences.shared.language)
            return
        }

        fetchWeather(for: loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationTimeoutWorkItem?.cancel()
        locationManager.stopUpdatingLocation()
        let nsError = error as NSError
        let clError = CLError.Code(rawValue: nsError.code)

        switch clError {
        case .denied:
            errorMessage = L10n.locationAccessMessage(UserPreferences.shared.language)
            isLoading = false
            return
        case .locationUnknown:
            if fetchWeatherUsingCachedLocation(maxAge: fallbackLocationCacheDuration) {
                return
            }
            showLocationUnavailable()
        default:
            if fetchWeatherUsingCachedLocation(maxAge: fallbackLocationCacheDuration) {
                return
            }
            showLocationUnavailable()
        }
    }

    private func requestCurrentLocation() {
        if fetchWeatherUsingCachedLocation(maxAge: freshLocationCacheDuration) {
            return
        }

        isLoading = true
        locationManager.stopUpdatingLocation()
        startLocationTimeout()
        locationManager.requestLocation()
    }

    private func startLocationTimeout() {
        locationTimeoutWorkItem?.cancel()

        let timeout = DispatchWorkItem { [weak self] in
            guard let self, self.isLoading else { return }
            self.locationManager.stopUpdatingLocation()
            if self.fetchWeatherUsingCachedLocation(maxAge: self.fallbackLocationCacheDuration) {
                return
            }

            self.showLocationUnavailable()
        }

        locationTimeoutWorkItem = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: timeout)
    }

    @discardableResult
    private func fetchWeatherUsingCachedLocation(maxAge: TimeInterval) -> Bool {
        guard let loc = locationManager.location,
              loc.horizontalAccuracy >= 0,
              Date().timeIntervalSince(loc.timestamp) <= maxAge else {
            return false
        }

        fetchWeather(for: loc)
        return true
    }

    private func showLocationUnavailable() {
        isLoading = false
        errorMessage = L10n.locationFetchFailedMessage(UserPreferences.shared.language)
    }

    private func fetchWeather(for location: CLLocation) {
        let coord = location.coordinate

        fetchWeatherData(
            lat: coord.latitude,
            lon: coord.longitude,
            city: "Current Location"
        )

        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self, let placemark = placemarks?.first else { return }
            let city = placemark.locality ?? placemark.subLocality ?? placemark.administrativeArea ?? placemark.name
            guard let city, !city.isEmpty else { return }
            DispatchQueue.main.async {
                if var updatedWeather = self.weather {
                    updatedWeather.cityName = city
                    self.weather = updatedWeather
                }
            }
        }
    }

    private func fetchWeatherData(lat: Double, lon: Double, city: String) {
        locationTimeoutWorkItem?.cancel()
        fetchTimeoutWorkItem?.cancel()
        isLoading = true
        errorMessage = nil

        let timeout = DispatchWorkItem { [weak self] in
            guard let self, self.isLoading else { return }
            self.fetchTask?.cancel()
            self.isLoading = false
            if self.weather == nil {
                self.errorMessage = L10n.weatherFetchFailedMessage(UserPreferences.shared.language)
            }
        }
        fetchTimeoutWorkItem = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: timeout)

        fetchTask?.cancel()
        fetchTask = Task { [weak self] in
            guard let self else { return }

            do {
                var fetched = try await WeatherService.shared.fetchWeather(latitude: lat, longitude: lon)
                guard !Task.isCancelled else { return }
                fetched.cityName = city
                let finalData = fetched
                await MainActor.run {
                    self.fetchTimeoutWorkItem?.cancel()
                    self.fetchTimeoutWorkItem = nil
                    self.weather = finalData
                    self.isLoading = false
                    self.lastSuccessfulFetch = Date()
                }
            } catch {
                guard !Task.isCancelled else { return }
                let errMsg = error.localizedDescription
                await MainActor.run {
                    self.fetchTimeoutWorkItem?.cancel()
                    self.fetchTimeoutWorkItem = nil
                    self.errorMessage = errMsg
                    self.isLoading = false
                }
            }
        }
    }
}
