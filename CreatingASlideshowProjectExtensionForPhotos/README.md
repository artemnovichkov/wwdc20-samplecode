# Creating a Slideshow Project Extension for Photos

Augment the macOS Photos app with extensions that support project creation.

## Overview

Starting in macOS 10.13, you can create Photos project extensions.  This sample app shows you how to implement a slideshow extension that transitions between photos by zooming in to the region of interest (ROI) that's algorithmically deemed most important.  It demonstrates the computation of saliency based on an ROI's weight and quality, and the process of subscribing to change notifications so your extension can respond to asset modifications.

## Configure the Sample Code Project

In the extension's `Info.plist` file, designate the extension type by entering `slideshow` in the field at `NSExtension` > `NSExtensionAttributes` > [`PHProjectCategory`](https://developer.apple.com/documentation/photokit/phprojectcategory).  You can add more categories to the information property list if you want your extension to appear in more categories in the Create menu.

Build and run the Photos Project Slideshow scheme in Xcode once to run the sample app, which installs the extension in the macOS Photos app. To use the extension, build and run the Slideshow Sample scheme in Xcode, which prompts you to open the macOS Photos app to use the extension. 

From within the Photos app, access the Create categories by choosing File > Create or right-clicking any group of assets.  Under the Slideshow category, you'll see the app extension and can create a project to run in it.

Because the project extension runs inside the Photos.app, the sample emulates the grid layout of the user’s photo assets. Pressing the play button in the upper-right corner of the extension starts the slideshow.

## Customize the Focus Rectangle of the Zoom Transition

The sample code project contains custom `Animator` and `AssetModel` classes.

The `Animator` class handles transitions between photos in the slideshow.  This sample's `Animator` asks an `AssetModel` object for a rectangle to zoom in to.  Photos identifies each human face it finds as a possible ROI, and the sample uses the bounding box of the most salient one as the preferred zoom rectangle. The code defines saliency of a [`PHProjectRegionOfInterest`](https://developer.apple.com/documentation/photokit/phprojectregionofinterest) as the sum of its [`weight`](https://developer.apple.com/documentation/photokit/phprojectregionofinterest/2909126-weight) and [`quality`](https://developer.apple.com/documentation/photokit/phprojectregionofinterest/2977341-quality) values, then sorts the array of the photo’s regions by that value.

``` swift
let sortedRois = assetProjectElement.regionsOfInterest.sorted { (roi1, roi2) -> Bool in
    return roi1.weight + roi1.quality < roi2.weight + roi2.quality
}
return sortedRois.last?.rect
```
[View in Source](x-source-tag://CustomizeZoomRect)

The `weight` of an ROI represents the pervasiveness of the face in the project as a whole.  The `quality` score represents the quality of the ROI in the individual asset, based on factors such as sharpness, visibility, and prominence in the photo.  Adding these two values is a heuristic for determining the face's relative importance throughout a photo project.  Objects that aren't faces don't qualify as ROI.

## Respond to Asset Changes in the Project

Your app extension should monitor change notifications and respond to asset changes in the Photos library, like photos being added or removed.

Register for change observation as soon as the project begins or resumes.  In the [`PHProjectExtensionController`](https://developer.apple.com/documentation/photokit/phprojectextensioncontroller) protocol, the [`beginProject`](https://developer.apple.com/documentation/photokit/phprojectextensioncontroller/2909215-beginproject) and [`resumeProject`](https://developer.apple.com/documentation/photokit/phprojectextensioncontroller/2909226-resumeproject) methods provide points for your extension to begin monitoring changes.

``` swift
self.projectAssets = PHAsset.fetchAssets(in: extensionContext.project, options: nil)
extensionContext.photoLibrary.register(self)
```
[View in Source](x-source-tag://RegisterChangeObservation)

When the project is complete, use the [`finishProject`](https://developer.apple.com/documentation/photokit/phprojectextensioncontroller/2909223-finishproject) protocol method to unregister from change observation.

``` swift
library.unregisterChangeObserver(self)
```
[View in Source](x-source-tag://UnregisterChangeObservation)

Whenever something changes in the Photos library, the  [photoLibraryDidChange](https://developer.apple.com/documentation/photokit/phphotolibrarychangeobserver/1620746-photolibrarydidchange) method is called.
When implementing this method, ask the [PHChange](https://developer.apple.com/documentation/photokit/phchange) instance for details about changes to the object you're interested in.
When assets are added or removed, the sample project calls [updatedProjectInfo(from:completion:)](https://developer.apple.com/documentation/photokit/phprojectextensioncontext/2977326-updatedprojectinfo) to get an updated [PHProjectInfo](https://developer.apple.com/documentation/photokit/phprojectinfo) instance, which you can use to refresh your UI.

``` swift
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
```
[View in Source](x-source-tag://UpdateProjectInfo)

## Support Copy and Paste

If your extension handles the paste action, implement the [`validateMenuItem`](https://developer.apple.com/documentation/objectivec/nsobject/1518160-validatemenuitem) delegate method to handle pasteboard contents.
```
func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    var canHandlePaste = false
    if menuItem.action == #selector(paste(_:)) {
        canHandlePaste = canHandleCurrentPasteboardContent()
    }
    return canHandlePaste
}
```
