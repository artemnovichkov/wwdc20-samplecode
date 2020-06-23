/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A file to manage the style of chart visualizations across the app.
*/

import UIKit
import CareKitUI

extension OCKCartesianChartView {
    /// Apply standard graph configuration to set axes and style in a default configuration.
    func applyDefaultConfiguration() {
        applyDefaultStyle()
        
        let numberFormatter = NumberFormatter()
        
        numberFormatter.numberStyle = .none
        
        graphView.numberFormatter = numberFormatter
        graphView.yMinimum = 0
    }
    
    func applyDefaultStyle() {
        headerView.detailLabel.textColor = .secondaryLabel
    }
    
    func applyHeaderStyle() {
        applyDefaultStyle()
        
        customStyle = ChartHeaderStyle()
    }
}

/// A styler for using the chart as a header with an `.insetGrouped` tableView.
struct ChartHeaderStyle: OCKStyler {
    var appearance: OCKAppearanceStyler {
        NoShadowAppearanceStyle()
    }
}

struct NoShadowAppearanceStyle: OCKAppearanceStyler {
    var shadowOpacity1: Float = 0
    var shadowRadius1: CGFloat = 0
    var shadowOffset1: CGSize = .zero
}
