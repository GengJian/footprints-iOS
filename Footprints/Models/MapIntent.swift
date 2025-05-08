import Foundation

enum MapIntent {
    case dateSelected(Date)
    case startTracking
    case stopTracking
    case locationUpdated(Location)
    case errorOccurred(String)
} 