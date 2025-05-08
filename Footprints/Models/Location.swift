import Foundation
import CoreLocation

struct Location: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let title: String?
    let subtitle: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(coordinate: CLLocationCoordinate2D, timestamp: Date, title: String? = nil, subtitle: String? = nil) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.timestamp = timestamp
        self.title = title
        self.subtitle = subtitle
    }
} 