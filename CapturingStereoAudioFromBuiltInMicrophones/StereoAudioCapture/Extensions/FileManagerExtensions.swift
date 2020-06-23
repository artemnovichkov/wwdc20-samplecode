/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Swift extensions to simplify file handling in the sample app.
*/

import Foundation

extension FileManager {

    var documentsDirectory: URL {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to find user's documents directory")
        }
        return url
    }

    func urlInDocumentsDirectory(named: String) -> URL {
        return documentsDirectory.appendingPathComponent(named)
    }
}
