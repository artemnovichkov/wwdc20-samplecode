/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that displays quantity sample statistics for the week.
*/

import UIKit
import HealthKit

class WeeklyQuantitySampleTableViewController: HealthDataTableViewController, HealthQueryDataSource {
    
    let calendar: Calendar = .current
    let healthStore = HealthData.healthStore
    
    var quantityTypeIdentifier: HKQuantityTypeIdentifier {
        return HKQuantityTypeIdentifier(rawValue: dataTypeIdentifier)
    }
    
    var quantityType: HKQuantityType {
        return HKQuantityType.quantityType(forIdentifier: quantityTypeIdentifier)!
    }
    
    var query: HKStatisticsCollectionQuery?
    
    // MARK: - View Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if query != nil { return }
        
        // Request authorization.
        let dataTypeValues = Set([quantityType])
        
        print("Requesting HealthKit authorization...")
        
        self.healthStore.requestAuthorization(toShare: dataTypeValues, read: dataTypeValues) { (success, error) in
            if success {
                self.calculateDailyQuantitySamplesForPastWeek()
            }
        }
    }
    
    func calculateDailyQuantitySamplesForPastWeek() {
        performQuery {
            DispatchQueue.main.async { [weak self] in
                self?.reloadData()
            }
        }
    }
    
    // MARK: - HealthQueryDataSource
    
    func performQuery(completion: @escaping () -> Void) {
        let predicate = createLastWeekPredicate()
        let anchorDate = createAnchorDate()
        let dailyInterval = DateComponents(day: 1)
        let statisticsOptions = getStatisticsOptions(for: dataTypeIdentifier)

        let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                                 quantitySamplePredicate: predicate,
                                                 options: statisticsOptions,
                                                 anchorDate: anchorDate,
                                                 intervalComponents: dailyInterval)
        
        // The handler block for the HKStatisticsCollection object.
        let updateInterfaceWithStatistics: (HKStatisticsCollection) -> Void = { statisticsCollection in
            self.dataValues = []
            
            let now = Date()
            let startDate = getLastWeekStartDate()
            let endDate = now
            
            statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { [weak self] (statistics, stop) in
                var dataValue = HealthDataTypeValue(startDate: statistics.startDate,
                                                    endDate: statistics.endDate,
                                                    value: 0)
                
                if let quantity = getStatisticsQuantity(for: statistics, with: statisticsOptions),
                   let identifier = self?.dataTypeIdentifier,
                   let unit = preferredUnit(for: identifier) {
                    dataValue.value = quantity.doubleValue(for: unit)
                }
                
                self?.dataValues.append(dataValue)
            }
            
            completion()
        }
        
        query.initialResultsHandler = { query, statisticsCollection, error in
            if let statisticsCollection = statisticsCollection {
                updateInterfaceWithStatistics(statisticsCollection)
            }
        }
        
        query.statisticsUpdateHandler = { [weak self] query, statistics, statisticsCollection, error in
            // Ensure we only update the interface if the visible data type is updated
            if let statisticsCollection = statisticsCollection, query.objectType?.identifier == self?.dataTypeIdentifier {
                updateInterfaceWithStatistics(statisticsCollection)
            }
        }
        
        self.healthStore.execute(query)
        self.query = query
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let query = query {
            self.healthStore.stop(query)
        }
    }
}

