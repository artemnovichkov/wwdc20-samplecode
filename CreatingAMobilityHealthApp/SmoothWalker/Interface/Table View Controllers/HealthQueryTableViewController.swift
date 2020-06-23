/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A table view controller that displays health data with a chart header view with refresh capabilities.
*/

import UIKit
import HealthKit
import CareKitUI

class HealthQueryTableViewController: ChartTableViewController, HealthQueryDataSource {
        
    var queryPredicate: NSPredicate? = nil
    var queryAnchor: HKQueryAnchor? = nil
    var queryLimit: Int = HKObjectQueryNoLimit
    
    // MARK: - View Life Cycle Overrides
    
    override func setUpViewController() {
        super.setUpViewController()
        
        setUpFetchButton()
        setUpRefreshControl()
    }
    
    private func setUpRefreshControl() {
        let refreshControl = UIRefreshControl()
        
        refreshControl.addTarget(self, action: #selector(refreshControlValueChanged), for: .valueChanged)
        
        self.refreshControl = refreshControl
    }
    
    private func setUpFetchButton() {
        let barButtonItem = UIBarButtonItem(title: "Fetch", style: .plain, target: self, action: #selector(didTapFetchButton))
        
        navigationItem.rightBarButtonItem = barButtonItem
    }
    
    // MARK: - Selectors
    
    @objc
    func didTapFetchButton() {
        fetchNetworkData()
    }
    
    @objc
    private func refreshControlValueChanged() {
        loadData()
    }
    
    // MARK: - Network
    
    func fetchNetworkData() {
        Network.pull() { [weak self] (serverResponse) in
            self?.handleServerResponse(serverResponse)
        }
    }
    
    /// Process a response sent from a remote server.
    func handleServerResponse(_ serverResponse: ServerResponse) {
        loadData()
    }
    
    // MARK: - HealthQueryDataSource
    
    /// Perform a query and reload the data upon completion.
    func loadData() {
        performQuery {
            DispatchQueue.main.async { [weak self] in
                self?.reloadData()
            }
        }
    }
    
    func performQuery(completion: @escaping () -> Void) {
        guard let sampleType = getSampleType(for: dataTypeIdentifier) else { return }
        
        let anchoredObjectQuery = HKAnchoredObjectQuery(type: sampleType,
                                                        predicate: queryPredicate,
                                                        anchor: queryAnchor,
                                                        limit: queryLimit) {
            (query, samplesOrNil, deletedObjectsOrNil, anchor, errorOrNil) in
            
            guard let samples = samplesOrNil else { return }
            
            self.dataValues = samples.map { (sample) -> HealthDataTypeValue in
                var dataValue = HealthDataTypeValue(startDate: sample.startDate,
                                                    endDate: sample.endDate,
                                                    value: .zero)
                if let quantitySample = sample as? HKQuantitySample,
                   let unit = preferredUnit(for: quantitySample) {
                    dataValue.value = quantitySample.quantity.doubleValue(for: unit)
                }
                
                return dataValue
            }
            
            completion()
        }
        
        HealthData.healthStore.execute(anchoredObjectQuery)
    }
        
    /// Override `reloadData` to update `chartView` before reloading `tableView` data.
    override func reloadData() {
        DispatchQueue.main.async {
            self.chartView.applyDefaultConfiguration()
            
            let dateLastUpdated = Date()
            self.chartView.headerView.detailLabel.text = createChartDateLastUpdatedLabel(dateLastUpdated)
            self.chartView.headerView.titleLabel.text = getDataTypeName(for: self.dataTypeIdentifier)
            
            self.dataValues.sort { $0.startDate < $1.startDate }
            
            let sampleStartDates = self.dataValues.map { $0.startDate }
            
            self.chartView.graphView.horizontalAxisMarkers = createHorizontalAxisMarkers(for: sampleStartDates)
            
            let dataSeries = self.dataValues.compactMap { CGFloat($0.value) }
            guard
                let unit = preferredUnit(for: self.dataTypeIdentifier),
                let unitTitle = getUnitDescription(for: unit)
            else {
                return
            }
            
            self.chartView.graphView.dataSeries = [
                OCKDataSeries(values: dataSeries, title: unitTitle)
            ]
            
            self.view.layoutIfNeeded()
            
            super.reloadData()
        }
    }
}
