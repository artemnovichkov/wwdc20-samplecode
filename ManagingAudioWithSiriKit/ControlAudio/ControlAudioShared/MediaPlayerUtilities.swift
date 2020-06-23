/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This file implements a few utilities for interacting with MediaPlayer
*/
import Foundation
import MediaPlayer

class MediaPlayerUtilities {
    public static let LocalLibraryIdentifierPrefix = "library://"

    private class func searchForPlaylistInLocalLibrary(withPredicate predicate: MPMediaPropertyPredicate) -> MPMediaPlaylist? {
        let mediaQuery = MPMediaQuery.playlists()
        mediaQuery.addFilterPredicate(predicate)

        return mediaQuery.collections?.first as? MPMediaPlaylist
    }

    class func searchForPlaylistInLocalLibrary(byName playlistName: String) -> MPMediaPlaylist? {
        let predicate = MPMediaPropertyPredicate(value: playlistName, forProperty: MPMediaPlaylistPropertyName)
        return searchForPlaylistInLocalLibrary(withPredicate: predicate)
    }

    class func searchForPlaylistInLocalLibrary(byPersistentID persistentID: UInt64) -> MPMediaPlaylist? {
        let predicate = MPMediaPropertyPredicate(value: persistentID, forProperty: MPMediaPlaylistPropertyPersistentID)
        return searchForPlaylistInLocalLibrary(withPredicate: predicate)
    }
}
