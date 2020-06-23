/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that displays stylized section titles.
*/

import SwiftUI

struct SectionHeaderView<Label>: View where Label: View {
    var label: () -> Label

    var body: some View {
        label()
            .textCase(.lowercase)
            .foregroundColor(Color(.label))
            .font(.system(size: 55, weight: .bold, design: .rounded))
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
