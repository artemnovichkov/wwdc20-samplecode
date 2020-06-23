/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A reusable view that can display a list of arbritary smoothies.
*/

import SwiftUI

struct SmoothieList: View {
    var smoothies: [Smoothie]
    
    @State private var selection: Smoothie?
    @EnvironmentObject private var model: FrutaModel
    
    var content: some View {
        List(selection: $selection) {
            ForEach(smoothies) { smoothie in
                NavigationLink(
                    destination: SmoothieView(smoothie: smoothie).environmentObject(model),
                    tag: smoothie,
                    selection: $selection
                ) {
                    SmoothieRow(smoothie: smoothie)
                }
                .tag(smoothie)
                .onReceive(model.$selectedSmoothieID) { newValue in
                    guard let smoothieID = newValue, let smoothie = Smoothie(for: smoothieID) else { return }
                    selection = smoothie
                }
            }
        }
    }
    
    @ViewBuilder var body: some View {
        #if os(iOS)
        content
        #else
        content
            .frame(minWidth: 270, idealWidth: 300, maxWidth: 400, maxHeight: .infinity)
            .toolbar { Spacer() }
        #endif
    }
}

struct SmoothieList_Previews: PreviewProvider {
    static var previews: some View {
        ForEach([ColorScheme.light, .dark], id: \.self) { scheme in
            NavigationView {
                SmoothieList(smoothies: Smoothie.all)
                    .navigationTitle("Smoothies")
                    .environmentObject(FrutaModel())
            }
            .preferredColorScheme(scheme)
        }
    }
}
