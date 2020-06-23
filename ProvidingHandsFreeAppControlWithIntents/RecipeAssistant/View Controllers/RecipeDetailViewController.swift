/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that displays attributes of a recipe, such as the necessary ingredients.
*/

import UIKit
import Intents

class RecipeDetailViewController: UITableViewController, NextStepProviding {
    
    var recipe: Recipe!
    
    // MARK: - Sections
    
    private enum SectionType {
        case servings, time, ingredients
    }
    
    private typealias SectionModel = (sectionType: SectionType, title: String, rowContent: [String])
    private lazy var sectionData: [SectionModel] = [
        SectionModel(sectionType: .servings, title: "Servings", rowContent: [recipe.servings ?? ""]),
        SectionModel(sectionType: .time, title: "Time", rowContent: [recipe.time ?? ""]),
        SectionModel(sectionType: .ingredients, title: "Ingredients", rowContent: recipe.ingredients ?? [])
    ]
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = recipe.displayString
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppIntentHandler.shared.currentIntentHandler = intentHandler
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Directions" {
            if let destination = segue.destination as? RecipeDirectionsViewController {
                destination.recipe = recipe
            }
        }
    }
    
    // MARK: - NextStepProviding
    
    lazy var intentHandler = IntentHandler(nextStepProvider: self, currentRecipe: recipe)
    
    func nextStep(recipe: Recipe) -> ShowDirectionsIntentResponse {
        guard let directions = recipe.directions, let firstDirection = directions.first else {
            return ShowDirectionsIntentResponse(code: .failure, userActivity: nil)
        }
        performSegue(withIdentifier: "Directions", sender: recipe)
        return ShowDirectionsIntentResponse.showDirections(step: NSNumber(value: 1), directions: firstDirection)
    }
    
}

extension RecipeDetailViewController {
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionData.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionData[section].rowContent.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath)
        cell.textLabel?.text = sectionData[indexPath.section].rowContent[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        return cell
    }
}

extension RecipeDetailViewController {
    
    // MARK: - Table delegate
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionData[section].title
    }

}
