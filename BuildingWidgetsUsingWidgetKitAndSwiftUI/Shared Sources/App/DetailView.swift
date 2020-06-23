/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that shows the details of a character.
*/
import SwiftUI

struct DetailView: View {
    
    let character: CharacterDetail

    var body: some View {
        ZStack {
            Color.appBackground.edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    AvatarView(character)
                        .frame(width: 170, height: 170, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.gameBackground))
                    Text("""
                        Once the timer ends \(character.name) will be back to
                        full health and the next wave of enemies will attack.
                        Place the Game Status Widget on your Home screen to
                        be prepared.
                        """)
                        .font(.callout)
                        .padding()
                        .multilineTextAlignment(.leading)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.gameBackground))
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("About \(character.name)")
                        .font(.title)
                    Text("\(character.bio)")
                        .font(.title2)
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.gameBackground))

            }
            .padding()
            .foregroundColor(.white)
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(character: .panda)
    }
}
