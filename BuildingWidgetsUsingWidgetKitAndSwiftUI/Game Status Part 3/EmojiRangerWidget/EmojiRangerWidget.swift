/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A widget that shows the avatar for a single character.
*/

import WidgetKit
import SwiftUI

struct Provider: IntentTimelineProvider {
    typealias Intent = CharacterSelectionIntent
    
    public typealias Entry = SimpleEntry
    
    func character(for configuration: CharacterSelectionIntent) -> CharacterDetail {
        switch configuration.hero {
        case .panda:
            return .panda
        case .egghead:
            return .egghead
        case .spouty:
            return .spouty
        default:
            return .panda
        }
    }

    public func snapshot(for configuration: CharacterSelectionIntent, with context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date(), relevance: nil, character: .panda)

        completion(entry)
    }

    public func timeline(for configuration: CharacterSelectionIntent, with context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let selectedCharacter = character(for: configuration)
        let endDate = selectedCharacter.fullHealthDate
        let oneMinute: TimeInterval = 60
        var currentDate = Date()
        var entries: [SimpleEntry] = []

        while currentDate < endDate {
            let relevance = TimelineEntryRelevance(score: Float(selectedCharacter.healthLevel))
            let entry = SimpleEntry(date: currentDate, relevance: relevance, character: selectedCharacter)
            
            currentDate += oneMinute
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)

        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    public let date: Date
    let relevance: TimelineEntryRelevance?
    let character: CharacterDetail
}

struct PlaceholderView: View {
    var body: some View {
        EmojiRangerWidgetEntryView(entry: SimpleEntry(date: Date(), relevance: nil, character: .panda))
    }
}

struct EmojiRangerWidgetEntryView: View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family

    @ViewBuilder
    var body: some View {
        switch family {
        case .systemSmall:
            ZStack {
                AvatarView(entry.character)
                    .widgetURL(entry.character.url)
                    .foregroundColor(.white)
            }
            .background(Color.gameBackground)
        default:
            ZStack {
                HStack(alignment: .top) {
                    AvatarView(entry.character)
                        .foregroundColor(.white)
                    Text(entry.character.bio)
                        .padding()
                        .foregroundColor(.white)
                }
                .padding()
                .widgetURL(entry.character.url)
            }
            .background(Color.gameBackground)
        }
    }
}

struct EmojiRangerWidget: Widget {
    private let kind: String = "EmojiRangerWidget"

    public var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: CharacterSelectionIntent.self, provider: Provider(), placeholder: PlaceholderView()) { entry in
            EmojiRangerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Ranger Detail")
        .description("See your favorite ranger.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct Widget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            
            EmojiRangerWidgetEntryView(entry: SimpleEntry(date: Date(), relevance: nil, character: .panda))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
