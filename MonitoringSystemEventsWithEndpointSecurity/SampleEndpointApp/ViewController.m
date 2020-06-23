/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's main view controller, which presents a user interface for installing the extension.
*/
#import "ViewController.h"
#import <SystemExtensions/SystemExtensions.h>

@interface ViewController ()

@property (strong) OSSystemExtensionRequest *currentRequest;
@property (weak) IBOutlet NSButton *installButton;
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@end

@implementation ViewController


- (IBAction)installExtension:(id __unused)sender {
	if (self.currentRequest) {
		NSBeep();
		return;
	}
	NSLog(@"Beginning to install the extension");

	OSSystemExtensionRequest *req = [OSSystemExtensionRequest activationRequestForExtension:@"com.example.apple-samplecode.SampleEndpointApp.Extension" queue:dispatch_get_main_queue()];
	req.delegate = (id<OSSystemExtensionRequestDelegate>)self;

	[[OSSystemExtensionManager sharedManager] submitRequest:req];
	self.currentRequest = req;
	[self logWithFormat:@"Begin installing the extension 🔄\n"];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	// Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
	[super setRepresentedObject:representedObject];

	// Update the view, if already loaded.
}

- (void)logText:(NSString *)text
// Logs the specified text to the text view.
{
	assert(text != nil);
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		[[self.textView textStorage] appendAttributedString:[[NSAttributedString alloc] initWithString:text]];
		[self.textView setTextColor:[NSColor textColor]];
		[self.textView scrollRangeToVisible:NSMakeRange([self.textView.string length], 0)];
	}];
}

- (void)logWithFormat:(NSString *)format, ...
// Logs the formatted text to the text view.
{
	va_list ap;

	assert(format != nil);

	va_start(ap, format);
	[self logText:[[NSString alloc] initWithFormat:format arguments:ap]];
	va_end(ap);
}

- (void)logError:(NSError *)error
// Logs the error to the text view.
{
	assert(error != nil);
	[self logWithFormat:@"error %@ / %d\n", [error domain], (int) [error code]];
}

- (OSSystemExtensionReplacementAction)request:(OSSystemExtensionRequest OS_UNUSED *)request actionForReplacingExtension:(OSSystemExtensionProperties *)existing withExtension:(OSSystemExtensionProperties *)extension
{
	NSLog(@"Got the upgrade request (%@ -> %@); answering replace.", existing.bundleVersion, extension.bundleVersion);
	return OSSystemExtensionReplacementActionReplace;
}

- (void)requestNeedsUserApproval:(OSSystemExtensionRequest *)request
{
	if (request != self.currentRequest) {
		NSLog(@"UNEXPECTED NON-CURRENT Request to activate %@ succeeded.", request.identifier);
		return;
	}
	NSLog(@"Request to activate %@ awaiting approval.", request.identifier);
	[self logWithFormat:@"Awaiting Approval ⏱ \n"];
}

- (void)request:(OSSystemExtensionRequest *)request didFinishWithResult:(OSSystemExtensionRequestResult)result
{
	if (request != self.currentRequest) {
		NSLog(@"UNEXPECTED NON-CURRENT Request to activate %@ succeeded.", request.identifier);
		return;
	}
	NSLog(@"Request to activate %@ succeeded (%zu).", request.identifier, (unsigned long)result);
	[self logWithFormat:@"Successfully installed the extension ✅\n"];
	self.currentRequest = nil;
}

- (void)request:(OSSystemExtensionRequest *)request didFailWithError:(NSError *)error
{
	if (request != self.currentRequest) {
		NSLog(@"UNEXPECTED NON-CURRENT Request to activate %@ failed with error %@.", request.identifier, error);
		return;
	}
	NSLog(@"Request to activate %@ failed with error %@.", request.identifier, error);
	[self logWithFormat:@"Failed to install the extension ❌\n%@", error.localizedDescription];
	self.currentRequest = nil;
}

@end
