/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A bundle of widgets for the Fruta app.
*/

import WidgetKit
import SwiftUI

@main
struct FrutaWidgets: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        FeaturedSmoothieWidget()
        RewardsCardWidget()
    }
}
