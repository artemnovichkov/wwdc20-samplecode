/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that shows a character's name.
*/
import SwiftUI
import WidgetKit

struct CharacterNameView: View {
    let character: CharacterDetail

    init(_ character: CharacterDetail?) {
        self.character = character ?? CharacterDetail.panda
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(character.name)
                .font(.title)
                .fontWeight(.bold)
                .minimumScaleFactor(0.25)
            Text("Level \(character.level)")
                .minimumScaleFactor(0.5)
            Text("\(character.exp) XP")
                .minimumScaleFactor(0.5)
        }
    }
}

struct CharacterNameView_Previews: PreviewProvider {
    static var previews: some View {
        CharacterNameView(CharacterDetail.panda)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
