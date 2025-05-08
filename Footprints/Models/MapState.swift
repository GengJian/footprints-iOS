import Foundation
import CoreLocation
import MapKit

struct MapState {
    var selectedDate: Date
    var locations: [Location]
    var isTracking: Bool
    var region: MKCoordinateRegion?
    var error: String?
    
    static var initial: MapState {
        MapState(
            selectedDate: Date(),
            locations: [],
            isTracking: false,
            region: nil,
            error: nil
        )
    }
} 