/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that helps display information from a fetch request based on dynamic view state.
*/

import CoreData
import SwiftUI

struct DynamicFetchRequestView<Data, Content>: View where Data: NSFetchRequestResult, Content: View {
    var request: FetchRequest<Data>

    var content: (FetchedResults<Data>) -> Content

    var body: some View {
        content(request.wrappedValue)
    }
}
