/*
See LICENSE folder for this sample’s licensing information.

Abstract:
NutritionFacts playground.
*/

import NutritionFacts
import SwiftUI

// Raw Ingredients
let banana = NutritionFact.banana
let blueberry = NutritionFact.blueberry
let peanutButter = NutritionFact.peanutButter
let almondMilk = NutritionFact.almondMilk

// Smoothie ingredients
let ingredients = [
    banana.amount(.grams(100)),
    blueberry.amount(.cups(1)),
    peanutButter.amount(.tablespoons(3)),
    almondMilk.amount(.cups(3))
]

let combinedIngredients = ingredients.reduce(.zero, +)

combinedIngredients.energy
combinedIngredients.energy.converted(to: .kilocalories)

let caloryBreakdown = combinedIngredients.calorieBreakdown

let chart = ChartView(
    title: "Calorie Breakdown",
    labeledValues: caloryBreakdown.labeledValues
)

// MARK: - Show Interactive Chart

import PlaygroundSupport

PlaygroundPage.current.setLiveView(
    chart
        .padding()
        .frame(width: 300, height: 350)
)
