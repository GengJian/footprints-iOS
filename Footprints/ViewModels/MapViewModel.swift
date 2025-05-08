import Foundation
import CoreLocation
import MapKit
import Combine

class MapViewModel: ObservableObject {
    @Published private(set) var state: MapState
    private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    
    init(locationManager: LocationManager = .shared) {
        self.locationManager = locationManager
        self.state = MapState.initial
        
        setupBindings()
    }
    
    private func setupBindings() {
        // 监听位置更新
        locationManager.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] (location: CLLocation) in
                let newLocation = Location(
                    coordinate: location.coordinate,
                    timestamp: location.timestamp
                )
                self?.handleIntent(.locationUpdated(newLocation))
            }
            .store(in: &cancellables)
    }
    
    func handleIntent(_ intent: MapIntent) {
        switch intent {
        case .dateSelected(let date):
            state.selectedDate = date
            state.locations = locationManager.getLocations(for: date)
            updateMapRegion()
            
        case .startTracking:
            state.isTracking = true
            locationManager.startUpdatingLocation()
            
        case .stopTracking:
            state.isTracking = false
            locationManager.stopUpdatingLocation()
            
        case .locationUpdated(let location):
            locationManager.saveLocation(location)
            if Calendar.current.isDate(location.timestamp, inSameDayAs: state.selectedDate) {
                state.locations = locationManager.getLocations(for: state.selectedDate)
                updateMapRegion()
            }
            
        case .errorOccurred(let error):
            state.error = error
        }
    }
    
    private func updateMapRegion() {
        guard !state.locations.isEmpty else { return }
        
        let coordinates = state.locations.map { $0.coordinate }
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let avgLatitude = latitudes.reduce(0, +) / Double(coordinates.count)
        let avgLongitude = longitudes.reduce(0, +) / Double(coordinates.count)
        
        let center = CLLocationCoordinate2D(
            latitude: avgLatitude,
            longitude: avgLongitude
        )
        
        state.region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
    }
} 
