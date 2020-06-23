/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This view controller allows you to enable and disable menu items from the active menu.
 `SoupMenuViewController` will display the active menu. When a menu item is disabled, any
 donated actions associated with the menu item are deleted from the system.
*/

import UIKit
import SoupKit

class ConfigureMenuTableViewController: UITableViewController {

    private enum SectionType {
        case visibleMenu, hiddenMenu
    }
    
    private typealias SectionModel = (sectionType: SectionType, sectionHeaderText: String, sectionFooterText: String, rowContent: [MenuItem])
    
    public var soupMenuManager: SoupMenuManager!
    
    public var soupOrderDataManager: SoupOrderDataManager! {
        didSet {
            soupMenuManager.orderManager = soupOrderDataManager
        }
    }
    
    private var sectionData: [SectionModel]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reloadData()
    }
    
    private func reloadData() {
        sectionData =  [SectionModel(sectionType: .visibleMenu,
                                     sectionHeaderText: "Visible Menu",
                                     sectionFooterText: "Uncheck a row to delete any donated shortcuts associated with the menu item.",
                                     rowContent: soupMenuManager.findItems(containing: [.regularItem], [.dailySpecialItem])),
                        SectionModel(sectionType: .hiddenMenu,
                                     sectionHeaderText: "Hidden Menu",
                                     sectionFooterText: "These menu items will only appear as relevant shortcuts on the Siri watch face.",
                                     rowContent: soupMenuManager.findItems(containing: [.secretItem]))]
        tableView.reloadData()
    }
}

extension ConfigureMenuTableViewController {
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionData.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionData[section].rowContent.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Basic Cell", for: indexPath)
        let menuItem = sectionData[indexPath.section].rowContent[indexPath.row]
        cell.textLabel?.text = menuItem.localizedName()
        cell.accessoryType = menuItem.attributes.contains(.available) ? .checkmark : .none
        return cell
    }
}

extension ConfigureMenuTableViewController {
    
    // MARK: - Table delegate
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionData[section].sectionHeaderText
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sectionData[section].sectionFooterText
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionModel = sectionData[indexPath.section]
        let currentMenuItem = sectionModel.rowContent[indexPath.row]
        var newMenuItem = currentMenuItem
        if newMenuItem.attributes.contains(.available) {
            newMenuItem.attributes.remove(.available)
        } else {
            newMenuItem.attributes.insert(.available)
        }
        
        soupMenuManager.replaceMenuItem(currentMenuItem, with: newMenuItem)
        reloadData()
    }
}
