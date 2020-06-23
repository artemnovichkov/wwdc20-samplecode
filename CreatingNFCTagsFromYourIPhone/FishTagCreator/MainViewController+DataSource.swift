/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Extension to handle view data source.
*/

import UIKit

extension MainViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    // Here are functions to support the picker view data source.
    // fishKinds stores the list of strings to displays in the picker view.
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return fishKinds.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return fishKinds[row]
    }
}
