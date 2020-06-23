/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of the renderer class that performs Metal setup and per-frame rendering.
*/

#import <simd/simd.h>

#import "Renderer.h"
#import "Transforms.h"
#import "ShaderTypes.h"
#import "Scene.h"

using namespace simd;

static const NSUInteger maxFramesInFlight = 3;
static const size_t alignedUniformsSize = (sizeof(Uniforms) + 255) & ~255;

@implementation Renderer
{
    id <MTLDevice> _device;
    id <MTLCommandQueue> _queue;
    id <MTLLibrary> _library;

    id <MTLBuffer> _uniformBuffer;

    id <MTLAccelerationStructure> _instanceAccelerationStructure;
    NSMutableArray *_primitiveAccelerationStructures;

    id <MTLComputePipelineState> _raytracingPipeline;
    id <MTLRenderPipelineState> _copyPipeline;

    id <MTLTexture> _accumulationTargets[2];
    id <MTLTexture> _randomTexture;

    id <MTLBuffer> _resourceBuffer;
    id <MTLBuffer> _instanceBuffer;

    id <MTLIntersectionFunctionTable> _intersectionFunctionTable;

    dispatch_semaphore_t _sem;
    CGSize _size;
    NSUInteger _uniformBufferOffset;
    NSUInteger _uniformBufferIndex;

    unsigned int _frameIndex;

    Scene *_scene;

    NSUInteger _resourcesStride;
    bool _useIntersectionFunctions;
}

- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                                 scene:(Scene *)scene
{
    self = [super init];

    if (self)
    {
        _device = device;

        _sem = dispatch_semaphore_create(maxFramesInFlight);

        _scene = scene;

        [self loadMetal];
        [self createBuffers];
        [self createAccelerationStructures];
        [self createPipelines];
    }

    return self;
}

// Initialize Metal shader library and command queue.
- (void)loadMetal
{
    _library = [_device newDefaultLibrary];

    _queue = [_device newCommandQueue];
}

// Create a compute pipeline state with an optional array of additional functions to link the compute
// function with. The sample uses this to link the ray-tracing kernel with any intersection functions.
- (id <MTLComputePipelineState>)newComputePipelineStateWithFunction:(id <MTLFunction>)function
                                                    linkedFunctions:(NSArray <id <MTLFunction>> *)linkedFunctions
{
    MTLLinkedFunctions *mtlLinkedFunctions = nil;

    // Attach the additional functions to an MTLLinkedFunctions object
    if (linkedFunctions) {
        mtlLinkedFunctions = [[MTLLinkedFunctions alloc] init];

        mtlLinkedFunctions.functions = linkedFunctions;
    }

    MTLComputePipelineDescriptor *descriptor = [[MTLComputePipelineDescriptor alloc] init];

    // Set the main compute function.
    descriptor.computeFunction = function;

    // Attach the linked functions object to the compute pipeline descriptor.
    descriptor.linkedFunctions = mtlLinkedFunctions;

    // Set to YES to allow the compiler to make certain optimizations.
    descriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = YES;

    NSError *error = nil;

    // Create the compute pipeline state.
    id <MTLComputePipelineState> pipeline = [_device newComputePipelineStateWithDescriptor:descriptor
                                                                                   options:0
                                                                                reflection:nil
                                                                                     error:&error];

    if (!pipeline) {
        NSLog(@"Failed to create %@ pipeline state: %@", function.name, error.localizedDescription);

        return nil;
    }

    return pipeline;
}

// Create a compute function and specialize its function constants.
- (id <MTLFunction>)specializedFunctionWithName:(NSString *)name {
    // Fill out a dictionary of function constant values.
    MTLFunctionConstantValues *constants = [[MTLFunctionConstantValues alloc] init];

    // The first constant is the stride between entries in the resource buffer. The sample
    // uses this to allow intersection functions to look up any resources they use.
    uint32_t resourcesStride = (uint32_t)_resourcesStride;
    [constants setConstantValue:&resourcesStride type:MTLDataTypeUInt atIndex:0];

    // The second constant turns the use of intersection functions on and off.
    [constants setConstantValue:&_useIntersectionFunctions type:MTLDataTypeBool atIndex:1];

    NSError *error = nil;

    // Finally, load the function from the Metal library.
    id <MTLFunction> function = [_library newFunctionWithName:name constantValues:constants error:&error];

    if (!function) {
        NSLog(@"Failed to create function %@: %@", name, error.localizedDescription);
        return nil;
    }

    return function;
}

// Create pipeline states
- (void)createPipelines
{
    _useIntersectionFunctions = false;

    // Check if any scene geometry has an intersection function
    for (Geometry *geometry in _scene.geometries) {
        if (geometry.intersectionFunctionName) {
            _useIntersectionFunctions = true;
            break;
        }
    }

    // Maps intersection function names to actual MTLFunctions
    NSMutableDictionary <NSString *, id <MTLFunction>> *intersectionFunctions = [NSMutableDictionary dictionary];

    // First, load all the intersection functions since the sample needs them to create the final
    // ray-tracing compute pipeline state.
    for (Geometry *geometry in _scene.geometries) {
        // Skip if the geometry doesn't have an intersection function or if the app already loaded
        // it.
        if (!geometry.intersectionFunctionName || [intersectionFunctions objectForKey:geometry.intersectionFunctionName])
            continue;

        // Specialize function constants used by the intersection function.
        id <MTLFunction> intersectionFunction = [self specializedFunctionWithName:geometry.intersectionFunctionName];

        // Add the function to the dictionary
        intersectionFunctions[geometry.intersectionFunctionName] = intersectionFunction;
    }

    id <MTLFunction> raytracingFunction = [self specializedFunctionWithName:@"raytracingKernel"];

    // Create the compute pipeline state which does all of the ray tracing.
    _raytracingPipeline = [self newComputePipelineStateWithFunction:raytracingFunction
                                                    linkedFunctions:[intersectionFunctions allValues]];

    // Create the intersection function table
    if (_useIntersectionFunctions) {
        MTLIntersectionFunctionTableDescriptor *intersectionFunctionTableDescriptor = [[MTLIntersectionFunctionTableDescriptor alloc] init];

        intersectionFunctionTableDescriptor.functionCount = _scene.geometries.count;

        // Create a table large enough to hold all of the intersection functions. Metal
        // links intersection functions into the compute pipeline state, potentially with
        // a different address for each compute pipeline. Therefore, the intersection
        // function table is specific to the compute pipeline state that created it and you
        // can only use it with that pipeline.
        _intersectionFunctionTable = [_raytracingPipeline newIntersectionFunctionTableWithDescriptor:intersectionFunctionTableDescriptor];

        // Bind the buffer used to pass resources to the intersection functions.
        [_intersectionFunctionTable setBuffer:_resourceBuffer offset:0 atIndex:0];

        // Map each piece of scene geometry to its intersection function.
        for (NSUInteger geometryIndex = 0; geometryIndex < _scene.geometries.count; geometryIndex++) {
            Geometry *geometry = _scene.geometries[geometryIndex];

            if (geometry.intersectionFunctionName) {
                id <MTLFunction> intersectionFunction = intersectionFunctions[geometry.intersectionFunctionName];

                // Create a handle to the copy of the intersection function linked into the
                // ray-tracing compute pipeline state. Create a different handle for each pipeline
                // it is linked with.
                id <MTLFunctionHandle> handle = [_raytracingPipeline functionHandleWithFunction:intersectionFunction];

                // Insert the handle into the intersection function table. This ultimately maps the
                // geometry's index to its intersection function.
                [_intersectionFunctionTable setFunction:handle atIndex:geometryIndex];
            }
        }
    }

    // Create a render pipeline state which copies the rendered scene into the MTKView and
    // performs simple tone mapping.
    MTLRenderPipelineDescriptor *renderDescriptor = [[MTLRenderPipelineDescriptor alloc] init];

    renderDescriptor.vertexFunction = [_library newFunctionWithName:@"copyVertex"];
    renderDescriptor.fragmentFunction = [_library newFunctionWithName:@"copyFragment"];

    renderDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA16Float;

    NSError *error = nil;

    _copyPipeline = [_device newRenderPipelineStateWithDescriptor:renderDescriptor error:nil];

    if (!_copyPipeline)
        NSLog(@"Failed to create the copy pipeline state: %@", error.localizedDescription);
}

// Create an argument encoder which encodes references to a set of resources
// into a buffer.
- (id <MTLArgumentEncoder>)newArgumentEncoderForResources:(NSArray <id <MTLResource>> *)resources {
    NSMutableArray *arguments = [NSMutableArray array];

    for (id <MTLResource> resource in resources) {
        MTLArgumentDescriptor *argumentDescriptor = [MTLArgumentDescriptor argumentDescriptor];

        argumentDescriptor.index = arguments.count;
        argumentDescriptor.access = MTLArgumentAccessReadOnly;

        if ([resource conformsToProtocol:@protocol(MTLBuffer)])
            argumentDescriptor.dataType = MTLDataTypePointer;
        else if ([resource conformsToProtocol:@protocol(MTLTexture)]) {
            id <MTLTexture> texture = (id <MTLTexture>)resource;

            argumentDescriptor.dataType = MTLDataTypeTexture;
            argumentDescriptor.textureType = texture.textureType;
        }

        [arguments addObject:argumentDescriptor];
    }

    return [_device newArgumentEncoderWithArguments:arguments];
}

- (void)createBuffers {
    // The uniform buffer contains a few small values which change from frame to frame. The
    // sample can have up to 3 frames in flight at once, so allocate a range of the buffer
    // for each frame. The GPU reads from one chunk while the CPU writes to the next chunk.
    // Align the chunks to 256 bytes on macOS and 16 bytes on iOS.
    NSUInteger uniformBufferSize = alignedUniformsSize * maxFramesInFlight;

    MTLResourceOptions options = getManagedBufferStorageMode();

    _uniformBuffer = [_device newBufferWithLength:uniformBufferSize options:options];

    // Upload scene data to buffers.
    [_scene uploadToBuffers];

    _resourcesStride = 0;

    // Each intersection function has its own set of resources. Determine the maximum size over all
    // intersection functions. This will become the stride used by intersection functions to find
    // the starting address for their resources.
    for (Geometry *geometry in _scene.geometries) {
        id <MTLArgumentEncoder> encoder = [self newArgumentEncoderForResources:geometry.resources];

        if (encoder.encodedLength > _resourcesStride)
            _resourcesStride = encoder.encodedLength;
    }

    // Create the resource buffer.
    _resourceBuffer = [_device newBufferWithLength:_resourcesStride * _scene.geometries.count options:options];

    for (NSUInteger geometryIndex = 0; geometryIndex < _scene.geometries.count; geometryIndex++) {
        Geometry *geometry = _scene.geometries[geometryIndex];

        // Create an argument encoder for this geometry's intersection function's resources
        id <MTLArgumentEncoder> encoder = [self newArgumentEncoderForResources:geometry.resources];

        // Bind the argument encoder to the resource buffer at this geometry's offset.
        [encoder setArgumentBuffer:_resourceBuffer offset:_resourcesStride * geometryIndex];

        // Encode the arguments into the resource buffer.
        for (NSUInteger argumentIndex = 0; argumentIndex < geometry.resources.count; argumentIndex++) {
            id <MTLResource> resource = geometry.resources[argumentIndex];

            if ([resource conformsToProtocol:@protocol(MTLBuffer)])
                [encoder setBuffer:(id <MTLBuffer>)resource offset:0 atIndex:argumentIndex];
            else if ([resource conformsToProtocol:@protocol(MTLTexture)])
                [encoder setTexture:(id <MTLTexture>)resource atIndex:argumentIndex];
        }
    }

#if !TARGET_OS_IPHONE
    [_resourceBuffer didModifyRange:NSMakeRange(0, _resourceBuffer.length)];
#endif
}

// Create and compact an acceleration structure, given an acceleration structure descriptor.
- (id <MTLAccelerationStructure>)newAccelerationStructureWithDescriptor:(MTLAccelerationStructureDescriptor *)descriptor
{
    // Query for the sizes needed to store and build the acceleration structure.
    MTLAccelerationStructureSizes accelSizes = [_device accelerationStructureSizesWithDescriptor:descriptor];

    // Allocate an acceleration structure large enough for this descriptor. This doesn't actually
    // build the acceleration structure, just allocates memory.
    id <MTLAccelerationStructure> accelerationStructure = [_device newAccelerationStructureWithSize:accelSizes.accelerationStructureSize];

    // Allocate scratch space used by Metal to build the acceleration structure.
    // Use MTLResourceStorageModePrivate for best performance since the sample
    // doesn't need access to buffer's contents.
    id <MTLBuffer> scratchBuffer = [_device newBufferWithLength:accelSizes.buildScratchBufferSize options:MTLResourceStorageModePrivate];

    // Create a command buffer which will perform the acceleration structure build
    id <MTLCommandBuffer> commandBuffer = [_queue commandBuffer];

    // Create an acceleration structure command encoder.
    id <MTLAccelerationStructureCommandEncoder> commandEncoder = [commandBuffer accelerationStructureCommandEncoder];

    // Allocate a buffer for Metal to write the compacted accelerated structure's size into.
    id <MTLBuffer> compactedSizeBuffer = [_device newBufferWithLength:sizeof(uint32_t) options:MTLResourceStorageModeShared];

    // Schedule the actual acceleration structure build
    [commandEncoder buildAccelerationStructure:accelerationStructure
                                    descriptor:descriptor
                                 scratchBuffer:scratchBuffer
                           scratchBufferOffset:0];

    // Compute and write the compacted acceleration structure size into the buffer. You
    // must already have a built accelerated structure because Metal determines the compacted
    // size based on the final size of the acceleration structure. Compacting an acceleration
    // structure can potentially reclaim significant amounts of memory since Metal must
    // create the initial structure using a conservative approach.

    [commandEncoder writeCompactedAccelerationStructureSize:accelerationStructure
                                                   toBuffer:compactedSizeBuffer
                                                     offset:0];

    // End encoding and commit the command buffer so the GPU can start building the
    // acceleration structure.
    [commandEncoder endEncoding];

    [commandBuffer commit];

    // The sample waits for Metal to finish executing the command buffer so that it can
    // read back the compacted size.

    // Note: Don't wait for Metal to finish executing the command buffer if you aren't compacting
    // the acceleration structure, as doing so requires CPU/GPU synchronization. You don't have
    // to compact acceleration structures, but you should when creating large static acceleration
    // structures, such as static scene geometry. Avoid compacting acceleration structures that
    // you rebuild every frame, as the synchronization cost may be significant.

    [commandBuffer waitUntilCompleted];

    uint32_t compactedSize = *(uint32_t *)compactedSizeBuffer.contents;

    // Allocate a smaller acceleration structure based on the returned size.
    id <MTLAccelerationStructure> compactedAccelerationStructure = [_device newAccelerationStructureWithSize:compactedSize];

    // Create another command buffer and encoder.
    commandBuffer = [_queue commandBuffer];

    commandEncoder = [commandBuffer accelerationStructureCommandEncoder];

    // Encode the command to copy and compact the acceleration structure into the
    // smaller acceleration structure.
    [commandEncoder copyAndCompactAccelerationStructure:accelerationStructure
                                toAccelerationStructure:compactedAccelerationStructure];

    // End encoding and commit the command buffer. You don't need to wait for Metal to finish
    // executing this command buffer as long as you synchronize any ray-intersection work
    // to run after this command buffer completes. The sample relies on Metal's default
    // dependency tracking on resources to automatically synchronize access to the new
    // compacted acceleration structure.
    [commandEncoder endEncoding];
    [commandBuffer commit];

    return compactedAccelerationStructure;
}

// Create acceleration structures for the scene. The scene contains primitive acceleration
// structures and an instance acceleration structure. The primitive acceleration structures
// contain primitives such as triangles and spheres. The instance acceleration structure contains
// copies or "instances" of the primitive acceleration structures, each with their own
// transformation matrix describing where to place them in the scene.
- (void)createAccelerationStructures
{
    MTLResourceOptions options = getManagedBufferStorageMode();

    _primitiveAccelerationStructures = [[NSMutableArray alloc] init];

    // Create a primitive acceleration structure for each piece of geometry in the scene.
    for (NSUInteger i = 0; i < _scene.geometries.count; i++) {
        Geometry *mesh = _scene.geometries[i];

        MTLAccelerationStructureGeometryDescriptor *geometryDescriptor = [mesh geometryDescriptor];

        // Assign each piece of geometry a consecutive slot in the intersection function table.
        geometryDescriptor.intersectionFunctionTableOffset = i;

        // Create a primitive acceleration structure descriptor to contain the single piece
        // of acceleration structure geometry.
        MTLPrimitiveAccelerationStructureDescriptor *accelDescriptor = [MTLPrimitiveAccelerationStructureDescriptor descriptor];

        accelDescriptor.geometryDescriptors = @[ geometryDescriptor ];

        // Build the acceleration structure.
        id <MTLAccelerationStructure> accelerationStructure = [self newAccelerationStructureWithDescriptor:accelDescriptor];

        // Add the acceleration structure to the array of primitive acceleration structures.
        [_primitiveAccelerationStructures addObject:accelerationStructure];
    }

    // Allocate a buffer of acceleration structure instance descriptors. Each descriptor represents
    // an instance of one of the primitive acceleration structures created above, with its own
    // transformation matrix.
    _instanceBuffer = [_device newBufferWithLength:sizeof(MTLAccelerationStructureInstanceDescriptor) * _scene.instances.count options:options];

    MTLAccelerationStructureInstanceDescriptor *instanceDescriptors = (MTLAccelerationStructureInstanceDescriptor *)_instanceBuffer.contents;

    // Fill out instance descriptors.
    for (NSUInteger instanceIndex = 0; instanceIndex < _scene.instances.count; instanceIndex++) {
        GeometryInstance *instance = _scene.instances[instanceIndex];

        NSUInteger geometryIndex = [_scene.geometries indexOfObject:instance.geometry];

        // Map the instance to its acceleration structure.
        instanceDescriptors[instanceIndex].accelerationStructureIndex = (uint32_t)geometryIndex;

        // Mark the instance as opaque if it doesn't have an intersection function so that the
        // ray intersector doesn't attempt to execute a function that doesn't exist.
        instanceDescriptors[instanceIndex].flags = instance.geometry.intersectionFunctionName == nil ? MTLAccelerationStructureInstanceFlagOpaque : 0;

        // Metal adds the geometry intersection function table offset and instance intersection
        // function table offset together to determine which intersection function to execute.
        // The sample mapped geometries directly to their intersection functions above, so it
        // sets the instance's table offset to 0.
        instanceDescriptors[instanceIndex].intersectionFunctionTableOffset = 0;

        // Set the instance mask, which the sample uses to filter out intersections between rays
        // and geometry. For example, it uses masks to prevent light sources from being visible
        // to secondary rays, which would result in their contribution being double-counted.
        instanceDescriptors[instanceIndex].mask = (uint32_t)instance.mask;

        // Copy the first three rows of the instance transformation matrix. Metal assumes that
        // the bottom row is (0, 0, 0, 1).
        // This allows instance descriptors to be tightly packed in memory.
        for (int column = 0; column < 4; column++)
            for (int row = 0; row < 3; row++)
                instanceDescriptors[instanceIndex].transformationMatrix.columns[column][row] = instance.transform.columns[column][row];
    }

#if !TARGET_OS_IPHONE
    [_instanceBuffer didModifyRange:NSMakeRange(0, _instanceBuffer.length)];
#endif

    // Create an instance acceleration structure descriptor.
    MTLInstanceAccelerationStructureDescriptor *accelDescriptor = [MTLInstanceAccelerationStructureDescriptor descriptor];

    accelDescriptor.instancedAccelerationStructures = _primitiveAccelerationStructures;
    accelDescriptor.instanceCount = _scene.instances.count;
    accelDescriptor.instanceDescriptorBuffer = _instanceBuffer;

    // Finally, create the instance acceleration structure containing all of the instances
    // in the scene.
    _instanceAccelerationStructure = [self newAccelerationStructureWithDescriptor:accelDescriptor];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    _size = size;

    // Create a pair of textures which the ray tracing kernel will use to accumulate
    // samples over several frames.
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];

    textureDescriptor.pixelFormat = MTLPixelFormatRGBA32Float;
    textureDescriptor.textureType = MTLTextureType2D;
    textureDescriptor.width = size.width;
    textureDescriptor.height = size.height;

    // Stored in private memory because only the GPU will read or write this texture.
    textureDescriptor.storageMode = MTLStorageModePrivate;
    textureDescriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite;

    for (NSUInteger i = 0; i < 2; i++)
        _accumulationTargets[i] = [_device newTextureWithDescriptor:textureDescriptor];

    // Create a texture containing a random integer value for each pixel. the sample
    // uses these values to decorrelate pixels while drawing pseudorandom numbers from the
    // Halton sequence.
    textureDescriptor.pixelFormat = MTLPixelFormatR32Uint;
    textureDescriptor.usage = MTLTextureUsageShaderRead;

    // The sample initializes the data in the texture, so it can't be private.
#if !TARGET_OS_IPHONE
    textureDescriptor.storageMode = MTLStorageModeManaged;
#else
    textureDescriptor.storageMode = MTLStorageModeShared;
#endif

    _randomTexture = [_device newTextureWithDescriptor:textureDescriptor];

    // Initialize random values.
    uint32_t *randomValues = (uint32_t *)malloc(sizeof(uint32_t) * size.width * size.height);

    for (NSUInteger i = 0; i < size.width * size.height; i++)
        randomValues[i] = rand() % (1024 * 1024);

    [_randomTexture replaceRegion:MTLRegionMake2D(0, 0, size.width, size.height)
                      mipmapLevel:0
                        withBytes:randomValues
                      bytesPerRow:sizeof(uint32_t) * size.width];

    free(randomValues);

    _frameIndex = 0;
}

- (void)updateUniforms {
    _uniformBufferOffset = alignedUniformsSize * _uniformBufferIndex;

    Uniforms *uniforms = (Uniforms *)((char *)_uniformBuffer.contents + _uniformBufferOffset);

    vector_float3 position = _scene.cameraPosition;
    vector_float3 target = _scene.cameraTarget;
    vector_float3 up = _scene.cameraUp;

    vector_float3 forward = vector_normalize(target - position);
    vector_float3 right = vector_normalize(vector_cross(forward, up));
    up = vector_normalize(vector_cross(right, forward));

    uniforms->camera.position = position;
    uniforms->camera.forward = forward;
    uniforms->camera.right = right;
    uniforms->camera.up = up;

    float fieldOfView = 45.0f * (M_PI / 180.0f);
    float aspectRatio = (float)_size.width / (float)_size.height;
    float imagePlaneHeight = tanf(fieldOfView / 2.0f);
    float imagePlaneWidth = aspectRatio * imagePlaneHeight;

    uniforms->camera.right *= imagePlaneWidth;
    uniforms->camera.up *= imagePlaneHeight;

    uniforms->width = (unsigned int)_size.width;
    uniforms->height = (unsigned int)_size.height;

    uniforms->frameIndex = _frameIndex++;

    uniforms->lightCount = (unsigned int)_scene.lightCount;

#if !TARGET_OS_IPHONE
    [_uniformBuffer didModifyRange:NSMakeRange(_uniformBufferOffset, alignedUniformsSize)];
#endif

    // Advance to the next slot in the uniform buffer.
    _uniformBufferIndex = (_uniformBufferIndex + 1) % maxFramesInFlight;
}

- (void)drawInMTKView:(MTKView *)view {
    // The sample uses the uniform buffer to stream uniform data to the GPU, so it
    // needs to wait until the GPU finishes processing the oldest GPU frame before
    // it can reuse that space in the buffer.
    dispatch_semaphore_wait(_sem, DISPATCH_TIME_FOREVER);

    // Create a command for the frame's commands.
    id <MTLCommandBuffer> commandBuffer = [_queue commandBuffer];

    __block dispatch_semaphore_t sem = _sem;

    // When the GPU finishes processing command buffer for the frame, signal the
    // semaphore to make the space in uniform available for future frames.

    // Note: Completion handlers should be as fast as possible as the GPU driver may
    // have other work scheduled on the underlying dispatch queue.
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        dispatch_semaphore_signal(sem);
    }];

    [self updateUniforms];

    NSUInteger width = (NSUInteger)_size.width;
    NSUInteger height = (NSUInteger)_size.height;

    // Launch a rectangular grid of threads on the GPU to perform ray tracing, with one thread per
    // pixel. The sample needs to align the number of threads to a multiple of the threadgroup
    // size, because earlier, when it created the pipeline objects, it declared that the pipeline
    // would always use a threadgroup size that's a multiple of the thread execution width
    // (SIMD group size). An 8x8 threadgroup is a safe threadgroup size and small enough to be
    // supported on most devices. A more advanced app would choose the threadgroup size dynamically.
    MTLSize threadsPerThreadgroup = MTLSizeMake(8, 8, 1);
    MTLSize threadgroups = MTLSizeMake((width  + threadsPerThreadgroup.width  - 1) / threadsPerThreadgroup.width,
                                       (height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
                                       1);

    // Create a compute encoder to encode GPU commands.
    id <MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];

    // Bind buffers
    [computeEncoder setBuffer:_uniformBuffer            offset:_uniformBufferOffset atIndex:0];
    [computeEncoder setBuffer:_resourceBuffer           offset:0                    atIndex:1];
    [computeEncoder setBuffer:_instanceBuffer           offset:0                    atIndex:2];
    [computeEncoder setBuffer:_scene.lightBuffer        offset:0                    atIndex:3];

    // Bind acceleration structure and intersection function table. These bind to normal buffer
    // binding slots.
    [computeEncoder setAccelerationStructure:_instanceAccelerationStructure atBufferIndex:4];
    [computeEncoder setIntersectionFunctionTable:_intersectionFunctionTable atBufferIndex:5];

    // Bind textures. The ray tracing kernel reads from _accumulationTargets[0], averages the
    // result with this frame's samples, and writes to _accumulationTargets[1].
    [computeEncoder setTexture:_randomTexture atIndex:0];
    [computeEncoder setTexture:_accumulationTargets[0] atIndex:1];
    [computeEncoder setTexture:_accumulationTargets[1] atIndex:2];

    // Mark any resources used by intersection functions as "used". The sample does this because
    // it only references these resources indirectly via the resource buffer. Metal makes all the
    // marked resources resident in memory before the intersection functions execute.
    // Normally, the sample would also mark the resource buffer itself since the
    // intersection table references it indirectly. However, the sample also binds the resource
    // buffer directly, so it doesn't need to mark it explicitly.
    for (Geometry *geometry in _scene.geometries)
        for (id <MTLResource> resource in geometry.resources)
            [computeEncoder useResource:resource usage:MTLResourceUsageRead];

    // Also mark primitive acceleration structures as used since only the instance acceleration
    // structure references them.
    for (id <MTLAccelerationStructure> primitiveAccelerationStructure in _primitiveAccelerationStructures)
        [computeEncoder useResource:primitiveAccelerationStructure usage:MTLResourceUsageRead];

    // Bind the compute pipeline state.
    [computeEncoder setComputePipelineState:_raytracingPipeline];

    // Dispatch the compute kernel to perform ray tracing.
    [computeEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadsPerThreadgroup];

    [computeEncoder endEncoding];

    // Swap the source and destination accumulation targets for the next frame.
    std::swap(_accumulationTargets[0], _accumulationTargets[1]);

    if (view.currentDrawable) {
        // Copy the resulting image into the view using the graphics pipeline since the sample
        // can't write directly to it using the compute kernel. The sample delays getting the
        // current render pass descriptor as long as possible to avoid a lenghty stall waiting
        // for the GPU/compositor to release a drawable. The drawable may be nil if
        // the window moved off screen.
        MTLRenderPassDescriptor* renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];

        renderPassDescriptor.colorAttachments[0].texture    = view.currentDrawable.texture;
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0f, 0.0f, 0.0f, 1.0f);

        // Create a render command encoder.
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

        [renderEncoder setRenderPipelineState:_copyPipeline];

        [renderEncoder setFragmentTexture:_accumulationTargets[0] atIndex:0];

        // Draw a quad which fills the screen.
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

        [renderEncoder endEncoding];

        // Present the drawable to the screen.
        [commandBuffer presentDrawable:view.currentDrawable];
    }

    // Finally, commit the command buffer so that the GPU can start executing.
    [commandBuffer commit];
}

@end
