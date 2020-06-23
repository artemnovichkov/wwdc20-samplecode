/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for the cross-platform app delegate.
*/

#if defined(TARGET_IOS)
@import UIKit;
#define PlatformAppDelegate UIResponder <UIApplicationDelegate>
#define PlatformWindow UIWindow
#else
@import AppKit;
#define PlatformAppDelegate NSObject <NSApplicationDelegate>
#define PlatformWindow NSWindow
#endif

@interface AAPLAppDelegate : PlatformAppDelegate

@property (strong, nonatomic) PlatformWindow *window;

@end
