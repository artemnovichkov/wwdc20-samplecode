/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Parser to import ARGeoAnchors from GPX files.
*/

import ARKit

protocol GPXParserDelegate: class {
    func parser(_ parser: GPXParser, didFinishParsingFileWithAnchors anchors: [ARGeoAnchor])
}

class GPXParser: NSObject, XMLParserDelegate {
    
    weak var delegate: GPXParserDelegate?
    
    // The XML parser used to parse the GPX file.
    private var parser: XMLParser?
    
    // The data of the currently parsed geo anchor.
    private var parsedGeoAnchorData = [String: String]()
    
    // The textual content of the currently parsed element.
    private var currentElementText = ""
    
    private var anchorsFoundInFile: [ARGeoAnchor] = []
    
    init?(contentsOf url: URL) {
        guard let parser = XMLParser(contentsOf: url) else {
            return nil
        }
        super.init()
        parser.delegate = self
        self.parser = parser
    }
    
    func parse() {
        parser?.parse()
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        // Each waypoint element contains all data describing a new geo anchor,
        // so intialize a new dictionary to collect all of the anchor's data.
        if elementName.lowercased() == "wpt" {
            parsedGeoAnchorData = attributeDict
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        let tag = elementName.lowercased()
        switch tag {
        case "wpt":
            // If the waypoint contained all required content, initialize the anchor from the collected data.
            if let lat = Double(parsedGeoAnchorData["lat"] ?? ""),
               let lon = Double(parsedGeoAnchorData["lon"] ?? ""),
               let name = parsedGeoAnchorData["name"] ?? "" {
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let altitude = Double(parsedGeoAnchorData["ele"] ?? "")
                let geoAnchor = ARGeoAnchor(name: name, coordinate: coordinate, altitude: altitude)
                anchorsFoundInFile.append(geoAnchor)
            }
        default:
            // For elements other than waypoints, save their content in the dictionary.
            parsedGeoAnchorData[tag] = currentElementText.trimmingCharacters(in: .whitespacesAndNewlines)
            currentElementText = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentElementText += string
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        delegate?.parser(self, didFinishParsingFileWithAnchors: anchorsFoundInFile)
    }
}
