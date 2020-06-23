/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An extension for the Quake entity.
*/

import CoreData

// MARK: - Core Data

/**
 Managed object subclass extension for the Quake entity.
 */
extension Quake {
    /**
     Updates a Quake instance with a quake dictionary if all provided keys have values.
     */
    func update(with quakeDictionary: [String: Any]) throws {
        guard let newCode = quakeDictionary["code"] as? String,
            let newMagnitude = quakeDictionary["magnitude"] as? Float,
            let newPlace = quakeDictionary["place"] as? String,
            let newTime = quakeDictionary["time"] as? Date else {
                throw QuakeError.missingData
        }
        code = newCode
        magnitude = NSNumber(value: newMagnitude)
        place = newPlace
        time = newTime
    }
}

// MARK: - Codable

/**
 A struct for decoding JSON with the following structure:

 "{
     "features":[{
        "properties":{
             "mag":1.9,
             "place":"21km ENE of Honaunau-Napoopoo, Hawaii",
             "time":1539187727610,"updated":1539187924350,
             "code":"70643082"
        }
     }]
 }"
 
 Stores an array of decoded QuakeProperties for later use in
 creating or updating Quake instances.
*/
struct GeoJSON: Decodable {
    private enum RootCodingKeys: String, CodingKey {
        case features
    }
    private enum FeatureCodingKeys: String, CodingKey {
        case properties
    }
    
    // Pretend that the data source is an array of dictionaries.
    // The keys must have the same name as the attributes of the Quake entity.
    private(set) var quakePropertiesList = [[String: Any]]()

    init(from decoder: Decoder) throws {
        let rootContainer = try decoder.container(keyedBy: RootCodingKeys.self)
        var featuresContainer = try rootContainer.nestedUnkeyedContainer(forKey: .features)
        
        while featuresContainer.isAtEnd == false {
            let propertiesContainer = try featuresContainer.nestedContainer(keyedBy: FeatureCodingKeys.self)
            
            // Decodes a single quake from the data, and appends it to the array.
            let properties = try propertiesContainer.decode(QuakeProperties.self, forKey: .properties)
            
            // Ignore invalid earthquake data.
            if !properties.isValid() {
                print("Ignored: " + "code = \(properties.code ?? ""), mag = \(properties.mag ?? 0) " +
                    "place = \(properties.place ?? ""), time = \(properties.time ?? 0)")
                continue
            }
            quakePropertiesList.append(properties.dictionary)
        }
    }
}

/**
 A struct encapsulating the properties of a Quake. All members are
 optional in case they are missing from the data.
 */
struct QuakeProperties: Decodable {
    let mag: Float?         // 1.9
    let place: String?      // "21km ENE of Honaunau-Napoopoo, Hawaii"
    let time: Double?       // 1539187727610
    let code: String?       // "70643082"
    
    func isValid() -> Bool {
        return (mag != nil && place != nil && code != nil && time != nil) ? true :  false
    }
    
    // The keys must have the same name as the attributes of the Quake entity.
    var dictionary: [String: Any] {
        return ["magnitude": mag ?? 0,
                "place": place ?? "",
                "time": Date(timeIntervalSince1970: TimeInterval(time ?? 0) / 1000),
                "code": code ?? ""]
    }
}
