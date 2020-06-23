/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for the renderer class that performs Metal setup and per-frame rendering.
*/

#ifndef AAPLRenderer_h
#define AAPLRenderer_h

@import MetalKit;

// Platform independent renderer class
@interface AAPLRenderer : NSObject<MTKViewDelegate>

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;
- (void)compileDylibWithString:(NSString *_Nonnull)programString;

@end

#endif /* AAPLRenderer_h */
