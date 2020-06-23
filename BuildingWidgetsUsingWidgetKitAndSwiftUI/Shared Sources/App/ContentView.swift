/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that displays the list of available characters.
*/
import SwiftUI

struct ContentView: View {
    
    @State var pandaActive: Bool = false
    @State var spoutyActive: Bool = false
    @State var eggheadActive: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(
                    destination: DetailView(character: .panda), isActive: $pandaActive) {
                    TableRow(character: .panda)
                }
                NavigationLink(
                    destination: DetailView(character: .spouty), isActive: $spoutyActive) {
                    TableRow(character: .spouty)
                }
                NavigationLink(
                    destination: DetailView(character: .egghead), isActive: $eggheadActive) {
                    TableRow(character: .egghead)
                }
            }
            .navigationBarTitle("Your Characters")
            .onOpenURL(perform: { (url) in
                self.pandaActive = url == CharacterDetail.panda.url
                self.spoutyActive = url == CharacterDetail.spouty.url
                self.eggheadActive = url == CharacterDetail.egghead.url
            })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct TableRow: View {
    let character: CharacterDetail
    var body: some View {
        HStack {
            Avatar(character: character)
            CharacterNameView(character)
                .padding()
        }
    }
}
