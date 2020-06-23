/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for class describing objects in a scene
*/

#ifndef Scene_h
#define Scene_h

#import <Metal/Metal.h>

#import "Transforms.h"
#import "ShaderTypes.h"

#define FACE_MASK_NONE       0
#define FACE_MASK_NEGATIVE_X (1 << 0)
#define FACE_MASK_POSITIVE_X (1 << 1)
#define FACE_MASK_NEGATIVE_Y (1 << 2)
#define FACE_MASK_POSITIVE_Y (1 << 3)
#define FACE_MASK_NEGATIVE_Z (1 << 4)
#define FACE_MASK_POSITIVE_Z (1 << 5)
#define FACE_MASK_ALL        ((1 << 6) - 1)

struct BoundingBox {
    MTLPackedFloat3 min;
    MTLPackedFloat3 max;
};

MTLResourceOptions getManagedBufferStorageMode();

// Represents a piece of geometry in a scene, The sample composes Geometry objects
// from primitives such as triangles or spheres. Each Geometry object has its
// own primitive acceleration structure and, optionally, an intersection function.
// The sample creates copies, or "instances" of geometry objects using the GeometryInstance
// class.
@interface Geometry : NSObject

// Metal device used to create the acceleration structures.
@property (nonatomic, readonly) id <MTLDevice> device;

// Name of the intersection function to use for this geometry, or nil
// for triangles.
@property (nonatomic, readonly) NSString *intersectionFunctionName;

// Initializer.
- (instancetype)initWithDevice:(id <MTLDevice>)device;

// Reset the geometry, removing all primitives.
- (void)clear;

// Upload the primitives to Metal buffers so the GPU can access them.
- (void)uploadToBuffers;

// Get the acceleration structure geometry descriptor for this piece of
// geometry.
- (MTLAccelerationStructureGeometryDescriptor *)geometryDescriptor;

// Get the array of Metal resources such as buffers and textures to pass
// to the geometry's intersection function.
- (NSArray <id <MTLResource>> *)resources;

@end

// Represents a piece of geometry made of triangles.
@interface TriangleGeometry : Geometry

// Add a cube to the triangle geometry.
- (void)addCubeWithFaces:(unsigned int)faceMask
                   color:(vector_float3)color
               transform:(matrix_float4x4)transform
           inwardNormals:(bool)inwardNormals;

@end

// Represents a piece of geometry made of spheres.
@interface SphereGeometry : Geometry

- (void)addSphereWithOrigin:(vector_float3)origin
                     radius:(float)radius
                      color:(vector_float3)color;

@end

// Represents an instance, or copy, of a piece of geometry in a scene.
// Each instance has its own transformation matrix which determines
// where to place it in the scene.
@interface GeometryInstance : NSObject

// The geometry to use in the instance.
@property (nonatomic, readonly) Geometry *geometry;

// Transformation matrix describing where to place the geometry in the
// scene.
@property (nonatomic, readonly) matrix_float4x4 transform;

// Mask used to filter out intersections between rays and different
// types of geometry.
@property (nonatomic, readonly) unsigned int mask;

// Initializer.
- (instancetype)initWithGeometry:(Geometry *)geometry
                       transform:(matrix_float4x4)transform
                            mask:(unsigned int)mask;

@end

// Represents an entire scene, including different types of geometry,
// instances of that geometry, lights, and a camera.
@interface Scene : NSObject

// The device used to create the scene.
@property (nonatomic, readonly) id <MTLDevice> device;

// Array of geometries in the scene.
@property (nonatomic, readonly) NSArray <Geometry *> *geometries;

// Array of geometry instances in the scene.
@property (nonatomic, readonly) NSArray <GeometryInstance *> *instances;

// Buffer containing lights.
@property (nonatomic, readonly) id <MTLBuffer> lightBuffer;

// Number of lights in the light buffer.
@property (nonatomic, readonly) NSUInteger lightCount;

// Camera "position" vector.
@property (nonatomic) vector_float3 cameraPosition;

// Camera "target" vector. The camera faces this point.
@property (nonatomic) vector_float3 cameraTarget;

// Camera "up" vector.
@property (nonatomic) vector_float3 cameraUp;

// Initializer
- (instancetype)initWithDevice:(id <MTLDevice>)device;

// Create scene with instances of a Cornell Box. Each box can optionally
// contain a sphere primitive which uses an intersection function.
+ (Scene *)newInstancedCornellBoxSceneWithDevice:(id <MTLDevice>)device
                        useIntersectionFunctions:(BOOL)useIntersectionFunctions;

// Add a piece of geometry to the scene.
- (void)addGeometry:(Geometry *)mesh;

// Add an instance of a piece of geometry to the scene.
- (void)addInstance:(GeometryInstance *)instance;

// Add a light to the scene.
- (void)addLight:(AreaLight)light;

// Remove all geometry, instances, and lights from the scene.
- (void)clear;

// Upload all scene data to Metal buffers so the GPU can access the data.
- (void)uploadToBuffers;

@end

#endif
