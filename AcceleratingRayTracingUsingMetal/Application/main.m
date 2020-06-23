/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main app entry point.
*/

#import <TargetConditionals.h>

#if !TARGET_OS_IPHONE
#import <Cocoa/Cocoa.h>
#else
#import <UIKit/UIKit.h>
#endif

#import "AppDelegate.h"

#if !TARGET_OS_IPHONE

int main(int argc, const char * argv[]) {
    return NSApplicationMain(argc, argv);
}

#else

int main(int argc, char * argv[]) {

    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}

#endif
