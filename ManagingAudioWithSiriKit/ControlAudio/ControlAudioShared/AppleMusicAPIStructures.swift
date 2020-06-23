/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This file defines the structures of the Apple Music API JSON objects
*/
import Foundation

struct Storefront: Codable {
    var type: String
    var href: String?
    var identifier: String
    var attributes: StorefrontAttributes?

    enum CodingKeys: String, CodingKey {
        case type
        case href
        case identifier = "id"
        case attributes
    }
}

struct StorefrontAttributes: Codable {
    var defaultLanguageTag: String
    var name: String
    var supportedLanguageTags: [String]
}

struct StorefrontResponse: Codable {
    var data: [Storefront]
    var errors: [Error]?
    var href: String?
    var next: String?
}

struct Artist: Codable {
    var type: String
    var href: String?
    var identifier: String
    var attributes: ArtistAttributes?
    var relationships: ArtistRelationships?

    enum CodingKeys: String, CodingKey {
        case type
        case href
        case identifier = "id"
        case attributes
        case relationships
    }
}

struct ArtistAttributes: Codable {
    var editorialNotes: EditorialNotes?
    var genreNames: [String]
    var name: String
    var url: String
}

struct ArtistRelationship: Codable {
    var data: [Artist]
}

struct ArtistRelationships: Codable {
    var albums: AlbumRelationship?
    var genres: GenreRelationship?
    var playlists: PlaylistRelationship?
    var station: StationRelationship?
}

struct ArtistResponse: Codable {
    var data: [Artist]
    var errors: [Error]?
    var href: String?
    var next: String?
}

struct Album: Codable {
    var type: String
    var href: String?
    var identifier: String
    var attributes: AlbumAttributes?
    var relationships: AlbumRelationships?

    enum CodingKeys: String, CodingKey {
        case type
        case href
        case identifier = "id"
        case attributes
        case relationships
    }
}

struct AlbumAttributes: Codable {
    var artistName: String
    var artwork: Artwork?
    var contentRating: String?
    var copyright: String?
    var editorialNotes: EditorialNotes?
    var genreNames: [String]
    var isComplete: Bool
    var isSingle: Bool
    var name: String
    var playParams: PlayParameters
    var recordLabel: String
    var releaseDate: Date
    var trackCount: Int
    var url: String
    var isMasteredForItunes: Bool
}

struct AlbumRelationship: Codable {
    var data: [Album]
}

struct AlbumRelationships: Codable {
    var artists: ArtistRelationships?
    var genres: GenreRelationship?
    var tracks: TrackRelationship?
}

struct AlbumResponse: Codable {
    var data: [Album]
    var errors: [Error]?
    var href: String?
    var next: String?
}

struct TrackRelationship: Codable {
    var data: [Song]
}

struct Artwork: Codable {
    var bgColor: String?
    var height: Int
    var width: Int
    var textColor1: String?
    var textColor2: String?
    var textColor3: String?
    var textColor4: String?
    var url: String
}

struct EditorialNotes: Codable {
    var short: String?
    var standard: String
}

struct PlayParameters: Codable {
    var identifier: String
    var kind: String

    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case kind
    }
}

struct Genre: Codable {
    var type: String
    var href: String?
    var identifier: String
    var attributes: GenreAttributes?

    enum CodingKeys: String, CodingKey {
        case type
        case href
        case identifier = "id"
        case attributes
    }
}

struct GenreAttributes: Codable {
    var name: String
}

struct GenreRelationship: Codable {
    var data: [Genre]
}

struct GenreResponse: Codable {
    var data: [Genre]
    var errors: [Error]?
    var href: String?
    var next: String?
}

struct Song: Codable {
    var type: String
    var href: String?
    var identifier: String
    var attributes: SongAttributes?
    var relationships: SongRelationships?

    enum CodingKeys: String, CodingKey {
        case type
        case href
        case identifier = "id"
        case attributes
        case relationships
    }
}

struct SongAttributes: Codable {
    var albumName: String
    var artistName: String
    var artwork: Artwork
    var composerName: String?
    var contentRating: String?
    var discNumber: Int
    var durationInMillis: Int
    var editorialNotes: EditorialNotes?
    var genreNames: [String]
    var isrc: String
    var movementCount: Int?
    var movementName: String?
    var movementNumber: Int?
    var name: String
    var playParams: PlayParameters?
    var previews: [Preview]
    var releaseDate: Date
    var trackNumber: Int
    var url: String
    var workName: String?
}

struct SongRelationships: Codable {
    var albums: AlbumRelationship?
    var artists: ArtistRelationship?
    var genres: GenreRelationship?
    var station: StationRelationship?
}

struct SongResponse: Codable {
    var data: [Song]
    var errors: [Error]?
    var href: String?
    var next: String?
}

struct Station: Codable {
    var type: String
    var href: String?
    var identifier: String
    var attributes: StationAttributes?

    enum CodingKeys: String, CodingKey {
        case type
        case href
        case identifier = "id"
        case attributes
    }
}

struct StationAttributes: Codable {
    var artwork: Artwork
    var durationInMillis: Int?
    var editorialNotes: EditorialNotes?
    var episodeNumber: Int?
    var isLive: Bool
    var name: String
    var url: String
}

struct StationRelationship: Codable {
    var data: [Station]
}

struct StationResponse: Codable {
    var data: [Station]
    var errors: [Error]?
    var href: String?
    var next: String?
}

struct Preview: Codable {
    var artwork: Artwork?
    var url: String
}

struct Playlist: Codable {
    var type: String
    var href: String?
    var identifier: String
    var attributes: PlaylistAttributes?
    var relationships: PlaylistRelationships?

    enum CodingKeys: String, CodingKey {
        case type
        case href
        case identifier = "id"
        case attributes
        case relationships
    }
}

struct PlaylistAttributes: Codable {
    var artwork: Artwork?
    var curatorName: String?
    var playlistDescription: EditorialNotes?
    var lastModifiedDate: Date
    var name: String
    var playParams: PlayParameters?
    var playlistType: String
    var url: String

    enum CodingKeys: String, CodingKey {
        case artwork
        case curatorName
        case playlistDescription = "description"
        case lastModifiedDate
        case name
        case playParams
        case playlistType
        case url
    }
}

struct PlaylistRelationship: Codable {
    var data: [Playlist]
}

struct PlaylistRelationships: Codable {
    var tracks: TrackRelationship?
}

struct PlaylistResponse: Codable {
    var data: [Playlist]
    var errors: [Error]?
    var href: String?
    var next: String?
}

struct Error: Codable {
    var code: String
    var detail: String?
    var identifier: String
    var source: ErrorSource?
    var status: String
    var title: String

    enum CodingKeys: String, CodingKey {
        case code
        case detail
        case identifier = "id"
        case source
        case status
        case title
    }
}

struct ErrorSource: Codable {
    var parameter: String?
}

struct SearchResponse: Codable {
    var results: SearchResults
    var errors: [Error]?
    var href: String?
    var next: String?
}

struct SearchResults: Codable {
    var albums: AlbumResponse?
    var artists: ArtistResponse?
    var playlists: PlaylistResponse?
    var songs: SongResponse?
    var stations: StationResponse?
}
