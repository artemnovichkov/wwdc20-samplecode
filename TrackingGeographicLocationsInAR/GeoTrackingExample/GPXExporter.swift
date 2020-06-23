/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Exporter to serialize ARGeoAnchors to GPX files.
*/

import ARKit

class GPXExporter {
    
    static let shared = GPXExporter()
    
    private let gpxPrefix = """
    <?xml version="1.0" encoding="UTF-8" standalone="no" ?>
    <gpx xmlns="http://www.topografix.com/GPX/1/1" creator="Apple Inc.">

    """
    private let waypointTemplate = """
      <wpt lat="LAT_PLACEHOLDER" lon="LON_PLACEHOLDER">
        <ele>ELE_PLACEHOLDER</ele>
        <name>NAME_PLACEHOLDER</name>
      </wpt>

    """
    private let gpxPostfix = "</gpx>"
        
    func exportGeoAnchors(_ geoAnchors: [ARGeoAnchor], toFileWithURL url: URL) throws {
        // Create GPX string
        var geoAnchorString = gpxPrefix
        for anchor in geoAnchors {
            geoAnchorString.append(gpxWaypoint(from: anchor))
        }
        geoAnchorString.append(gpxPostfix)
        
        // Save GPX file to disk
        try geoAnchorString.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func gpxWaypoint(from geoAnchor: ARGeoAnchor) -> String {
        let waypoint = waypointTemplate
        .replacingOccurrences(of: "LAT_PLACEHOLDER", with: String(format: "%.8f", geoAnchor.coordinate.latitude))
        .replacingOccurrences(of: "LON_PLACEHOLDER", with: String(format: "%.8f", geoAnchor.coordinate.longitude))
        .replacingOccurrences(of: "ELE_PLACEHOLDER", with: geoAnchor.altitude != nil ? String(format: "%.8f", geoAnchor.altitude!) : "")
        .replacingOccurrences(of: "NAME_PLACEHOLDER", with: geoAnchor.name ?? "")
        return waypoint
    }
}
