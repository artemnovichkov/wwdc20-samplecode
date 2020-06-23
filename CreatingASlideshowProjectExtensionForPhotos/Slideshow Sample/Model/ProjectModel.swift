/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implements the project model for the Photos project slideshow extension.
*/

import PhotosUI

class ProjectModel: NSObject, NSSecureCoding {
    let projectInfo: PHProjectInfo
    init(projectInfo: PHProjectInfo) {
        self.projectInfo = projectInfo
    }

    // MARK: - NSSecureCoding

    static var supportsSecureCoding: Bool {
        return true
    }

    enum CodingKeys: String, RawRepresentable {
        case projectInfo
    }

    required init?(coder decoder: NSCoder) {
        guard let projectInfo = decoder.decodeObject(of: PHProjectInfo.self, forKey: CodingKeys.projectInfo.rawValue) else {
            return nil
        }
        self.projectInfo = projectInfo
    }

    func encode(with coder: NSCoder) {
        coder.encode(projectInfo, forKey: CodingKeys.projectInfo.rawValue)
    }

}
