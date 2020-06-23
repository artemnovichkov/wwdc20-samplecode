/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of the cross-platform text editing view controller.
*/

#import "AAPLEditViewController.h"

@implementation AAPLEditViewController
{
    NSString *_dylibString;
    CGFloat spaceToBottomValueStartValue;
    __weak IBOutlet NSLayoutConstraint *spaceToBottomLayoutGuide;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSError *error;
    NSString *pathToFunction = [[NSBundle mainBundle] pathForResource:@"AAPLUserCompiledFunction.metal"
                                                               ofType:nil];
    _dylibString = [NSString stringWithContentsOfFile:pathToFunction
                                             encoding:NSUTF8StringEncoding
                                                error:&error];

    NSAssert(_dylibString, @"Failed to load kernel string from file: %@", error);

#if defined(TARGET_IOS)
    _textView.text = _dylibString;
    spaceToBottomValueStartValue = spaceToBottomLayoutGuide.constant;
    [self registerForKeyboardNotifications];
#else
    [_textView setString:_dylibString];
#endif
}

/// When the "Compile" button is clicked the source for this dynamic library from the text view
/// will be compiled on the fly and inserted via insertLibraries.
#if defined(TARGET_IOS)
- (IBAction)onClick:(UIButton *)sender
{
    [_textView resignFirstResponder];
    [_renderer compileDylibWithString:_textView.text];
}

/// Handle keyboard notifications
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    spaceToBottomLayoutGuide.constant = keyboardSize.height;
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    spaceToBottomLayoutGuide.constant = spaceToBottomValueStartValue;
}

#else
- (IBAction)onClick:(NSButton *)sender
{
    [_renderer compileDylibWithString:[_textView string]];
}
#endif

@end
