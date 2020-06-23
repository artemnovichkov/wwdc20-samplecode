/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This file implements a simplified interface to the Apple Music API, as well as managing authorization with StoreKit
*/
import os.log
import Foundation
import StoreKit

class AppleMusicAPIController {
    // Replace the placeholder below with your token, generated in Step 4 of the sample code configuration
    static let developerToken = """
        <Your Generated Developer Token Goes Here>
        """

    static let authorizationHeader = "Bearer \(developerToken)"
    static let baseURL = "https://api.music.apple.com"
    static let userTokenDefaultsKeyName = "userToken"

    private var storefront: String?
    private var userToken: String?
    private let dateDecoder = DateDecoder()

    private enum SearchType: String {
        case album = "albums"
        case artist = "artists"
        case song = "songs"
        case media = "albums,artists,songs"
    }

	// For simplicity in this sample application, user defaults is used for user token storage. If your application
	// uses StoreKit and stores a user token, then Keychain storage is a more appropriate storage location.
	// See the Apple Music Catalog sample code for more information.
    private func sharedDefaults() -> UserDefaults? {
        return UserDefaults(suiteName: "com.example.apple-samplecode.ControlAudio.Shared")
    }

    private func retrieveSavedUserToken() -> String? {
        return sharedDefaults()?.string(forKey: AppleMusicAPIController.userTokenDefaultsKeyName)
    }

    private func saveUserToken(_ userToken: String) {
        sharedDefaults()?.set(userToken, forKey: AppleMusicAPIController.userTokenDefaultsKeyName)
    }

    func prepareForRequests(_ completion: @escaping (Bool) -> Void) {
        let continueAfterAuthorization: () -> Void = {
            self.fetchUserToken { fetchedUserToken in
                guard let userToken = fetchedUserToken else {
                    completion(false)
                    return
                }

                self.userToken = userToken
                // Save the user token to avoid having to fetch it from StoreKit again later.
                self.saveUserToken(userToken)
                self.fetchStorefront { fetchedStorefront in
                    guard let storefront = fetchedStorefront else {
                        completion(false)
                        return
                    }

                    self.storefront = storefront
                    completion(true)
                }
            }
        }

        if SKCloudServiceController.authorizationStatus() != .authorized {
            requestAuthorization { authorized in
                if !authorized {
                    completion(false)
                } else {
                    continueAfterAuthorization()
                }
            }
        } else {
            continueAfterAuthorization()
        }
    }
    
    private func requestAuthorization(_ completion: @escaping (Bool) -> Void) {
        SKCloudServiceController.requestAuthorization { authorizationStatus in
            switch authorizationStatus {
            case .authorized:
                completion(true)
            default:
                completion(false)
            }
        }
    }

    private func fetchUserToken(_ completion: @escaping (String?) -> Void) {
        if let savedToken = retrieveSavedUserToken() {
            completion(savedToken)
        } else {
            let cloudServiceController = SKCloudServiceController()

            cloudServiceController.requestUserToken(forDeveloperToken: AppleMusicAPIController.developerToken) { fetchedUserToken, error in
                guard let resolvedUserToken = fetchedUserToken else {
                    let errorString = error?.localizedDescription ?? "<unknown>"
                    os_log("Failed to fetch user token error: %{public}@", log: OSLog.default, type: .error, errorString)
                    completion(nil)
                    return
                }

                os_log("Fetched user token: %{public}@", log: OSLog.default, type: .info, resolvedUserToken)
                completion(fetchedUserToken)
            }
        }
    }

    private func fetchStorefront(_ completion: @escaping (String?) -> Void) {
        let url = composeAppleMusicAPIURL("/v1/me/storefront", parameters: nil)
        executeFetch(StorefrontResponse.self, url: url) { storefrontResponse in
            guard let storefront = storefrontResponse?.data.first?.identifier else {
                completion(nil)
                return
            }

            os_log("Fetched storefront: %{public}@", log: OSLog.default, type: .info, storefront)
            completion(storefront)
        }
    }

    private func composeAppleMusicAPIURL(_ path: String, parameters: [String: String]?) -> URL? {
        var components = URLComponents(string: AppleMusicAPIController.baseURL)!
        components.path = path

        if let resolvedParameters = parameters, !resolvedParameters.isEmpty {
            components.queryItems = resolvedParameters.map { name, value in URLQueryItem(name: name, value: value) }
        }

        return components.url
    }

    private func executeFetch<T: Decodable>(_ type: T.Type, url: URL?, completion: @escaping (T?) -> Void) {
        guard let resolvedURL = url, let resolvedUserToken = userToken else {
            completion(nil)
            return
        }

        var request = URLRequest(url: resolvedURL)
        request.addValue(AppleMusicAPIController.authorizationHeader, forHTTPHeaderField: "Authorization")
        request.addValue(resolvedUserToken, forHTTPHeaderField: "Music-User-Token")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let urlResponse = response as? HTTPURLResponse, urlResponse.statusCode == 200, let resolvedData = data else {
                let errorString = error?.localizedDescription ?? "<unknown>"
                os_log("Failed to fetch data error: %{public}@", log: OSLog.default, type: .error, errorString)
                completion(nil)
                return
            }

            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.custom { dateDecoder -> Date in
                let string = try dateDecoder.singleValueContainer().decode(String.self)
                guard let date = self.dateDecoder.decode(string) else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(codingPath: dateDecoder.codingPath,
                                              debugDescription: "Expected date string to be ISO8601 or yyyy-MM-dd formatted."))
                }

                return date
            }
            let decodedResult = try? jsonDecoder.decode(T.self, from: resolvedData)
            completion(decodedResult)
        }.resume()
    }

    private func performSearchOfType(_ type: SearchType, term: String, completion: @escaping (SearchResponse?) -> Void) {
        guard let resolvedStorefront = storefront else {
            completion(nil)
            return
        }

        let path = "/v1/catalog/\(resolvedStorefront)/search"
        let url = composeAppleMusicAPIURL(path, parameters: ["types": type.rawValue, "term": term])
        executeFetch(SearchResponse.self, url: url, completion: completion)
    }
    
    private func resolveArtistPlaylistOrAlbumFromSearchResults(_ searchResults: SearchResults, completion: @escaping ([Any]?) -> Void) {
        guard let artistPath = searchResults.artists?.data.first?.href else {
            completion(nil)
            return
        }

        let url = self.composeAppleMusicAPIURL(artistPath, parameters: ["include": "albums,playlists"])
        self.executeFetch(ArtistResponse.self, url: url, completion: { artistResponse in
            guard let completeArtistRelationships = artistResponse?.data.first?.relationships else {
                completion(nil)
                return
            }

            completion(completeArtistRelationships.playlists?.data ?? completeArtistRelationships.albums?.data)
        })
    }
    
    func searchForArtist(_ artistName: String?, completion: @escaping ([Any]?) -> Void) {
        guard let searchTerm = artistName else {
            completion(nil)
            return
        }

        performSearchOfType(.artist, term: searchTerm) { searchResponse in
            guard let searchResults = searchResponse?.results else {
                completion(nil)
                return
            }

            self.resolveArtistPlaylistOrAlbumFromSearchResults(searchResults, completion: completion)
        }
    }
    
    func searchForSong(_ songName: String?, albumName: String?, artistName: String?, completion: @escaping ([Song]?) -> Void) {
        guard var searchTerm = songName else {
            completion(nil)
            return
        }

        if let resolvedAlbumName = albumName {
            searchTerm += " \(resolvedAlbumName)"
        }

        if let resolvedArtistName = artistName {
            searchTerm += " \(resolvedArtistName)"
        }

        performSearchOfType(.song, term: searchTerm) { searchResponse in
			completion(searchResponse?.results.songs?.data)
        }
    }
    
    func searchForAlbum(_ albumName: String?, artistName: String?, completion: @escaping ([Album]?) -> Void) {
        guard var searchTerm = albumName else {
            completion(nil)
            return
        }

        if let artistName = artistName {
            searchTerm += " \(artistName)"
        }

        performSearchOfType(.album, term: searchTerm) { searchResponse in
			completion(searchResponse?.results.albums?.data)
        }
    }
    
    func searchForMedia(_ mediaName: String?, completion: @escaping ([Any]?) -> Void) {
        guard let searchTerm = mediaName else {
            completion(nil)
            return
        }

        performSearchOfType(.media, term: searchTerm) { searchResponse in
            guard let searchResults = searchResponse?.results else {
                completion(nil)
                return
            }

            // In this sample application, with no specified media type, prefer artists, then albums, then songs.
            self.resolveArtistPlaylistOrAlbumFromSearchResults(searchResults, completion: { playlistsOrAlbums in
                completion(playlistsOrAlbums ?? searchResults.albums?.data ?? searchResults.songs?.data)
            })
        }
    }
    
    func fetchSongByIdentifier(_ identifier: String?, completion: @escaping (Song?) -> Void) {
        guard let resolvedIdentifier = identifier, let resolvedStorefront = storefront, !resolvedIdentifier.isEmpty else {
            completion(nil)
            return
        }

        let path = "/v1/catalog/\(resolvedStorefront)/songs/\(resolvedIdentifier)"
        let url = composeAppleMusicAPIURL(path, parameters: nil)
        executeFetch(SongResponse.self, url: url) { songResponse in
            completion(songResponse?.data.first)
        }
    }
}

private class DateDecoder {
    let iso8601Decoder: ISO8601DateFormatter
    let yyyyMMddDecoder: DateFormatter
    let yyyyMMDecoder: DateFormatter

    init() {
        iso8601Decoder = ISO8601DateFormatter()
        iso8601Decoder.formatOptions = .withInternetDateTime
        yyyyMMddDecoder = DateFormatter()
        yyyyMMddDecoder.dateFormat = "yyyy-MM-dd"
        yyyyMMDecoder = DateFormatter()
        yyyyMMDecoder.dateFormat = "yyyy-MM"
    }

    func decode(_ value: String) -> Date? {
        // In the Apple Music API, some dates are iso8601, some are YYYY-MM-DD and some are YYYY-MM, try to get a usable date out.
        return iso8601Decoder.date(from: value) ?? yyyyMMddDecoder.date(from: value) ?? yyyyMMDecoder.date(from: value)
    }
}
