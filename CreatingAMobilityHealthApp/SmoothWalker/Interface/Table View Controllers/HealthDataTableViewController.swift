/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A table view controller with manual health data entry and the ability to switch health data types.
*/

import UIKit
import HealthKit

protocol HealthDataTableViewControllerDelegate: class {
    func didAddNewData(with value: Double)
}

/// A view controller that allows switching between health data types as a data source and manually adding new quantity or category samples.
class HealthDataTableViewController: DataTableViewController {
    
    // MARK: - View Life Cycle Overrides
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationItem()
    }
    
    override func setUpNavigationController() {
        super.setUpNavigationController()
        
        // The data type selection ("More") bar button item.
        let leftBarButtonItem = UIBarButtonItem(title: "More", style: .plain, target: self,
                                                action: #selector(didTapLeftBarButtonItem))
        navigationItem.leftBarButtonItem = leftBarButtonItem
        
        // The Add Data bar button item.
        let rightBarButtonItem = UIBarButtonItem(title: "Add Data", style: .plain, target: self,
                                                 action: #selector(didTapRightBarButtonItem))
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
    func updateNavigationItem() {
        navigationItem.title = getDataTypeName(for: dataTypeIdentifier)
    }
    
    // MARK: - Button Selectors
    
    @objc
    private func didTapRightBarButtonItem() {
        presentManualEntryViewController()
    }
    
    @objc
    private func didTapLeftBarButtonItem() {
        presentDataTypeSelectionView()
    }
    
    // MARK: - Add Data
    
    private func presentManualEntryViewController() {
        let title = getDataTypeName(for: self.dataTypeIdentifier)
        let message = "Enter a value to add as a sample to your health data."
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = title
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        let confirmAction = UIAlertAction(title: "Add", style: .default) { [weak self, weak alertController] _ in
            guard let alertController = alertController, let textField = alertController.textFields?.first else { return }
            
            if let string = textField.text, let doubleValue = Double(string) {
                self?.didAddNewData(with: doubleValue)
            }
        }
        
        alertController.addAction(confirmAction)
        
        present(alertController, animated: true)
    }
    
    // MARK: - Other / Data Type Selection
    
    private func presentDataTypeSelectionView() {
        let title = "Select Health Data Type"
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        
        for dataType in HealthData.readDataTypes {
            let actionTitle = getDataTypeName(for: dataType.identifier)
            let action = UIAlertAction(title: actionTitle, style: .default) { [weak self] (action) in
                self?.didSelectDataTypeIdentifier(dataType.identifier)
            }
            
            alertController.addAction(action)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(cancel)
        
        present(alertController, animated: true)
    }
    
    private func didSelectDataTypeIdentifier(_ dataTypeIdentifier: String) {
        self.dataTypeIdentifier = dataTypeIdentifier
        
        HealthData.requestHealthDataAccessIfNeeded(dataTypes: [self.dataTypeIdentifier]) { [weak self] (success) in
            if success {
                DispatchQueue.main.async {
                    self?.updateNavigationItem()
                }
                
                if let healthQueryDataSourceProvider = self as? HealthQueryDataSource {
                    healthQueryDataSourceProvider.performQuery() { [weak self] in
                        DispatchQueue.main.async {
                            self?.reloadData()
                        }
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.reloadData()
                    }
                }
            }
        }
        
    }
}

extension HealthDataTableViewController: HealthDataTableViewControllerDelegate {
    
    /// Handle a value corresponding to incoming HealthKit data.
    func didAddNewData(with value: Double) {
        guard let sample = processHealthSample(with: value) else { return }

        HealthData.saveHealthData([sample]) { [weak self] (success, error) in
            if let error = error {
                print("DataTypeTableViewController didAddNewData error:", error.localizedDescription)
            }
            if success {
                print("Successfully saved a new sample!", sample)
                DispatchQueue.main.async { [weak self] in
                    self?.reloadData()
                }
            } else {
                print("Error: Could not save new sample.", sample)
            }
        }
    }
    
    private func processHealthSample(with value: Double) -> HKObject? {
        let dataTypeIdentifier = self.dataTypeIdentifier
        
        guard
            let sampleType = getSampleType(for: dataTypeIdentifier),
            let unit = preferredUnit(for: dataTypeIdentifier)
        else {
            return nil
        }
        
        let now = Date()
        let start = now
        let end = now
        
        var optionalSample: HKObject?
        if let quantityType = sampleType as? HKQuantityType {
            let quantity = HKQuantity(unit: unit, doubleValue: value)
            let quantitySample = HKQuantitySample(type: quantityType, quantity: quantity, start: start, end: end)
            optionalSample = quantitySample
        }
        if let categoryType = sampleType as? HKCategoryType {
            let categorySample = HKCategorySample(type: categoryType, value: Int(value), start: start, end: end)
            optionalSample = categorySample
        }
        return optionalSample
    }
}
