import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    private let locationManager = CLLocationManager()
    private let userDefaults = UserDefaults.standard
    private let locationsKey = "savedLocations"
    
    @Published var currentLocation: CLLocation?
    @Published var locations: [Location] = []
    
    override init() {
        super.init()
        setupLocationManager()
        loadLocations()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func requestLocationPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func saveLocation(_ location: Location) {
        locations.append(location)
        saveLocations()
    }
    
    func getLocations(for date: Date) -> [Location] {
        let calendar = Calendar.current
        return locations.filter { location in
            calendar.isDate(location.timestamp, inSameDayAs: date)
        }
    }
    
    private func saveLocations() {
        if let encoded = try? JSONEncoder().encode(locations) {
            userDefaults.set(encoded, forKey: locationsKey)
        }
    }
    
    private func loadLocations() {
        if let data = userDefaults.data(forKey: locationsKey),
           let decoded = try? JSONDecoder().decode([Location].self, from: data) {
            locations = decoded
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        
        let newLocation = Location(
            coordinate: location.coordinate,
            timestamp: location.timestamp
        )
        saveLocation(newLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
} 