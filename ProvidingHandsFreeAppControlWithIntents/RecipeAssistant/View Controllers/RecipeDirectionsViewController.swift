/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that displays the directions for a recipe.
*/

import UIKit
import Intents
import IntentsUI

class RecipeDirectionsViewController: UITableViewController, NextStepProviding {
    
    var recipe: Recipe!
    var currentStep = 1
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isToolbarHidden = false
        self.toolbarItems = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(customView: {
                let button = INUIAddVoiceShortcutButton(style: .automaticOutline)
                button.shortcut = INShortcut(intent: {
                    let intent = ShowDirectionsIntent()
                    intent.suggestedInvocationPhrase = "Next Step"
                    return intent
                }())
                button.delegate = self
                return button
            }()),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        ]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppIntentHandler.shared.currentIntentHandler = intentHandler
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
    
    // MARK: - Actions
    
    @IBAction func nextStepBarButtonItemPressed(sender: UIBarButtonItem) {
        nextStep(recipe: recipe)
    }
    
    // MARK: - NextStepProviding
    
    lazy var intentHandler = IntentHandler(nextStepProvider: self, currentRecipe: recipe)
    
    @discardableResult
    func nextStep(recipe: Recipe) -> ShowDirectionsIntentResponse {
        guard let directions = recipe.directions else {
            return ShowDirectionsIntentResponse(code: .failure, userActivity: nil)
        }
        currentStep = currentStep >= directions.count ? 1 : currentStep + 1
        self.navigationItem.rightBarButtonItem?.title = (currentStep >= directions.count ? "Start Over" : "Next Step")
        tableView.reloadSections([0], with: .automatic)
        return ShowDirectionsIntentResponse.showDirections(step: NSNumber(value: currentStep),
                                                           directions: directions[currentStep - 1])
    }
    
}

extension RecipeDirectionsViewController {
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecipeDirectionsCell.identifier, for: indexPath)
        if let cell = cell as? RecipeDirectionsCell {
            cell.stepLabel.text = "\(currentStep)"
            cell.directionsLabel.text = recipe.directions?[currentStep - 1]
        }
        return cell
    }
}

extension RecipeDirectionsViewController {
    
    // MARK: - Table delegate
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let directions = recipe.directions else {
            return nil
        }
        return "Step \(currentStep) of \(directions.count)"
    }

}

extension RecipeDirectionsViewController: INUIAddVoiceShortcutButtonDelegate {
    
    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        addVoiceShortcutViewController.delegate = self
        present(addVoiceShortcutViewController, animated: true, completion: nil)
    }
    
    func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        editVoiceShortcutViewController.delegate = self
        present(editVoiceShortcutViewController, animated: true, completion: nil)
    }
    
}

extension RecipeDirectionsViewController: INUIAddVoiceShortcutViewControllerDelegate {
    
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController,
                                        didFinishWith voiceShortcut: INVoiceShortcut?,
                                        error: Error?) {
        if let error = error as NSError? {
            print("Error: \(error)")
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension RecipeDirectionsViewController: INUIEditVoiceShortcutViewControllerDelegate {
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didUpdate voiceShortcut: INVoiceShortcut?,
                                         error: Error?) {
        if let error = error as NSError? {
            print("Error: \(error)")
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

class RecipeDirectionsCell: UITableViewCell {
    
    static let identifier = "RecipeDirectionsCell"
    @IBOutlet weak var stepLabel: UILabel!
    @IBOutlet weak var directionsLabel: UILabel!
    
}
