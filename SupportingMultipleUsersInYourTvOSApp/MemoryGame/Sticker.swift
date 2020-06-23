/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A value that represents a single game tile image.
*/

struct Sticker: Codable, Hashable {

    /// The name of the image displayed by this sticker.
    var image: String

    /// A set of all available stickers.
    static var all = Set(
        (1...10).lazy
            .map { "stickers/\($0)" }
            .map { Sticker(image: $0) }
    )
}
