/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Project view controller for Photos project slideshow extension.
*/

import Cocoa
import PhotosUI

@available(OSXApplicationExtension 10.13, *)
class PhotoProjectViewController: NSViewController, PHProjectExtensionController, PHPhotoLibraryChangeObserver {

    lazy var gridViewController = GridViewController()
    weak var slideshowViewController: SlideshowViewController?

    var projectModel: ProjectModel?
    var projectAssets: PHFetchResult<PHAsset>?

    var projectExtensionContext: PHProjectExtensionContext? {
        return extensionContext as? PHProjectExtensionContext
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(gridViewController)
        let subview = gridViewController.view
        subview.translatesAutoresizingMaskIntoConstraints = true
        subview.autoresizingMask = [.height, .width]
        subview.frame = view.bounds
        view.addSubview(subview)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        DispatchQueue.main.async {
            self.view.window?.makeFirstResponder(self)
        }
    }

    // MARK: - PHProjectExtensionController

    /// - Tag: RegisterChangeObservation
    func beginProject(with extensionContext: PHProjectExtensionContext, projectInfo: PHProjectInfo, completion: @escaping (Error?) -> Void) {
        DispatchQueue.main.async {
            self.setupProjectModel(with: projectInfo, extensionContext: extensionContext)
            self.projectAssets = PHAsset.fetchAssets(in: extensionContext.project, options: nil)
            extensionContext.photoLibrary.register(self)
            completion(nil)
        }
    }

    func resumeProject(with extensionContext: PHProjectExtensionContext, completion: @escaping (Error?) -> Void) {
        DispatchQueue.main.async {
            do {
                let project = try ProjectModel.load(from: extensionContext)
                self.setup(with: project, extensionContext: extensionContext)
                self.projectAssets = PHAsset.fetchAssets(in: extensionContext.project, options: nil)
                extensionContext.photoLibrary.register(self)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    /// - Tag: UnregisterChangeObservation
    func finishProject(completionHandler completion: @escaping () -> Void) {
        if let library = projectExtensionContext?.photoLibrary {
            library.unregisterChangeObserver(self)
        }
        completion()
    }

    // MARK: - PHPhotoLibraryChangeObserver

    /// - Tag: UpdateProjectInfo
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let fetchResult = projectAssets,
            let changeDetails = changeInstance.changeDetails(for: fetchResult)
            else { return }
        projectAssets = changeDetails.fetchResultAfterChanges

        guard let projectExtensionContext = projectExtensionContext else { return }
        projectExtensionContext.updatedProjectInfo(from: projectModel?.projectInfo) { (updatedProjectInfo) in
            guard let projectInfo = updatedProjectInfo else { return }
            DispatchQueue.main.async {
                self.setupProjectModel(with: projectInfo, extensionContext: projectExtensionContext)
            }
        }
    }

    // MARK: -

    func setupProjectModel(with projectInfo: PHProjectInfo, extensionContext: PHProjectExtensionContext) {
        let project = ProjectModel(projectInfo: projectInfo)
        project.store( in: extensionContext, completion: { (success, error) in
            if !success, let error = error {
                self.handle(error: error)
            }
        })
        self.setup(with: project, extensionContext: extensionContext)
    }

    func setup(with projectModel: ProjectModel?, extensionContext: PHProjectExtensionContext) {
        self.projectModel = projectModel
        if let project = projectModel {
            gridViewController.loadCollectionView(project: project, extensionContext: extensionContext)
        }
    }

    func handle(error: Error) {
        // You should add some real error handling code.
        print(error)
        DispatchQueue.main.async {
            NSAlert(error: error).runModal()
        }
    }

    @IBAction func startSlideshow(_ sender: Any?) {
        let slideshowController = SlideshowViewController()
        let animator = RoiZoomAnimator()
        slideshowController.animator = animator
        self.addChild(slideshowController)
        slideshowViewController = slideshowController
        transition(from: gridViewController, to: slideshowController, options: .crossfade) {
            slideshowController.startSlideshow(with: self.gridViewController.models)
        }
    }

    override func cancelOperation(_ sender: Any?) {
        if let slideshowController = slideshowViewController {
            transition(from: slideshowController, to: gridViewController, options: .crossfade) {
                slideshowController.removeFromParent()
                self.slideshowViewController = nil
            }
        } else {
            // Forward to let the window handle exit full screen.
            nextResponder?.tryToPerform(_: #selector(cancelOperation), with: sender)
        }
    }

}
