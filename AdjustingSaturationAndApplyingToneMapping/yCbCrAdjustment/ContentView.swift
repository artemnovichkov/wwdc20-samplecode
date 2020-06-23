/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main UI structure.
*/

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var ycbcrAdjustment: YCbCrAdjustment
    
    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    
    static func format(_ value: Float) -> String {
        Self.formatter.string(from: value as NSNumber)!
    }
    
    func reset() {
        ycbcrAdjustment.reset()
    }
    
    let font = Font.system(.body, design: .default).monospacedDigit()
    
    var body: some View {
        HSplitView {
            Image(decorative: ycbcrAdjustment.outputImage, scale: 1)
                .resizable()
                .scaledToFit()
                .padding()
            
            GeometryReader { geometry in
                VStack {
                    HStack {
                        Slider(value: self.$ycbcrAdjustment.saturation,
                               in: 0 ... 4) {
                                Text("Saturation")
                                    .font(self.font)
                                    .frame(width: geometry.size.width / 4,
                                           alignment: .leading)
                                
                        }
                        Text("\(Self.format(self.ycbcrAdjustment.saturation))")
                            .font(self.font)
                    }
                    
                    HStack {
                        Slider(value: self.$ycbcrAdjustment.lumaGamma,
                               in: 0.5 ... 2.5) {
                                Text("Luma Gamma")
                                    .font(self.font)
                                    .frame(width: geometry.size.width / 4,
                                           alignment: .leading)
                        }
                        Text("\(Self.format(self.ycbcrAdjustment.lumaGamma))")
                            .font(self.font)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Toggle(isOn: self.$ycbcrAdjustment.useLinear) {
                            Text("sRGB → Linear")
                                .font(self.font)
                        }
                        
                        Spacer()
                        
                        Button(action: self.reset) {
                            Text("Reset")
                                .font(self.font)
                        }
                    }
                }
            }
            .padding()
            .frame(minWidth: 400)
        }
    }
}
