/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A modifier that adds a border around views when the `ShowDebugBorders` launch argument is set.
*/

import SwiftUI

private struct DebugBorderViewModifier<Border>: ViewModifier where Border: ShapeStyle {
    var border: () -> Border

    var width: CGFloat

    #if DEBUG
    @ViewBuilder func body(content: Content) -> some View {
        if Configuration.showDebugBorders {
            content.border(border(), width: width)
        } else {
            content
        }
    }
    #else
    func body(content: Content) -> some View {
        content
    }
    #endif
}

extension View {
    
    /// Adds a debug border to this view in debug builds and when the ShowDebugBorders launch argument is passed.
    func debugBorder<Border>(
        _ border: @autoclosure @escaping () -> Border,
        width: CGFloat = 10
    ) -> some View where Border: ShapeStyle {
        modifier(DebugBorderViewModifier(border: border, width: width))
    }
}
