/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A widget that displays the rewards card, showing progress towards the next free smoothie.
*/

import WidgetKit
import SwiftUI

struct RewardsCardWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RewardsCard", provider: Provider(), placeholder: RewardsCardPlaceholderView()) { entry in
            RewardsCardEntryView(entry: entry)
        }
        .configurationDisplayName("Rewards Card")
        .description("See your progress towards your next free smoothie!")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

extension RewardsCardWidget {
    struct Provider: TimelineProvider {
        func snapshot(with context: Context, completion: @escaping (Entry) -> Void) {
            completion(Entry(date: Date(), points: 4))
        }
        
        func timeline(with context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
            let entry = Entry(date: Date(), points: 4)
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
        }
    }
}

extension RewardsCardWidget {
    struct Entry: TimelineEntry {
        var date: Date
        var points: Int
    }
}

struct RewardsCardPlaceholderView: View {
    var body: some View {
        RewardsCardEntryView(entry: .init(date: Date(), points: 4))
    }
}

public struct RewardsCardEntryView: View {
    var entry: RewardsCardWidget.Entry
    
    @Environment(\.widgetFamily) private var family
    
    var compact: Bool {
        family != .systemLarge
    }
    
    public var body: some View {
        ZStack {
            BubbleBackground()
            RewardsCard(totalStamps: entry.points, hasAccount: true, compact: compact)
        }
    }
}

struct RewardsCardWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RewardsCardPlaceholderView()
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            RewardsCardEntryView(entry: .init(date: Date(), points: 8))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            RewardsCardEntryView(entry: .init(date: Date(), points: 2))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
