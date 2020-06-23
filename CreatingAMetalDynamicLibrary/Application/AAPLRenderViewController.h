/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for the cross-platform Metal rendering view controller.
*/

#if defined(TARGET_IOS)
@import UIKit;
#define PlatformViewController UIViewController
#else
@import AppKit;
#define PlatformViewController NSViewController
#endif

@import MetalKit;

@interface AAPLRenderViewController : PlatformViewController

@end
