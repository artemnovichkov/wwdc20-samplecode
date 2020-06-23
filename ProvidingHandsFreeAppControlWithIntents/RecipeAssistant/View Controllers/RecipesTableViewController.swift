/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that displays the contents of the `RecipeBook`.
*/

import UIKit
import Intents

class RecipesTableViewController: UITableViewController, NextStepProviding {
    
    // MARK: - View lifecycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppIntentHandler.shared.currentIntentHandler = intentHandler
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "Recipe Details" else {
            return
        }
        
        var recipe = sender as? Recipe

        if sender is UITableViewCell,
            let selectedIndexPaths = tableView.indexPathsForSelectedRows,
            let selectedIndexPath = selectedIndexPaths.first {
            recipe = Recipe.allCases[selectedIndexPath.row]
        }
        
        if let destination = segue.destination as? RecipeDetailViewController, let recipe = recipe {
            destination.recipe = recipe
        }
    }
    
    // MARK: - NextStepProviding
    
    lazy var intentHandler = IntentHandler(nextStepProvider: self)
    
    func nextStep(recipe: Recipe) -> ShowDirectionsIntentResponse {
        performSegue(withIdentifier: "Recipe Details", sender: recipe)
        return ShowDirectionsIntentResponse.showIngredients(recipe: recipe)
    }
}

extension RecipesTableViewController {
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Recipe.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeDetailCell", for: indexPath)
        let recipe = Recipe.allCases[indexPath.row]
        if let iconImageName = recipe.iconImageName {
            cell.imageView?.image = UIImage(named: iconImageName)
        }
        cell.imageView?.layer.cornerRadius = 8
        cell.imageView?.clipsToBounds = true
        cell.textLabel?.text = recipe.displayString
        cell.detailTextLabel?.text = nil
        return cell
    }
}
