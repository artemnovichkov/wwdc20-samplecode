/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An intent handler for `ShowDirectionsIntent` that returns recipes and the next set of directions inside a recipe.
*/

import UIKit
import Intents

class IntentHandler: NSObject, ShowDirectionsIntentHandling {
    
    var currentRecipe: Recipe?
    weak var nextStepProvider: NextStepProviding?
    
    init(nextStepProvider: NextStepProviding? = nil, currentRecipe: Recipe? = nil) {
        self.nextStepProvider = nextStepProvider
        self.currentRecipe = currentRecipe
    }
    
    // MARK: - ShowDirectionsIntentHandling
    
    func provideRecipeOptionsCollection(for intent: ShowDirectionsIntent, with completion: @escaping (INObjectCollection<Recipe>?, Error?) -> Void) {
        completion(INObjectCollection(items: Recipe.allCases), nil)
    }
    
    func resolveRecipe(for intent: ShowDirectionsIntent, with completion: @escaping (RecipeResolutionResult) -> Void) {
        guard let recipe = recipe(for: intent) else {
            completion(RecipeResolutionResult.disambiguation(with: Recipe.allCases))
            return
        }
        completion(RecipeResolutionResult.success(with: recipe))
    }
    
    func handle(intent: ShowDirectionsIntent, completion: @escaping (ShowDirectionsIntentResponse) -> Void) {
        guard let recipe = recipe(for: intent),
              let nextStepProvider = self.nextStepProvider,
              UIApplication.shared.applicationState != .background else {
            // If the app is in the background, responding with `.continueInApp` will
            // launch the app into the foreground.
            //
            // If there are no scenes connected to the app,
            // the `scene(_:willConnectTo:options:)` will be invoked on the scene delegate.
            //
            // If there are scenes connected to the app,
            // the `scene(_:continue:)` method will be invoked on the scene delegate.
            completion(ShowDirectionsIntentResponse(code: .continueInApp, userActivity: nil))
            return
        }
        completion(nextStepProvider.nextStep(recipe: recipe))
    }
    
    private func recipe(for intent: ShowDirectionsIntent) -> Recipe? {
        return currentRecipe != nil ? currentRecipe : intent.recipe
    }
    
}

/// All of the view controllers in this app use this protocol to respond to voice commands when they're frontmost.
protocol NextStepProviding: NSObject {
    
    /// The intent handler object will be used to process resolve, confirm, and handle phases.
    var intentHandler: IntentHandler { get }
    
    /// When the intent handler is ready to advance to the next step, the `nextStep` method will be called.
    @discardableResult
    func nextStep(recipe: Recipe) -> ShowDirectionsIntentResponse
    
}
