/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of split view controller for iOS.
*/

#import "AAPLSplitViewController.h"

@interface AAPLSplitViewController ()

@end

@implementation AAPLSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.preferredDisplayMode = UISplitViewControllerDisplayModeOneBesideSecondary;
}

@end
