/*
See LICENSE folder for this sample’s licensing information.

Abstract:
iBeacon implementation for setting up at WWDC game room tables.
*/

import Foundation
import CoreLocation
import os.log

private let regionUUID = UUID(uuidString: "53FA6CD3-DFE4-493C-8795-56E71D2DAEAF")!
private let regionId = "GameRoom"

struct GameTableLocation: Equatable, Hashable {
    typealias ProximityLocationId = Int
    let identifier: ProximityLocationId
    let name: String

    private init(identifier: Int) {
        self.identifier = identifier
        self.name = "Table \(self.identifier)"
    }
    
    private static var locations: [ProximityLocationId: GameTableLocation] = [:]
    static func location(with identifier: ProximityLocationId) -> GameTableLocation {
        if let location = locations[identifier] {
            return location
        }
        
        let location = GameTableLocation(identifier: identifier)
        locations[identifier] = location
        return location
    }
    
    static func == (lhs: GameTableLocation, rhs: GameTableLocation) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    func hash(into hasher: inout Hasher) {
        identifier.hash(into: &hasher)
    }
}

extension CLProximity: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .immediate:
            return "immediate"
        case .near:
            return "near"
        case .far:
            return "far"
        default:
            fatalError("Encountered an unexpected CL proximity.")
        }
    }
}

protocol ProximityManagerDelegate: class {
    func proximityManager(_ manager: ProximityManager, didChange location: GameTableLocation?)
    func proximityManager(_ manager: ProximityManager, didChange authorization: Bool)
}

class ProximityManager: NSObject {
    static var shared = ProximityManager()

    let locationManager = CLLocationManager()
    let region = CLBeaconRegion(proximityUUID: regionUUID, identifier: regionId)
    var isAvailable: Bool {
        return CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self)
    }
    var isAuthorized: Bool {
        return CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways
    }
    
    var closestLocation: GameTableLocation?
    weak var delegate: ProximityManagerDelegate?
    
    override private init() {
        super.init()
        self.locationManager.delegate = self
        requestAuthorization()
    }

    func requestAuthorization() {
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func start() {
        guard isAvailable else { return }
        os_log(.debug, "Starting beacon ranging")
        locationManager.startRangingBeacons(in: region)
    }
    
    func stop() {
        guard isAvailable else { return }
        os_log(.debug, "Stopping beacon ranging")
        os_log(.debug, "Closest location is: %d", closestLocation?.identifier ?? 0)
        locationManager.stopRangingBeacons(in: region)
    }
}

extension ProximityManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        // we want to filter out beacons that have unknown proximity
        let knownBeacons = beacons.filter { $0.proximity != CLProximity.unknown }
        for beacon in knownBeacons {
            let proximity = beacon.proximity.description
            os_log(.debug, "Beacon %@ proximity: %s", beacon.minor, proximity)
        }
        if let beacon = knownBeacons.first {
            os_log(.debug, "First Beacon is %@", beacon.minor)
            var location: GameTableLocation? = nil
            if beacon.proximity == .near || beacon.proximity == .immediate {
                location = GameTableLocation.location(with: beacon.minor.intValue)
            }
            
            if closestLocation != location {
                os_log(.debug, "Closest location changed to: %d", location?.identifier ?? 0)
                closestLocation = location
                delegate?.proximityManager(self, didChange: location)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        os_log(.error, "Ranging beacons failed for region %s: (%s)", region.identifier, error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let statusString: String
        switch status {
        case .authorizedAlways:
            statusString = "always"
        case .authorizedWhenInUse:
            statusString = "when in use"
        case .denied:
            statusString = "denied"
        case .notDetermined:
            statusString = "not determined"
        case .restricted:
            statusString = "restricted"
        default:
            fatalError("Encountered an unexpected auth status.")
        }
        os_log(.debug, "Changed location authorization status: %s", statusString)

        if let delegate = delegate {
            delegate.proximityManager(self, didChange: self.isAuthorized)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        os_log(.error, "Location manager did fail with error %s", error.localizedDescription)
    }
}
