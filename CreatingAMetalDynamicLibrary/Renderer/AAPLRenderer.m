/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of the renderer class that performs Metal setup and per-frame rendering.
*/

@import simd;
@import MetalKit;

#import "AAPLRenderer.h"
#import "AAPLMathUtilities.h"

// Include header shared between C code here, which executes Metal API commands, and .metal files
#import "AAPLShaderTypes.h"

// The max number of command buffers in flight
static const NSUInteger AAPLMaxFramesInFlight = 3;


// Main class performing the rendering
@implementation AAPLRenderer
{
    dispatch_semaphore_t _inFlightSemaphore;
    id <MTLBuffer> _frameDataBuffer[AAPLMaxFramesInFlight];
    NSUInteger _frameNumber;

    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;

    id<MTLRenderPipelineState> _renderPipeline;
    id<MTLDepthStencilState> _depthState;
    id<MTLTexture> _colorMap;
    id<MTLBuffer> _positionBuffer;
    id<MTLBuffer> _texCoordBuffer;
    id<MTLBuffer> _indexBuffer;
    id<MTLTexture> _colorTarget;

    MTLRenderPassDescriptor *_renderPassDescriptor;

    MTLVertexDescriptor *_vertexDescriptor;
    // Projection matrix calculated as a function of view size
    matrix_float4x4 _projectionMatrix;
    float _rotation;

    id<MTLComputePipelineState> _computePipeline;
    MTLComputePipelineDescriptor *_baseDescriptor;
    MTLSize _dispatchExecutionSize;
    MTLSize _threadsPerThreadgroup;
    NSUInteger _threadgroupMemoryLength;
}

/// Initialize with the MetalKit view with the Metal device used to render.  This MetalKit view
/// object will also be used to set the pixelFormat and other properties of the drawable
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
{
    self = [super init];
    if(self)
    {
        _device = mtkView.device;
        _inFlightSemaphore = dispatch_semaphore_create(AAPLMaxFramesInFlight);
        [self loadMetal:mtkView];
        [self loadAssets];
    }
    
    return self;
}

/// Create the Metal render state objects including shaders and render state pipeline objects
- (void)loadMetal:(nonnull MTKView*)mtkView
{
    [self setUpView:mtkView];

    id<MTLLibrary> metalLibrary = [self loadMetallib];

    [self createBuffers];

    [self createRenderStateWithLibrary:metalLibrary];

    [self createComputePipelineWithLibrary:metalLibrary];

    _commandQueue = [_device newCommandQueue];
}

// Load the Metal library created in the "Build Executable Metal Library" build phase.
// This library includes the functions in AAPLShaders.metal and the UserDylib.metallib
// created in the "Build Dynamic Metal Library" build phase.
- (id<MTLLibrary>)loadMetallib
{
    NSError *error;

    id<MTLLibrary> library = [_device newLibraryWithURL:[[NSBundle mainBundle]
                                                                URLForResource:@"AAPLShaders"
                                                                withExtension:@"metallib"]
                                                         error:&error];

    NSAssert(library, @"Failed to load AAPLShaders dynamic metal library: %@", error);

    return library;
}

/// Set up properties of the view
- (void)setUpView:(nonnull MTKView*)mtkView
{
    mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    mtkView.sampleCount = 1;
}

/// Create buffers modified each frame to animate the cube
- (void)createBuffers
{
    for(NSUInteger i = 0; i < AAPLMaxFramesInFlight; i++)
    {
        _frameDataBuffer[i] = [_device newBufferWithLength:sizeof(AAPLPerFrameData)
                                                   options:MTLResourceStorageModeShared];

        _frameDataBuffer[i].label = @"FrameDataBuffer";
    }
}

/// Create the render pass descriptor, render pipeline state object, and depth state object to render the cube.
- (void)createRenderStateWithLibrary:(id<MTLLibrary>)metallib
{
    NSError *error;

    // Set up render pass descriptor
    {
        _renderPassDescriptor = [MTLRenderPassDescriptor new];
        _renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);
        _renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        _renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

        _renderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
        _renderPassDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
    }

    // Set up render pipeline
    {
        _vertexDescriptor = [MTLVertexDescriptor new];
    
        _vertexDescriptor.attributes[AAPLVertexAttributePosition].format = MTLVertexFormatFloat3;
        _vertexDescriptor.attributes[AAPLVertexAttributePosition].offset = 0;
        _vertexDescriptor.attributes[AAPLVertexAttributePosition].bufferIndex = AAPLBufferIndexMeshPositions;

        _vertexDescriptor.attributes[AAPLVertexAttributeTexcoord].format = MTLVertexFormatFloat2;
        _vertexDescriptor.attributes[AAPLVertexAttributeTexcoord].offset = 0;
        _vertexDescriptor.attributes[AAPLVertexAttributeTexcoord].bufferIndex = AAPLBufferIndexMeshGenerics;

        _vertexDescriptor.layouts[AAPLBufferIndexMeshPositions].stride = 16;
        _vertexDescriptor.layouts[AAPLBufferIndexMeshPositions].stepRate = 1;
        _vertexDescriptor.layouts[AAPLBufferIndexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;

        _vertexDescriptor.layouts[AAPLBufferIndexMeshGenerics].stride = 8;
        _vertexDescriptor.layouts[AAPLBufferIndexMeshGenerics].stepRate = 1;
        _vertexDescriptor.layouts[AAPLBufferIndexMeshGenerics].stepFunction = MTLVertexStepFunctionPerVertex;

        // Load the vertex function from the library
        id<MTLFunction> vertexFunction = [metallib newFunctionWithName:@"vertexShader"];

        // Load the fragment function from the library
        id<MTLFunction> fragmentFunction = [metallib newFunctionWithName:@"fragmentShader"];

        MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
        pipelineDescriptor.label = @"RenderPipeline";
        pipelineDescriptor.sampleCount = 1;
        pipelineDescriptor.vertexFunction = vertexFunction;
        pipelineDescriptor.vertexDescriptor = _vertexDescriptor;
        pipelineDescriptor.fragmentFunction = fragmentFunction;
        pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA8Unorm;
        pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;

        _renderPipeline = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];

        NSAssert(_renderPipeline, @"Failed to create render pipeline state: %@", error);
    }

    // Set up depth stencil state
    {
        MTLDepthStencilDescriptor *depthStateDesc = [MTLDepthStencilDescriptor new];
        depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
        depthStateDesc.depthWriteEnabled = YES;
        _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
    }
}

- (void)createComputePipelineWithLibrary:(id<MTLLibrary>)metallib
{
    NSError *error;

    id<MTLFunction> kernelFunction = [metallib newFunctionWithName:@"dylibKernel"];
    _baseDescriptor = [MTLComputePipelineDescriptor new];
    _baseDescriptor.computeFunction = kernelFunction;
    MTLComputePipelineDescriptor *descriptor = [MTLComputePipelineDescriptor new];
    descriptor.computeFunction = _baseDescriptor.computeFunction;
    
    _computePipeline = [_device newComputePipelineStateWithDescriptor:descriptor
                                                              options:MTLPipelineOptionNone
                                                           reflection:nil
                                                                error:&error];
    NSAssert(_computePipeline, @"Error creating pipeline which links library from source: %@", error);
}

/// Load assets into metal objects
- (void)loadAssets
{
    // Create a buffer with positions to draw the cube.
    {
        static const vector_float3 cubePositions[] =
        {
            // Front
            { -1, -1,  1 },
            { -1,  1,  1 },
            {  1,  1,  1 },
            {  1, -1,  1 },

            // Top
            { -1,  1,  1 },
            { -1,  1, -1 },
            {  1,  1, -1 },
            {  1,  1,  1 },

            // Right
            {  1, -1,  1 },
            {  1,  1,  1 },
            {  1,  1, -1 },
            {  1, -1, -1 },

            // Back
            { -1,  1, -1 },
            { -1, -1, -1 },
            {  1, -1, -1 },
            {  1,  1, -1 },

            // Bottom
            { -1, -1, -1 },
            { -1, -1,  1 },
            {  1, -1,  1 },
            {  1, -1, -1 },

            // Left
            { -1, -1, -1 },
            { -1,  1, -1 },
            { -1,  1,  1 },
            { -1, -1,  1 }
        };

        _positionBuffer = [_device newBufferWithBytes:cubePositions
                                               length:sizeof(cubePositions)
                                              options:0];
    }

    // Create a buffer with texture coordinates to draw the cube.
    {
        static const vector_float2 cubeTexCoords[] =
        {
            // Front
            { 0, 0 },
            { 0, 1 },
            { 1, 1 },
            { 1, 0 },

            // Top
            { 0, 0 },
            { 0, 1 },
            { 1, 1 },
            { 1, 0 },

            // Right
            { 0, 0 },
            { 0, 1 },
            { 1, 1 },
            { 1, 0 },

            // Back
            { 1, 0 },
            { 1, 1 },
            { 0, 1 },
            { 0, 0 },

            // Bottom
            { 0, 0 },
            { 0, 1 },
            { 1, 1 },
            { 1, 0 },

            // Right
            { 0, 0 },
            { 0, 1 },
            { 1, 1 },
            { 1, 0 },
        };

        _texCoordBuffer = [_device newBufferWithBytes:cubeTexCoords
                                               length:sizeof(cubeTexCoords)
                                              options:0];
    }

    // Create the index buffer to draw the cube.
    {

        static uint16_t indices[] =
        {
            // Front
             0,  2,  1,  0,  3,  2,

            // Top
             4,  6,  5,  4,  7,  6,

            // Right
             8, 10,  9,  8, 11, 10,

            // Back
            12, 14, 13, 12, 15, 14,

            // Bottom
            16, 18, 17, 16, 19, 18,

            // Left
            20, 22, 21, 20, 23, 22,
        };

        _indexBuffer = [_device newBufferWithBytes:indices
                                            length:sizeof(indices)
                                           options:0];
    }

    // Load color texture from asset catalog
    {
        MTKTextureLoader* textureLoader = [[MTKTextureLoader alloc] initWithDevice:_device];

        NSDictionary *textureLoaderOptions =
        @{
            MTKTextureLoaderOptionTextureUsage       : @(MTLTextureUsageShaderRead),
            MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModePrivate)
         };

        NSError *error;

        _colorMap = [textureLoader newTextureWithName:@"ColorMap"
                                          scaleFactor:1.0
                                               bundle:nil
                                              options:textureLoaderOptions
                                                error:&error];

        NSAssert(_colorMap, @"Error creating the Metal texture, error: %@.", error);
    }
}

/// Update any scene state before encoding rendering commands to our drawable
- (void)updateSceneState
{
    NSUInteger frameDataBufferIndex = _frameNumber % AAPLMaxFramesInFlight;

    AAPLPerFrameData *frameData = (AAPLPerFrameData*)_frameDataBuffer[frameDataBufferIndex].contents;

    frameData->projectionMatrix = _projectionMatrix;

    vector_float3 rotationAxis = { 1, 1, 0 };
    matrix_float4x4 modelMatrix = matrix4x4_rotation(_rotation, rotationAxis);
    matrix_float4x4 viewMatrix = matrix4x4_translation(0.0, 0.0, -6.0);

    frameData->modelViewMatrix = matrix_multiply(viewMatrix, modelMatrix);

    _rotation += .01;
}

/// Update the 3D projection matrix with the given size
- (void)updateProjectionMatrixWithSize:(CGSize)size
{
    /// Respond to drawable size or orientation changes here
    float aspect = size.width / (float)size.height;
    _projectionMatrix = matrix_perspective_right_hand(65.0f * (M_PI / 180.0f), aspect, 0.1f, 100.0f);
}

/// Create render targets for compute kernel inputs
-(void)createRenderTargetsWithSize:(CGSize)size
{
    MTLTextureDescriptor *renderTargetDesc = [MTLTextureDescriptor new];

    // Set up properties common to both color and depth textures.
    renderTargetDesc.width = size.width;
    renderTargetDesc.height = size.height;
    renderTargetDesc.storageMode = MTLStorageModePrivate;

    // Set up a color render texture target.
    renderTargetDesc.pixelFormat = MTLPixelFormatRGBA8Unorm;
    renderTargetDesc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    _colorTarget =  [_device newTextureWithDescriptor:renderTargetDesc];

    // Set up a depth texture target.
    renderTargetDesc.pixelFormat = MTLPixelFormatDepth32Float;
    renderTargetDesc.usage = MTLTextureUsageRenderTarget;
    id<MTLTexture> depthTarget = [_device newTextureWithDescriptor:renderTargetDesc];

    // Set up the render pass descriptor with newly created textures.
    _renderPassDescriptor.colorAttachments[0].texture = _colorTarget;
    _renderPassDescriptor.depthAttachment.texture = depthTarget;
}

/// Called whenever view changes orientation or layout is changed
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    // Update the aspect ratio and projection matrix since the view orientation or size has changed.
    [self updateProjectionMatrixWithSize:size];
    [self createRenderTargetsWithSize:size];
}

/// Called whenever the view needs to render
- (void)drawInMTKView:(nonnull MTKView*)view
{
    NSUInteger frameDataBufferIndex = _frameNumber % AAPLMaxFramesInFlight;

    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);

    [self updateSceneState];

    // Render cube to offscreen texture
    {
        id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
        commandBuffer.label = [NSString stringWithFormat:@"Render CommandBuffer"];

        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer
                                                     renderCommandEncoderWithDescriptor:_renderPassDescriptor];
        // Render cube
        renderEncoder.label = @"Render Encoder";
        [renderEncoder pushDebugGroup:@"Render Cube"];

        [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [renderEncoder setCullMode:MTLCullModeBack];
        [renderEncoder setRenderPipelineState:_renderPipeline];
        [renderEncoder setDepthStencilState:_depthState];

        [renderEncoder setVertexBuffer:_positionBuffer
                                offset:0
                               atIndex:AAPLBufferIndexMeshPositions];

        [renderEncoder setVertexBuffer:_texCoordBuffer
                                offset:0
                               atIndex:AAPLBufferIndexMeshGenerics];

        [renderEncoder setVertexBuffer:_frameDataBuffer[frameDataBufferIndex]
                                offset:0
                               atIndex:AAPLBufferIndexFrameData];

        [renderEncoder setFragmentBuffer:_frameDataBuffer[frameDataBufferIndex]
                                  offset:0
                                 atIndex:AAPLBufferIndexFrameData];

        [renderEncoder setFragmentTexture:_colorMap
                                  atIndex:AAPLTextureIndexColorMap];

        [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                  indexCount:36
                                   indexType:MTLIndexTypeUInt16
                                 indexBuffer:_indexBuffer
                           indexBufferOffset:0];

        [renderEncoder popDebugGroup];
        [renderEncoder endEncoding];

        [commandBuffer commit];
    }

    // Use compute pipeline from function in dylib to process offscreen texture
    if(_computePipeline && view.currentDrawable)
    {
        id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
        commandBuffer.label = [NSString stringWithFormat:@"Compute CommandBuffer"];

        __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
        [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
         {
            dispatch_semaphore_signal(block_sema);
        }];

        id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
        computeEncoder.label = @"Compute Encoder";
        [computeEncoder setComputePipelineState:_computePipeline];
        [computeEncoder setTexture:_colorTarget
                           atIndex:AAPLTextureIndexComputeIn];
        [computeEncoder setTexture:view.currentDrawable.texture
                           atIndex:AAPLTextureIndexComputeOut];
        [computeEncoder dispatchThreads:MTLSizeMake(view.drawableSize.width, view.drawableSize.height, 1)
                  threadsPerThreadgroup:MTLSizeMake(16, 16, 1)];

        [computeEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];

        [commandBuffer commit];
    }


    _frameNumber++;
}

/// Compile a dylib with the given program string then create a compute pipeline with the dylib
-(void)compileDylibWithString:(NSString *)programString
{
    NSError *error;

    MTLCompileOptions *options = [MTLCompileOptions new];
    options.libraryType = MTLLibraryTypeDynamic;
    options.installName = [NSString stringWithFormat:@"@executable_path/userCreatedDylib.metallib"];

    id<MTLLibrary> lib = [_device newLibraryWithSource:programString
                                               options:options
                                                 error:&error];
    if(!lib && error)
    {
        NSLog(@"Error compiling library from source: %@", error);
        return;
    }
    
    id<MTLDynamicLibrary> dynamicLib = [_device newDynamicLibrary:lib
                                                            error:&error];
    if(!dynamicLib && error)
    {
        NSLog(@"Error creating dynamic library from source library: %@", error);
        return;
    }
    
    MTLComputePipelineDescriptor *descriptor = [MTLComputePipelineDescriptor new];
    descriptor.computeFunction = _baseDescriptor.computeFunction;
    descriptor.insertLibraries = @[dynamicLib];
    
    id<MTLComputePipelineState> previousComputePipeline = _computePipeline;
    _computePipeline = [_device newComputePipelineStateWithDescriptor:descriptor
                                                              options:MTLPipelineOptionNone
                                                           reflection:nil
                                                                error:&error];
    if(!_computePipeline && error)
    {
        NSLog(@"Error creating pipeline library from source library, using previous pipeline: %@", error);
        _computePipeline = previousComputePipeline;
        return;
    }
}

@end
