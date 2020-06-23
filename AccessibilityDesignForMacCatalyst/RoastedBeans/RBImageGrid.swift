/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The Image Grid.
*/
import SwiftUI

struct RBImageGrid: View {

    let title: String
    let images: [UIImage]

    var body: some View {
        ZStack {
            Rectangle()
                .cornerRadius(10)
                .foregroundColor(Color(.secondarySystemBackground))
            VStack(alignment: .leading) {
                Text(title + ":")
                    .bold()
                HStack {
                    ForEach(images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            // Ideally, we would want to provide a more descriptive label here
                            .accessibility(label: Text(NSLocalizedString("Coffee", comment: "")))
                            .padding(.all, 8)
                    }
                }
            }
            .padding(.all, 8)
            /*
             By specifying the child behaviour as contain, we make this view an
             accessibilityContainer. This also allows VoiceOver on macOS to focus
             on the container itself, and then navigate into the container where each
             of the images can be navigated to.
            */
            .accessibilityElement(children: .contain)
            .accessibility(label: Text(title))
        }
        .padding(.all, 16)
    }
}
