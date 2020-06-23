/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of the cross-platform Metal rendering view controller.
*/

#import "AAPLRenderViewController.h"
#import "AAPLEditViewController.h"
#include "AAPLRenderer.h"

#if defined(TARGET_IOS)
#include "AAPLSplitViewController.h"
#endif

@implementation AAPLRenderViewController
{
    MTKView *_view;
    
    AAPLRenderer *_renderer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _view = (MTKView *)self.view;

#if defined(TARGET_IOS)
    _view.device = MTLCreateSystemDefaultDevice();
    
    NSAssert(_view.device, @"Metal is not supported on this device");
    
    if (@available(iOS 14.0, *))
    {
        NSAssert(_view.device.supportsDynamicLibraries,
                 @"Dynamic libraries are not supported on this device."
                 @"Must use a device with an A13 or newer");
    }
    else
    {
        NSLog(@"Dynamic libraries are only supported on iOS 14 and higher");
        return;
    }
#else
    _view.device = [self selectMetalDevice];
    NSAssert(_view.device, @"Metal is not supported on this device");
#endif
    _view.framebufferOnly = NO;
    _renderer = [[AAPLRenderer alloc] initWithMetalKitView:_view];
    
    NSAssert(_renderer, @"Renderer failed initialization");

#if defined(TARGET_IOS)
    CGFloat contentScaleFactor = _view.contentScaleFactor;
    [_renderer mtkView:_view drawableSizeWillChange:
     CGSizeMake(_view.bounds.size.width * contentScaleFactor,
                _view.bounds.size.height * contentScaleFactor)];
#else
    CGFloat backingScaleFactor = [[NSScreen mainScreen] backingScaleFactor];
    [_renderer mtkView:_view drawableSizeWillChange:
     CGSizeMake(_view.bounds.size.width * backingScaleFactor,
                _view.bounds.size.height * backingScaleFactor)];
#endif
    
    _view.delegate = _renderer;
}

#if defined(TARGET_IOS)
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Find the split view controller
    UIViewController *parentViewController = [self parentViewController];
    while(parentViewController != nil &&
          ![parentViewController isKindOfClass:[AAPLSplitViewController class]])
    {
        parentViewController = [parentViewController parentViewController];
    }
    NSAssert(parentViewController, @"Could not establish expected parent view controller");
    AAPLSplitViewController *splitViewController = (AAPLSplitViewController *)parentViewController;
    
    // Find the edit view controller
    NSArray<__kindof UIViewController *> *viewControllers = [splitViewController viewControllers];
    AAPLEditViewController *editViewController;
    for(UIViewController *viewController in viewControllers)
    {
        if([viewController isKindOfClass:[AAPLEditViewController class]])
        {
            editViewController = (AAPLEditViewController *)viewController;
            break;
        }
    }
    if(editViewController != nil)
    {
        editViewController.renderer = _renderer;
    }
}
#else
- (void)viewWillAppear
{
    [super viewWillAppear];
    
    AAPLEditViewController *editViewController = (AAPLEditViewController *)[[[((NSSplitViewController *)[self parentViewController])
                                  splitViewItems]
                                 firstObject]
                                viewController];
    if(editViewController != nil)
    {
        editViewController.renderer = _renderer;
    }
}

- (id<MTLDevice>)selectMetalDevice
{
    NSArray<id<MTLDevice>> *devices = MTLCopyAllDevices();
    // Search for high-powered devices that support dynamic libraries
    for(id<MTLDevice> device in devices)
    {
        if(!device.isLowPower &&
           device.supportsDynamicLibraries)
        {
            return device;
        }
    }
    // Search for any device that supports dynamic libraries
    for(id<MTLDevice> device in devices)
    {
        if(device.supportsDynamicLibraries)
        {
            return device;
        }
    }
    
    return nil;
}
#endif

@end
