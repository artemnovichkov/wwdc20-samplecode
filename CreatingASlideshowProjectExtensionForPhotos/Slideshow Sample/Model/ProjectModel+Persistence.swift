/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Extends the slideshow extension project model for archiving.
*/

import PhotosUI

extension ProjectModel {
    func store(in extensionContext: PHProjectExtensionContext, completion: @escaping (Bool, Error?) -> Void) {
        var data = Data()
        do {
            data = try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: true)
        } catch {
            completion(false, error)
            return
        }
        extensionContext.photoLibrary.performChanges({
            let project = extensionContext.project
            let changeRequest = PHProjectChangeRequest(project: project)
            changeRequest.projectExtensionData = data
        }, completionHandler: completion)
    }

    class func load(from extensionContext: PHProjectExtensionContext) throws -> ProjectModel? {
        let data = extensionContext.project.projectExtensionData
        if data.isEmpty {
            return nil
        }
        let project = try NSKeyedUnarchiver.unarchivedObject(ofClass: ProjectModel.self, from: data)
        return project
    }
}
