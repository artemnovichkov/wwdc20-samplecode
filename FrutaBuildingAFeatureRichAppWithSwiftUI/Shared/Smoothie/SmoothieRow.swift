/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A row used by SmoothieList that adjusts its layout based on environment and platform
*/

import SwiftUI
import NutritionFacts

struct SmoothieRow: View {
    var smoothie: Smoothie
    
    @EnvironmentObject private var model: FrutaModel

    var size: CGFloat {
        #if os(iOS)
        return 96
        #else
        return 60
        #endif
    }

    var cornerRadius: CGFloat {
        #if os(iOS)
        return 16
        #else
        return 8
        #endif
    }
    
    var verticalRowPadding: CGFloat {
        #if os(macOS)
        return 10
        #else
        return 0
        #endif
    }
    
    var verticalTextPadding: CGFloat {
        #if os(iOS)
        return 8
        #else
        return 0
        #endif
    }
    
    var ingredients: String {
        ListFormatter.localizedString(byJoining: smoothie.menuIngredients.map { $0.ingredient.name })
    }

    var body: some View {
        HStack(alignment: .top) {
            smoothie.image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .accessibility(hidden: true)

            VStack(alignment: .leading) {
                Text(smoothie.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(ingredients)
                    .lineLimit(2)
                    .accessibility(label: Text("Ingredients: \(ingredients)."))

                Text("\(smoothie.kilocalories) Calories")
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.vertical, verticalTextPadding)
            
            Spacer(minLength: 0)
        }
        .font(.subheadline)
        .padding(.vertical, verticalRowPadding)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

struct SmoothieRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SmoothieRow(smoothie: .lemonberry)
            SmoothieRow(smoothie: .thatsASmore)
        }
        .frame(width: 250, alignment: .leading)
        .padding(.horizontal)
        .previewLayout(.sizeThatFits)
        .environmentObject(FrutaModel())
    }
}
