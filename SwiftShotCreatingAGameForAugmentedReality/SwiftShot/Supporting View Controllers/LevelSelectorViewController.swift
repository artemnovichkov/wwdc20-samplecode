/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller for choosing levels.
*/

import UIKit

protocol LevelSelectorViewControllerDelegate: class {
    func levelSelectorViewController(_ levelSelectorViewController: LevelSelectorViewController, didSelect level: GameLevel)
}

class LevelSelectorViewController: UITableViewController {
    weak var delegate: LevelSelectorViewControllerDelegate?
    
    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return GameLevel.allLevels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let level = GameLevel.level(at: indexPath.row) else {
            fatalError("Level \(indexPath.row) not found")
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "LevelCell", for: indexPath)
        cell.textLabel?.text = level.name
        return cell
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let level = GameLevel.level(at: indexPath.row) else {
            fatalError("Level \(indexPath.row) not found")
        }
        
        UserDefaults.standard.selectedLevel = level
        
        delegate?.levelSelectorViewController(self, didSelect: level)
        
        navigationController?.popViewController(animated: true)
    }
}
