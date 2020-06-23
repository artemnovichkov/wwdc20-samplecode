/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for the cross-platform text editing view controller.
*/

#if defined(TARGET_IOS)
@import UIKit;
#define PlatformViewController UIViewController
#else
@import AppKit;
#define PlatformViewController NSViewController
#endif

@import MetalKit;

#include "AAPLRenderer.h"

@interface AAPLEditViewController : PlatformViewController

#if defined(TARGET_IOS)
@property (weak, nonatomic) IBOutlet UITextView *textView;
#else
@property (unsafe_unretained) IBOutlet NSTextView *textView;
#endif

@property (atomic) AAPLRenderer *renderer;

@end
