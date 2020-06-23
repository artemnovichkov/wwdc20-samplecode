/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view where users can add drinks or view the current amount of caffeine they have drunk.
*/

import SwiftUI

// The Coffee Tracker app's main view.
struct CoffeeTrackerView: View {
    
    @EnvironmentObject var coffeeData: CoffeeData
    @State var showDrinkList = false
    
    // Layout the view's body.
    var body: some View {
        VStack {
            
            // Display the current amount of caffeine in the user's body.
            Text(coffeeData.currentMGCaffeineString + " mg")
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(colorForCaffeineDose())
            Text("Current Caffeine Dose")
                .font(.footnote)
            Divider()
            
            // Displays how much the user has drunk today,
            // using the equivalent number of 8 oz. cups of coffee.
            Text(coffeeData.totalCupsTodayString + " cups")
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(colorForDailyDrinkCount())
            Text("Equivalent Drinks Today")
                .font(.footnote)
            Spacer()
            
            // Display a button that lets the user record new drinks.
            Button(action: { self.showDrinkList.toggle() }) {
                Image("add-coffee")
            }
        }
        .sheet(isPresented: $showDrinkList) {
            DrinkListView().environmentObject(self.coffeeData)
        }
    }
    
    // MARK: - Private Methods
    // Calculate the color based on the amount of caffeine currently in the user's body.
    private func colorForCaffeineDose() -> Color {
        // Get the current amount of caffeine in the system.
        let currentDose = coffeeData.currentMGCaffeine
        return Color(coffeeData.color(forCaffeineDose: currentDose))
    }
    
    // Calculate the color based on the number of drinks consumed today.
    private func colorForDailyDrinkCount() -> Color {
        // Get the number of cups drank today
        let cups = coffeeData.totalCupsToday
        return Color(coffeeData.color(forTotalCups: cups))
    }
}

// Configure a preview of the coffee tracker view.
struct CoffeeTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        CoffeeTrackerView()
            .environmentObject(CoffeeData.shared)
    }
}
