/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Network utility functions to simulate pushing and pulling data, as well as process a mock server response.
*/

import Foundation
import HealthKit

class Network {
    
    // MARK: - Sending Data
    
    class func push(addedSamples: [HKObject]? = nil, deletedSamples: [HKDeletedObject]? = nil) {
        if let samples = addedSamples, !samples.isEmpty {
            pushAddedSamples(samples)
        }
        
        if let deletedSamples = deletedSamples, !deletedSamples.isEmpty {
            pushDeletedSamples(deletedSamples)
        }
    }
    
    class func pushAddedSamples(_ objects: [HKObject]) {
        var statusDictionary: [String: Int] = [:]
        for object in objects {
            guard let sample = object as? HKSample else {
                print("We don't support pushing non-sample objects at this time!")
                
                return
            }
            
            let identifier = sample.sampleType.identifier
            
            if let value = statusDictionary[identifier] {
                statusDictionary[identifier] = value + 1
            } else {
                statusDictionary[identifier] = 1
            }
        }
        
        print("Pushing \(objects.count) new samples to server!")
        print("Samples:", statusDictionary)
    }
    
    class func pushDeletedSamples(_ samples: [HKDeletedObject]) {
        print("Pushing \(samples.count) deleted samples to server!")
        print("Samples:", samples)
    }
    
    // MARK: - Receiving Data
    
    class func pull(completion: @escaping (ServerResponse) -> Void) {
        print("Pulling data from the server!")
        
        // Load a mock server response from disk to simulate pulling new data.
        print("Loading mock server response.")
        let response = loadMockServerResponse()
        
        completion(response)
    }
    
    // MARK: - Helper Functions
    
    /// Process ``ServerHealthSample` into a HealthKit object.
    class func createHealthSample(_ sample: ServerHealthSample) throws -> HKObject {
        let identifier = sample.typeIdentifier
        let value = sample.value
        let start = sample.startDate
        let end = sample.endDate
        
        var metadata = [String: Any]()
        metadata[HKMetadataKeySyncIdentifier] = sample.syncIdentifier
        metadata[HKMetadataKeySyncVersion] = sample.syncVersion
        
        var healthSample: HKObject
        switch sample.type {
        case .category:
            guard let type = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: identifier)) else {
                throw NetworkError.invalidObjectTypeIdentifier(invalidIdentifier: identifier)
            }
            
            healthSample = HKCategorySample(type: type, value: Int(value), start: start, end: end, metadata: metadata)
        case .quantity:
            guard let type = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: identifier)) else {
                throw NetworkError.invalidObjectTypeIdentifier(invalidIdentifier: identifier)
            }
            guard let unit = NetworkSupport.processUnitString(sample.unit) else {
                throw NetworkError.invalidSampleUnit(invalidUnit: sample.unit)
            }
            
            let quantity = HKQuantity(unit: unit, doubleValue: value)
            
            healthSample = HKQuantitySample(type: type, quantity: quantity, start: start, end: end, metadata: metadata)
        }
        
        return healthSample
    }
    
    private class func loadMockServerResponse() -> ServerResponse {
        let pathName = "MockServerResponse"
        
        guard
            let file = Bundle.main.url(forResource: pathName, withExtension: "json"),
            let data = try? Data(contentsOf: file)
        else {
            fatalError("Could not load file \(pathName).json!")
        }
        
        do {
            let decoder = JSONDecoder()
            
            decoder.dateDecodingStrategy = .iso8601
            
            let serverResponse = try decoder.decode(ServerResponse.self, from: data)
            
            return serverResponse
        } catch {
            fatalError("Could not decode ServerResponse!")
        }
    }
}

enum NetworkError: Error {
    case invalidObjectType
    case invalidObjectTypeIdentifier(invalidIdentifier: String)
    case invalidSampleUnit(invalidUnit: String)
}

class NetworkSupport {
    /// Process server response for HKUnit kind.
    class func processUnitString(_ unit: String) -> HKUnit? {
        switch unit {
        case "count":
            return .count()
        case "largeCalorie":
            return .largeCalorie()
        case "inch":
            return .inch()
        case "centimeter":
            return .meterUnit(with: .centi)
        case "meter":
            return .meterUnit(with: .none)
        case "kilometer":
            return .meterUnit(with: .kilo)
        case "pound":
            return .pound()
        default:
            return nil
        }
    }
}
