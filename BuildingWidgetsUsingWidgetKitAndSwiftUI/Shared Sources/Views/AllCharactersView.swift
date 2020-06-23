/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that shows a list of characters, sorted by their health level.
*/
import SwiftUI

struct AllCharactersView: View {
    
    let characters: [CharacterDetail]
    
    init(characters: [CharacterDetail]? = CharacterDetail.availableCharacters) {
        self.characters = characters ?? CharacterDetail.availableCharacters
    }
    
    var body: some View {
        VStack(spacing: 48) {
            ForEach(
                characters.sorted { $0.healthLevel > $1.healthLevel }, id: \.self) { character in
                Link(destination: character.url) {
                    HStack {
                        Avatar(character: character)
                        VStack(alignment: .leading) {
                            Text(character.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Level \(character.level)")
                                .foregroundColor(.white)
                            HealthLevelShape(level: character.healthLevel)
                                .frame(height: 10)
                        }
                    }
                }
            }
        }
    }
}

struct AllCharactersView_Previews: PreviewProvider {
    static var previews: some View {
        AllCharactersView()
    }
}
