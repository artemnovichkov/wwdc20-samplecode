/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Animates newly aquired points as stamps on a card representing progress towards the next free smoothie.
*/

import SwiftUI

struct RewardsCard: View {
    var totalStamps: Int
    var animatedStamps = 0
    var hasAccount: Bool
    var compact = false
    
    var spacing: CGFloat {
        compact ? 10 : 20
    }
    
    var columns: [GridItem] {
        [GridItem](repeating: GridItem(.flexible(minimum: 20), spacing: 10), count: 5)
    }
    
    var body: some View {
        VStack {
            VStack(spacing: 0) {
                Text("Rewards Card")
                    .font(compact ? Font.subheadline.bold() : Font.title2.bold())
                    .padding(.top, spacing)
                
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(1...10, id: \.self) { index in
                        let status: StampSlot.Status = {
                            guard index <= totalStamps else {
                                return .unstamped
                            }
                            let firstAnimatedIndex = totalStamps - animatedStamps
                            if index >= firstAnimatedIndex {
                                return .stampedAnimated(delayIndex: index - firstAnimatedIndex)
                            } else {
                                return .stamped
                            }
                        }()
                        StampSlot(status: status, compact: compact)
                    }
                }
                .frame(maxWidth: compact ? 250 : 300)
                .opacity(hasAccount ? 1 : 0.5)
                .padding(spacing)
            }
            .background(Rectangle().fill(BackgroundStyle()))
            .clipShape(RoundedRectangle(cornerRadius: spacing, style: .continuous))
            .accessibility(label: Text("\(totalStamps) of 10 points earned"))
            
            if !compact {
                Group {
                    if hasAccount {
                        Text(totalStamps < 10 ? "You are \(10 - totalStamps) points away from a free smoothie!"
                                : "Congratulations, you got yourself a free smoothie!")
                    } else {
                        Text("Sign up to get rewards!")
                    }
                }
                .font(Font.system(.headline, design: .rounded).bold())
                .multilineTextAlignment(.center)
                .foregroundColor(Color("rewards-foreground"))
                .padding([.horizontal], 20)
            }
        }
        .padding(20)
    }
}

extension RewardsCard {
    
    struct StampSlot: View {
        enum Status {
            case unstamped
            case stampedAnimated(delayIndex: Int)
            case stamped
        }
        
        var status: Status
        var compact = false
        
        @State private var stamped = false
        
        var body: some View {
            ZStack {
                Circle().fill(Color("bubbles-background").opacity(0.5))
                
                switch status {
                case .stamped, .stampedAnimated:
                    Image(systemName: "seal.fill")
                        .font(.system(size: compact ? 24 : 30))
                        .scaleEffect(stamped ? 1 : 2)
                        .opacity(stamped ? 1 : 0)
                        .foregroundColor(Color("rewards-foreground"))
                default:
                    EmptyView()
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .onAppear {
                switch status {
                case .stamped:
                    stamped = true
                case .stampedAnimated(let delayIndex):
                    let delay = Double(delayIndex + 1) * 0.15
                    #if !os(macOS)
                    withAnimation(Animation.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                        stamped = true
                    }
                    #else
                    stamped = true
                    #endif
                default:
                    stamped = false
                }
            }
        }
    }
}

struct RewardsCard_Previews: PreviewProvider {
    static var previews: some View {
        RewardsCard(totalStamps: 8, animatedStamps: 4, hasAccount: true)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
