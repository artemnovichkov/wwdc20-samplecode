/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A button that unlocks all recipes.
*/

import SwiftUI
import StoreKit

struct RecipeUnlockButton: View {
    var product: Product
    var purchaseAction: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var minWidth: CGFloat {
        #if os(iOS)
        return 80
        #else
        return 60
        #endif
    }
    
    @ViewBuilder var purchaseButton: some View {
        if case let .available(price, locale) = product.availability {
            let displayPrice: String = {
                let formatter = NumberFormatter()
                formatter.locale = locale
                formatter.numberStyle = .currency
                return formatter.string(for: price)!
            }()
            Button(action: purchaseAction) {
                Text(displayPrice)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(colorScheme == .light ? Color.white : .black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(minWidth: minWidth)
                    .background(colorScheme == .light ? Color.black : .white)
                    .clipShape(Capsule())
                    .contentShape(Rectangle())
            }
            .buttonStyle(SquishableButtonStyle())
            .accessibility(label: Text("Buy recipe for \(displayPrice)"))
        }
    }
    
    var bar: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(product.title)
                    .font(.headline)
                    .bold()
                Text(product.description)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            
            Spacer()
            
            purchaseButton
        }
        .padding()
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
    
    var shape: RoundedRectangle {
        #if os(iOS)
        return RoundedRectangle(cornerRadius: 16, style: .continuous)
        #else
        return RoundedRectangle(cornerRadius: 10, style: .continuous)
        #endif
    }
    
    @ViewBuilder var body: some View {
        #if os(iOS)
        ZStack(alignment: .bottom) {
            Image("smoothie/recipes-background").resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 225)
                .accessibility(hidden: true)
            bar.background(VisualEffectBlur())
        }
        .clipShape(shape)
        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
        .padding()
        .accessibilityElement(children: .contain)
        #else
        VStack(spacing: 0) {
            Image("smoothie/recipes-background").resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 100)
                .clipped()
                .overlay(Divider().padding(.horizontal, 1), alignment: .bottom)
                .accessibility(hidden: true)
            bar.background(Rectangle().fill(BackgroundStyle()))
        }
        .clipShape(shape)
        .overlay(shape.inset(by: 0.5).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        .padding(10)
        .accessibilityElement(children: .contain)
        #endif
    }
}

// MARK: - Product
extension RecipeUnlockButton {
    struct Product {
        var title: String
        var description: String
        var availability: Availability
    }
    
    enum Availability {
        case available(price: NSDecimalNumber, locale: Locale)
        case unavailable
    }
}

extension RecipeUnlockButton.Product {
    init(for product: SKProduct) {
        title = product.localizedTitle
        description = product.localizedDescription
        availability = .available(price: product.price, locale: product.priceLocale)
    }
}

// MARK: - Previews
struct RecipeUnlockButton_Previews: PreviewProvider {
    static let availableProduct = RecipeUnlockButton.Product(
        title: "Unlock All Recipes",
        description: "Make smoothies at home!",
        availability: .available(price: 4.99, locale: .current)
    )
    
    static let unavailableProduct = RecipeUnlockButton.Product(
        title: "Unlock All Recipes",
        description: "Loading...",
        availability: .unavailable
    )
    
    static var previews: some View {
        Group {
            RecipeUnlockButton(product: availableProduct, purchaseAction: {})
            RecipeUnlockButton(product: unavailableProduct, purchaseAction: {})
        }
        .frame(width: 300)
        .previewLayout(.sizeThatFits)
    }
}
