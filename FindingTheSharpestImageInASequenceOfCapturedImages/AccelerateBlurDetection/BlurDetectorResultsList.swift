/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Blur Results List.
*/

import SwiftUI

struct BlurDetectorResultsList: View {
    let results: [BlurDetectionResult]

    var body: some View {
        List(self.results, id: \.index) { item in
            BlurDetectionItemRenderer(item: item)
        }
    }
}

