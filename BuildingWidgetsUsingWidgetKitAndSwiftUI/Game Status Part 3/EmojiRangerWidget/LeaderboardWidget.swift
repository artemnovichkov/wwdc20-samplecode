/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A widget that shows a leaderboard of all available characters.
*/

import WidgetKit
import SwiftUI

struct LeaderboardProvider: TimelineProvider {
    public typealias Entry = LeaderboardEntry

    public func snapshot(with context: Context, completion: @escaping (LeaderboardEntry) -> Void) {
        let entry = LeaderboardEntry(date: Date(), characters: CharacterDetail.availableCharacters)

        completion(entry)
    }

    public func timeline(with context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        CharacterDetail.loadLeaderboardData { (characters, error) in
            guard let characters = characters else {
                let timeline = Timeline(entries: [LeaderboardEntry(date: Date(), characters: CharacterDetail.availableCharacters)], policy: .atEnd)

                completion(timeline)

                return
            }
            let timeline = Timeline(entries: [LeaderboardEntry(date: Date(), characters: characters)], policy: .atEnd)
            completion(timeline)
        }
    }
}

struct LeaderboardEntry: TimelineEntry {
    public let date: Date
    var characters: [CharacterDetail]?
}

struct LeaderboardPlaceholderView: View {
    var body: some View {
        LeaderboardWidgetEntryView(entry: LeaderboardEntry(date: Date(), characters: nil))
    }
}

struct LeaderboardWidgetEntryView: View {
    var entry: LeaderboardProvider.Entry

    var body: some View {
        ZStack {
            Color.gameBackground
        AllCharactersView(characters: entry.characters)
            .padding()
        }
    }
}

@main
struct LeaderboardWidget: Widget {
    private let kind: String = "LeaderboardWidget"

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LeaderboardProvider(), placeholder: LeaderboardPlaceholderView()) { entry in
            LeaderboardWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Ranger Leaderboard")
        .description("See all the rangers.")
        .supportedFamilies([.systemLarge])
    }
}

struct LeaderboardWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LeaderboardWidgetEntryView(entry: LeaderboardEntry(date: Date(), characters: nil))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
